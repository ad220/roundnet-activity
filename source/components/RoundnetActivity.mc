import Toybox.Lang;
import Toybox.System;
import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.ActivityMonitor;
import Toybox.Sensor;
import Toybox.FitContributor;
import Toybox.Attention;


class RoundnetActivity {

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

    private var locEnabled as Boolean;
    private var tempEnabled as Boolean;
    private var lastTemp as Number?;
    private var tempField as FitContributor.Field?;
    private var recordTimer as TimerCallback?;

    private var lapFields as Dictionary;
    private var sessionFields as Dictionary;

    public function initialize() {

        self.time = 0;
        self.timeOnLap = 0;
        self.distanceOnLap = 0;
        self.scorePlayer = 0;
        self.scoreOpponent = 0;
        self.gamesPlayer = 0;
        self.gamesOpponent = 0;
        self.stepsOnStart = ActivityMonitor.getInfo().steps;
        self.stepsOnLap = ActivityMonitor.getInfo().steps;
        
        self.locEnabled = getApp().sensorsSettings.get("location") as Boolean;
        self.tempEnabled = getApp().sensorsSettings.get("temperature") as Boolean;
        createSession();

        self.tempField = tempEnabled ? session.createField("temperature", 0, FitContributor.DATA_TYPE_SINT8, {:units=>"°C", :nativeNum=>RECORD_TEMPERATURE}) : null;

        self.lapFields = {};
        self.lapFields.put(LAP_PLAYER_SCORE,    session.createField("player_score",     1, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_LAP, :nativeNum => LAP_PLAYER_SCORE}));
        self.lapFields.put(LAP_OPPONENT_SCORE,  session.createField("opponent_score",   2, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_LAP, :nativeNum => LAP_OPPONENT_SCORE}));
        self.lapFields.put(LAP_STEPS,           session.createField("steps",            3, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_LAP}));
        self.lapFields.put(LAP_AVG_TIME,        session.createField("avg_time",         4, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_LAP}));
        self.lapFields.put(LAP_AVG_STEPS,       session.createField("avg_steps",        6, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_LAP}));
        
        self.sessionFields = {};
        self.sessionFields.put(SESSION_PLAYER_SCORE,    session.createField("player_score",     7,  FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION, :nativeNum => SESSION_PLAYER_SCORE}));
        self.sessionFields.put(SESSION_OPPONENT_SCORE,  session.createField("opponent_score",   8,  FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION, :nativeNum => SESSION_OPPONENT_SCORE}));
        self.sessionFields.put(SESSION_STEPS,           session.createField("steps",            9,  FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION}));
        self.sessionFields.put(SESSION_AVG_TIME,        session.createField("avg_time",         10, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION}));
        self.sessionFields.put(SESSION_AVG_STEPS,       session.createField("avg_steps",        12, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION}));
        
        if (locEnabled) {
            self.lapFields.put(LAP_AVG_DISTANCE, session.createField("avg_distance", 5, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_LAP}));
            self.sessionFields.put(SESSION_AVG_DISTANCE, session.createField("avg_distance", 11, FitContributor.DATA_TYPE_UINT16, {:mesgType => FitContributor.MESG_TYPE_SESSION}));
        }

        // TODO: handle error during session start
        System.println("Session start result: "+resume());
    }

    (:sysgt6)
    private function createSession() {
        Sensor.enableSensorType(Sensor.SENSOR_HEARTRATE);
        if (tempEnabled) { Sensor.enableSensorType(Sensor.SENSOR_TEMPERATURE); }

        self.session = ActivityRecording.createSession({    // set up recording session
            :name=>"Roundnet",                             // set session name
            :sport=> Activity.SPORT_GENERIC,                 // set sport type
            :subSport=> Activity.SUB_SPORT_MATCH           // set sub sport type
        });
    }

    (:syslt6)
    private function createSession() {
        System.println("API level lower than 3.4.0");
        var sensors = [Sensor.SENSOR_HEARTRATE];
        if (tempEnabled) { sensors.add(Sensor.SENSOR_TEMPERATURE); }
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE, Sensor.SENSOR_TEMPERATURE]);

        self.session = ActivityRecording.createSession({
            :name=>"Roundnet",
            :sport=> ActivityRecording.SPORT_GENERIC,
            :subSport=> ActivityRecording.SUB_SPORT_MATCH,
        });
    }

    public function isRecording() as Boolean {
        return session.isRecording();
    }

    public function stop() as Boolean {
        if (session.isRecording()) {
            var status = session.stop();
            var timer = getApp().timer;
            timer.stop(recordTimer);
            return status;
        }
        return false;
    }

    public function resume() as Boolean {
        if (!session.isRecording()) {
            var status = session.start();
            recordTimer = getApp().timer.start(method(:updateRecordFields), 1, true);
            return status;
        }
        return false;
    }

    public function updateRecordFields() as Void {
        if (session.isRecording()) {
            time = Activity.getActivityInfo().timerTime / 1000;

            if (tempEnabled) {
                var temp = getTemperature();
                if (temp!=null) {
                    temp = temp.toNumber();
                    if (temp!=lastTemp) {
                        tempField.setData(temp);
                        lastTemp = temp;
                    }
                }
            }

            WatchUi.requestUpdate();
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

        (lapFields.get(LAP_AVG_TIME) as FitContributor.Field)
            .setData(pointsCount>0 ? (currentTime - timeOnLap)/pointsCount/1000 : 0);
        (lapFields.get(LAP_AVG_STEPS) as FitContributor.Field)
            .setData(pointsCount>0 ? (steps - stepsOnLap)/pointsCount : 0);
        
        if (locEnabled) {
            (lapFields.get(LAP_AVG_DISTANCE) as FitContributor.Field)
                .setData(pointsCount>0 ? (currentDistance - distanceOnLap)/pointsCount : 0);
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
        (sessionFields.get(SESSION_PLAYER_SCORE)    as FitContributor.Field).setData(gamesPlayer);
        (sessionFields.get(SESSION_OPPONENT_SCORE)  as FitContributor.Field).setData(gamesOpponent);
        (sessionFields.get(SESSION_STEPS)           as FitContributor.Field).setData(steps);

        (sessionFields.get(SESSION_AVG_TIME)        as FitContributor.Field)
            .setData(gamesCount>0 ? info.timerTime/gamesCount/60000 : 0);
        (sessionFields.get(SESSION_AVG_STEPS)       as FitContributor.Field)
            .setData(gamesCount>0 ? steps/gamesCount : 0);

        if (locEnabled) {
            (sessionFields.get(SESSION_AVG_DISTANCE) as FitContributor.Field)
                .setData(gamesCount>0 ? info.elapsedDistance/gamesCount : 0);
        }

        session.save();
        exit();
    }

    public function discard() as Void {
        session.discard();
        exit();
    }

    private function exit() as Void {
        session = null;
        if (Sensor has :disableSensorType) {
            Sensor.disableSensorType(Sensor.SENSOR_HEARTRATE);
            Sensor.disableSensorType(Sensor.SENSOR_TEMPERATURE);
        } else {
            Sensor.setEnabledSensors([]);
        }
    }

    public function incrPlayerScore() as Void {
        scorePlayer++;
        Attention.vibrate([new Attention.VibeProfile(50, 80)]);
        WatchUi.requestUpdate();
    }
    
    public function incrOpponentScore() as Void {
        scoreOpponent++;
        Attention.vibrate([new Attention.VibeProfile(50, 80)]);
        WatchUi.requestUpdate();
    }

    public function decrPlayerScore() as Void {
        if (scorePlayer>0) {
            scorePlayer--;
            Attention.vibrate([new Attention.VibeProfile(50, 80)]);
        }
        WatchUi.requestUpdate();
    }

    public function decrOpponentScore() as Void {
        if (scoreOpponent>0) {
            scoreOpponent--;
            Attention.vibrate([new Attention.VibeProfile(50, 80)]);
        }
        WatchUi.requestUpdate();
    }

    public function getScore(teamId as Team) as Number {
        return teamId ? scoreOpponent : scorePlayer;
    }

    public function getGames(teamId as Team) as Number {
        return teamId ? gamesOpponent : gamesPlayer;
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