import Toybox.Lang;
import Toybox.System;
import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.ActivityMonitor;
import Toybox.Sensor;
import Toybox.FitContributor;


class SpikeballActivity {

    public const MESG_TYPE_LENGTH = 101;

    public enum Team {
        TEAM_PLAYER,
        TEAM_OPPONENT,
    }

    public enum SessionField {
        SESSION_PLAYER_SCORE    = 82,
        SESSION_OPPONENT_SCORE,
        SESSION_STEPS           = 256,
        SESSION_AVG_TIME,
        SESSION_AVG_DISTANCE,
        SESSION_AVG_STEPS,
    }
    
    public enum LapField {
        LAP_OPPONENT_SCORE      = 74,
        LAP_PLAYER_SCORE        = 83,
        LAP_STEPS               = 256,
        LAP_AVG_TIME,
        LAP_AVG_DISTANCE,
        LAP_AVG_STEPS,
    }

    public enum RecordField {
        RECORD_TEMPERATURE      = 13,
    }

    private var timer as TimerController;
    private var session as ActivityRecording.Session?;
    private var time as Number;
    private var timeOnLap as Number;
    private var distanceOnLap as Number;
    private var scorePlayer as Number;
    private var scoreOpponent as Number;
    private var gamesPlayer as Number;
    private var gamesOpponent as Number;
    private var stepsOnStart as Number;
    private var stepsOnLap as Number;

    private var lastTemp as Number?;
    private var tempField as FitContributor.Field;
    private var recordTimer as TimerCallback?;

    private var lapFields as Dictionary;
    private var sessionFields as Dictionary;
    private var loopField as LoopField?;
    private var fieldTimer as TimerCallback?;

    public function initialize(timer as TimerController) {

        self.timer = timer;
        self.time = 0;
        self.timeOnLap = 0;
        self.distanceOnLap = 0;
        self.scorePlayer = 0;
        self.scoreOpponent = 0;
        self.gamesPlayer = 0;
        self.gamesOpponent = 0;
        self.stepsOnStart = ActivityMonitor.getInfo().steps;
        self.stepsOnLap = ActivityMonitor.getInfo().steps;

        if (Toybox.Sensor has :enableSensorType) { // API level >= 3.2.0
            Sensor.enableSensorType(Sensor.SENSOR_HEARTRATE);
            Sensor.enableSensorType(Sensor.SENSOR_TEMPERATURE);
            self.session = ActivityRecording.createSession({    // set up recording session
                :name=>"Spikeball",                             // set session name
                :sport=> Activity.SPORT_GENERIC,                 // set sport type
                :subSport=> Activity.SUB_SPORT_MATCH           // set sub sport type
            });
        } else {
            System.println("Older device"); // API level < 3.2.0
            Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE, Sensor.SENSOR_TEMPERATURE]);
            self.session = ActivityRecording.createSession({
                :name=>"Spikeball",
                :sport=>70 as ActivityRecording.Sport1,
                :subSport=>22 as ActivityRecording.SubSport,
            });
        }

        self.tempField = session.createField("temperature", 0, FitContributor.DATA_TYPE_SINT8, {:units=>"°C", :nativeNum=>RECORD_TEMPERATURE});

        self.lapFields = {};
        self.lapFields.put(LAP_PLAYER_SCORE,    session.createField("player_score",     1, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_LAP, :nativeNum => LAP_PLAYER_SCORE}));
        self.lapFields.put(LAP_OPPONENT_SCORE,  session.createField("opponent_score",   2, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_LAP, :nativeNum => LAP_OPPONENT_SCORE}));
        self.lapFields.put(LAP_STEPS,           session.createField("steps",            3, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_LAP}));
        self.lapFields.put(LAP_AVG_TIME,        session.createField("avg_time",         4, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_LAP}));
        self.lapFields.put(LAP_AVG_DISTANCE,    session.createField("avg_distance",     5, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_LAP}));
        self.lapFields.put(LAP_AVG_STEPS,       session.createField("avg_steps",        6, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_LAP}));
        
        self.sessionFields = {};
        self.sessionFields.put(SESSION_PLAYER_SCORE,    session.createField("player_score",     7,  FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION, :nativeNum => SESSION_PLAYER_SCORE}));
        self.sessionFields.put(SESSION_OPPONENT_SCORE,  session.createField("opponent_score",   8,  FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION, :nativeNum => SESSION_OPPONENT_SCORE}));
        self.sessionFields.put(SESSION_STEPS,           session.createField("steps",            9,  FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION}));
        self.sessionFields.put(SESSION_AVG_TIME,        session.createField("avg_time",         10, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION}));
        self.sessionFields.put(SESSION_AVG_DISTANCE,    session.createField("avg_distance",     11, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION}));
        self.sessionFields.put(SESSION_AVG_STEPS,       session.createField("avg_steps",        12, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION}));

        // TODO: handle error during session start
        System.println("Session start result: "+resume());
    }

    public function isRecording() as Boolean {
        return session.isRecording();
    }

    public function registerField(loopField as LoopField) as Void {
        self.loopField = loopField;
        timer.stop(fieldTimer);
        fieldTimer = timer.start(loopField.method(:nextField), 5, true);
    }

    public function stop() as Boolean {
        if (session.isRecording()) {
            var status = session.stop();
            timer.stop(recordTimer);
            timer.stop(fieldTimer);
            return status;
        }
        return false;
    }

    public function resume() as Boolean {
        if (!session.isRecording()) {
            var status = session.start();
            recordTimer = timer.start(method(:updateRecordFields), 1, true);
            return status;
        }
        return false;
    }

    public function updateRecordFields() as Void {
        if (session.isRecording()) {
            time = Activity.getActivityInfo().timerTime / 1000;

            var temp = getTemperature();
            if (temp!=null) {
                temp = temp.toNumber();
                if (temp!=lastTemp) {
                    tempField.setData(temp);
                    lastTemp = temp;
                }
            }
        }
    }

    public function lap() as Void {
        if (session.isRecording()) {
            updateLapFields();
            session.addLap();
            WatchUi.requestUpdate();
        }
    }

    private function updateLapFields() as Void {
        var info = Activity.getActivityInfo();
        var currentTime = info.timerTime;
        var currentDistance = info.elapsedDistance;
        var pointsCount = scorePlayer + scoreOpponent;
        var steps = ActivityMonitor.getInfo().steps;
        (lapFields.get(LAP_PLAYER_SCORE) as FitContributor.Field).setData(scorePlayer);
        (lapFields.get(LAP_OPPONENT_SCORE) as FitContributor.Field).setData(scoreOpponent);
        (lapFields.get(LAP_STEPS) as FitContributor.Field).setData(steps - stepsOnLap);
        if (pointsCount>0) {
            (lapFields.get(LAP_AVG_TIME) as FitContributor.Field).setData((currentTime - timeOnLap)/pointsCount/1000);
            (lapFields.get(LAP_AVG_DISTANCE) as FitContributor.Field).setData((currentDistance - distanceOnLap)/pointsCount);
            (lapFields.get(LAP_AVG_STEPS) as FitContributor.Field).setData((steps - stepsOnLap)/pointsCount);
        } else {
            (lapFields.get(LAP_AVG_TIME) as FitContributor.Field).setData(0);
            (lapFields.get(LAP_AVG_DISTANCE) as FitContributor.Field).setData(0);
            (lapFields.get(LAP_AVG_STEPS) as FitContributor.Field).setData(0);
        }
        stepsOnLap = steps;
        
        // TODO: handle tie game better
        if (scorePlayer >= scoreOpponent) {
            gamesPlayer++;
        } if (scoreOpponent >= scorePlayer) {
            gamesOpponent++;
        }
        scorePlayer = 0;
        scoreOpponent = 0;
    }

    public function save() as Void {
        var info = Activity.getActivityInfo();
        var steps = getSteps();
        var gamesCount = gamesPlayer + gamesOpponent;
        updateLapFields();
        (sessionFields.get(SESSION_PLAYER_SCORE) as FitContributor.Field).setData(gamesPlayer);
        (sessionFields.get(SESSION_OPPONENT_SCORE) as FitContributor.Field).setData(gamesOpponent);
        (sessionFields.get(SESSION_STEPS) as FitContributor.Field).setData(steps);
        if (gamesCount>0) {
            (sessionFields.get(SESSION_AVG_TIME) as FitContributor.Field).setData(info.timerTime/gamesCount/1000);
            (sessionFields.get(SESSION_AVG_DISTANCE) as FitContributor.Field).setData(info.elapsedDistance/gamesCount);
            (sessionFields.get(SESSION_AVG_STEPS) as FitContributor.Field).setData(steps/gamesCount);
        } else {
            (sessionFields.get(SESSION_AVG_TIME) as FitContributor.Field).setData(0);
            (sessionFields.get(SESSION_AVG_DISTANCE) as FitContributor.Field).setData(0);
            (sessionFields.get(SESSION_AVG_STEPS) as FitContributor.Field).setData(0);
        }
        session.save();
        session = null;
    }

    public function discard() as Void {
        session.discard();
        session = null;
    }

    public function addScore(teamId as Team) as Void {
        if (teamId) {
            scoreOpponent++;
        } else {
            scorePlayer++;
        }
        WatchUi.requestUpdate();
    }

    public function getScore(teamId as Team) as Number {
        return teamId ? scoreOpponent : scorePlayer;
    }

    public function getHR() as Number {
        return Sensor.getInfo().heartRate;
    }

    public function getSteps() as Number {
        return ActivityMonitor.getInfo().steps - stepsOnStart;
    }

    public function getDistance() as Number {
        var distance = Activity.getActivityInfo().elapsedDistance;
        return distance!=null ? distance.toNumber() : 0;
    }

    public function getKcal() as Number {
        var kcal = Activity.getActivityInfo().calories;
        return kcal!=null ? kcal : 0;
    }

    public function getTemperature() as Float? {
        return Sensor.getInfo().temperature;
    }

    public function getFormattedTime() as String{
        return (time/3600).format("%01d") + "'" + (time%3600/60).format("%02d") + '"' + (time%60).format("%02d");
    }
}