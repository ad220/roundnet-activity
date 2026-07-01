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

    (:initialized) private var session as ActivityRecording.Session;
    private var time as Number;
    private var timeOnLap as Number;
    private var distanceOnLap as Numeric;
    private var scorePlayer as Number;
    private var scoreOpponent as Number;
    private var gamesPlayer as Number;
    private var gamesOpponent as Number;
    private var stepsOnStart as Number;
    private var stepsOnLap as Number;
    private var serviceHistory as ByteArray;
    private var warmup as Boolean;

    (:initialized) private var serviceState as Number; // 0xF00: player tracker, 0x0F0: team position, 0x00F: server position
    (:initialized) private var equalServing as Boolean;
    (:initialized) private var pointsToSwitch as Number;
    (:initialized) private var pointsToWin as Number;
    (:initialized) private var twoPointsDiff as Boolean;
    (:initialized) private var retryAutoWin as Boolean;
    (:initialized) private var locEnabled as Boolean;

    private var lastTemp as Number?;
    private var tempField as FitContributor.Field?;
    (:initialized) private var recordTimer as TimerCallback;

    private var lapFields as Dictionary;
    private var sessionFields as Dictionary;
    private var delegate as RoundnetActivityDelegate?;

    public function initialize() {

        self.time               = 0;
        self.timeOnLap          = 0;
        self.distanceOnLap      = 0;
        self.scorePlayer        = 0;
        self.scoreOpponent      = 0;
        self.gamesPlayer        = 0;
        self.gamesOpponent      = 0;

        var startingSteps       = ActivityMonitor.getInfo().steps;
        if (startingSteps == null) { startingSteps = 0; }
        self.stepsOnStart       = startingSteps;
        self.stepsOnLap         = 0;
        self.warmup = false;

        self.serviceHistory     = new [256]b;

        refreshSettings();

        createSession();

        self.tempField = getApp().settings.get("sensor_temperature") as Boolean ? session.createField("temperature", 0, FitContributor.DATA_TYPE_SINT8, {:units => "°C", :nativeNum => RECORD_TEMPERATURE}) : null;

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
        var status = resume();
        System.println("Session started: "+status);
        if (!status) {
            exit();
        }
    }

    private function refreshSettings() as Void {
        var settings    = getApp().settings;
        serviceState    = settings.get("field_service") as Boolean ? 0xF0 : -1;
        equalServing    = settings.get("game_equal_serving") as Boolean;
        pointsToSwitch  = settings.get("game_switch_alarm") as Boolean ? settings.get("game_switch_points") as Number : 0;
        pointsToWin     = settings.get("game_win_auto") as Boolean ? settings.get("game_win_points") as Number : 0;
        twoPointsDiff   = settings.get("game_win_two_pt_diff") as Boolean;
        retryAutoWin    = settings.get("game_win_retry") as Boolean;
        locEnabled      = settings.get("sensor_location") as Boolean;
    }

    (:sysgt6)
    private function createSession() as Void {
        Sensor.enableSensorType(Sensor.SENSOR_HEARTRATE);
        if (tempField != null) { Sensor.enableSensorType(Sensor.SENSOR_TEMPERATURE); }

        self.session = ActivityRecording.createSession({    // set up recording session
            :name=>"Roundnet",                              // set session name
            :sport=> Activity.SPORT_GENERIC,                // set sport type
            :subSport=> Activity.SUB_SPORT_MATCH            // set sub sport type
        });
    }

    (:syslt6)
    private function createSession() as Void {
        var sensors = [Sensor.SENSOR_HEARTRATE] as Array<Sensor.SensorType>;
        if (tempField != null) { sensors.add(Sensor.SENSOR_TEMPERATURE); }
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE, Sensor.SENSOR_TEMPERATURE]);

        self.session = ActivityRecording.createSession({
            :name=>"Roundnet",
            :sport=> ActivityRecording.SPORT_GENERIC,
            :subSport=> ActivityRecording.SUB_SPORT_MATCH,
        });
    }

    public function registerDelegate(delegate as RoundnetActivityDelegate) as Void {
        self.delegate = delegate;
    }

    public function isRecording() as Boolean {
        return session.isRecording();
    }

    public function stop() as Boolean {
        if (session.isRecording()) {
            var status = session.stop();
            recordTimer.stop();
            delegate = null;
            return status;
        }
        return false;
    }

    public function resume() as Boolean {
        if (!session.isRecording()) {
            var status = session.start();
            if (status) {
                recordTimer = getApp().timer.start(method(:updateRecordFields), 1, true);
            }
            return status;
        }
        return false;
    }

    public function updateRecordFields() as Void {
        if (!session.isRecording()) { return; }

        var ttime = Activity.getActivityInfo().timerTime;
        time = ttime != null ? ttime / 1000 : 0;

        if (tempField != null) {
            var temp = getTemperature();
            if (temp != null) {
                temp = temp.toNumber();
                if (temp != lastTemp) {
                    (tempField as Field).setData(temp);
                    lastTemp = temp;
                }
            }
        }

        WatchUi.requestUpdate();
    }

    public function lap() as Void {
        if (session.isRecording()) {
            updateLapFields();
            session.addLap();

            refreshSettings();
            scorePlayer = 0;
            scoreOpponent = 0;

            var ttime = Activity.getActivityInfo().timerTime;
            time = ttime != null ? ttime / 1000 : 0;
        }
    }

    private function updateLapFields() as Void {
        var info                = Activity.getActivityInfo();
        var pointsCount         = scorePlayer + scoreOpponent;
        var steps               = getSteps();

        var currentTime         = info.timerTime;
        var currentDistance     = info.elapsedDistance;
        if (currentTime         == null) { currentTime      = 0; }
        if (currentDistance     == null) { currentDistance  = 0.0; }

        (lapFields.get(LAP_PLAYER_SCORE)    as FitContributor.Field).setData(scorePlayer);
        (lapFields.get(LAP_OPPONENT_SCORE)  as FitContributor.Field).setData(scoreOpponent);
        (lapFields.get(LAP_STEPS)           as FitContributor.Field).setData(steps - stepsOnLap);

        (lapFields.get(LAP_AVG_TIME)        as FitContributor.Field)
            .setData(pointsCount > 0 ? (currentTime - timeOnLap) / pointsCount / 1000 : 0);
        (lapFields.get(LAP_AVG_STEPS) as FitContributor.Field)
            .setData(pointsCount > 0 ? (steps - stepsOnLap) / pointsCount : 0);

        timeOnLap = currentTime;
        stepsOnLap = steps;

        if (locEnabled) {
            (lapFields.get(LAP_AVG_DISTANCE) as FitContributor.Field)
                .setData(pointsCount>0 ? (currentDistance - distanceOnLap)/pointsCount : 0);
            distanceOnLap = currentDistance;
        }

        if      (scorePlayer > scoreOpponent) { gamesPlayer++; }
        else if (scoreOpponent > scorePlayer) { gamesOpponent++; }
    }

    public function save() as Void {
        var steps = getSteps();
        var gamesCount = gamesPlayer + gamesOpponent;
        updateLapFields();

        (sessionFields.get(SESSION_PLAYER_SCORE)    as FitContributor.Field).setData(gamesPlayer);
        (sessionFields.get(SESSION_OPPONENT_SCORE)  as FitContributor.Field).setData(gamesOpponent);
        (sessionFields.get(SESSION_STEPS)           as FitContributor.Field).setData(steps);

        (sessionFields.get(SESSION_AVG_TIME)        as FitContributor.Field)
            .setData(gamesCount>0 ? time / gamesCount / 60000 : 0);
        (sessionFields.get(SESSION_AVG_STEPS)       as FitContributor.Field)
            .setData(gamesCount>0 ? steps / gamesCount : 0);

        if (locEnabled) {
            (sessionFields.get(SESSION_AVG_DISTANCE) as FitContributor.Field)
                .setData(gamesCount>0 ? getDistance() / gamesCount : 0);
        }

        session.save();
        exit();
    }

    public function discard() as Void {
        session.discard();
        exit();
    }

    private function exit() as Void {
        delegate = null;
        recordTimer.stop();
        recordTimer.clear();

        if (Sensor has :disableSensorType) {
            Sensor.disableSensorType(Sensor.SENSOR_HEARTRATE);
            Sensor.disableSensorType(Sensor.SENSOR_TEMPERATURE);
        } else {
            Sensor.setEnabledSensors([]);
        }
    }

    public function incrPlayerScore() as Void {
        scorePlayer++;
        onPoint(scorePlayer>=pointsToWin and (!twoPointsDiff or scorePlayer>=scoreOpponent+2), TEAM_PLAYER);
    }

    public function incrOpponentScore() as Void {
        scoreOpponent++;
        onPoint(scoreOpponent>=pointsToWin and (!twoPointsDiff or scoreOpponent>=scorePlayer+2), TEAM_OPPONENT);
    }

    public function decrPlayerScore() as Void {
        if (scorePlayer>0) {
            scorePlayer--;
            decodeServiceState(serviceHistory[scorePlayer + scoreOpponent]);
            Attention.vibrate([new Attention.VibeProfile(50, 80)]);
        }
        WatchUi.requestUpdate();
    }

    public function decrOpponentScore() as Void {
        if (scoreOpponent>0) {
            scoreOpponent--;
            decodeServiceState(serviceHistory[scorePlayer + scoreOpponent]);
            Attention.vibrate([new Attention.VibeProfile(50, 80)]);
        }
        WatchUi.requestUpdate();
    }

    private function onPoint(winCond as Boolean, winner as Team) as Void {
        winCond = winCond and pointsToWin > 1;
        var points = scorePlayer + scoreOpponent;

        // serving helper update
        if (serviceState != -1) {
            if (equalServing) {
                updateEqualServing();
            } else {
                updateLegacyServing(winner);
            }
        }
        serviceHistory[points] = encodeServiceState();

        if (winCond) {
            if (!retryAutoWin)      { pointsToWin &= 1; }
            if (delegate != null)   { delegate.warnLap(); }
        }
        else {
            // check if rotating positions
            var checkSwitch =
                pointsToSwitch!=0 and
                (equalServing ? (points+1)%4 : points%pointsToSwitch) == 0 and
                (!equalServing or points < pointsToWin << 1 - 1);

            if (checkSwitch) {
                if (Attention has :vibrate) {
                    Attention.vibrate([new Attention.VibeProfile(80, 600)]);
                }
                if (Attention has :playTone) {
                    Attention.playTone({:toneProfile => [new Attention.ToneProfile(690, 600)]});
                }

                if (delegate != null) {
                    delegate.triggerSwitchAlarm();
                }
            } else {
                Attention.vibrate([new Attention.VibeProfile(50, 80)]);
            }

            WatchUi.requestUpdate();
        }
    }

    private function updateEqualServing() as Void {
        var server = serviceState & 0x0F;
        var totalScore = scorePlayer + scoreOpponent;
        var mask = 0;

        if (totalScore >= pointsToWin << 1 - 1) {
            // 2 points difference win condition
            var shift = (totalScore - pointsToWin << 1 + 2) % 4;
            if (shift == 0) { shift = 2; }
            mask = server ^ (server << shift + server >> (4-shift)) & 0x0F;
        }
        else if (totalScore & 1 == 1 or server & 0x09 == 0){
            // swap opponents if they are on their second service
            if (serviceState & (server << 4) != 0 && totalScore & 1 == 0) { serviceState ^= 0xF00; }

            // changing server counter clockwise
            mask = server ^ (server << 1 + server >> 3) & 0x0F;
        }
        else {
            // swapping positions with team mate
            mask = server==1 ? 0xFA0 : 0xFAA;
        }

        serviceState ^= mask;
    }

    private function updateLegacyServing(winner as Team) as Void {
        var server = serviceState & 0x0F;
        var servingTeam = serviceState & (server << 4) ? TEAM_OPPONENT : TEAM_PLAYER;

        if (winner == servingTeam) {
            // swapping team mate positions
            if (servingTeam == TEAM_OPPONENT) {
                serviceState ^= (serviceState >> 4) & 0x0F;
            } else {
                serviceState ^= server==1 ? 0xA0 : 0xAA;
            }
            serviceState ^= 0xF00;
        } else {
            var oddScore = (winner ? scoreOpponent : scorePlayer) & 1;
            var mask = ((serviceState >> 7) ^ oddScore) & 1 ? 0x0A : 0x05;
            var team = (serviceState >> 4) & 0x0F;
            mask &= winner ? team : ~team;
            serviceState ^= mask ^ server;
        }
    }

    private function encodeServiceState() as Char {
        var result = 0;
        result |= serviceState & 0x800 ? 8 : 0;
        result |= serviceState & 0x080 ? 4 : 0;
        result |= serviceState & 0x00C ? 2 : 0;
        result |= serviceState & 0x00A ? 1 : 0;
        return result.toChar();
    }

    private function decodeServiceState(state as Number) as Void {
        serviceState = 0;
        serviceState |= state & 8 ? 0xA00 : 0x500;
        serviceState |= state & 4 ? 0x0C0 : 0x060;
        serviceState |= 1 << (state & 0x03);
    }

    public function initServiceHelper(team as Team) as Void {
        if      (serviceState == 0xF0) {
            // team mate position
            serviceState &= 0x60 << team;
        }
        else if (serviceState & 0x0F == 0) {
            // server position
            serviceState ^= 1 << (serviceState >> 7 + team << 1);
            serviceState ^= 0x500;
            serviceHistory[0] = encodeServiceState();
        }
        WatchUi.requestUpdate();
    }

    public function isHelperReady() as Boolean {
        return serviceState & 0x0F != 0;
    }

    public function getScore(teamId as Team) as Number {
        return teamId ? scoreOpponent : scorePlayer;
    }

    public function getGames(teamId as Team) as Number {
        return teamId ? gamesOpponent : gamesPlayer;
    }

    public function getHR() as Number? {
        return Sensor.getInfo().heartRate;
    }

    public function getSteps() as Number {
        var steps = ActivityMonitor.getInfo().steps;
        return steps != null ? steps - stepsOnStart : 0;
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

    public function getFormattedTime(ofLap as Boolean) as String {
        var t = ofLap ? time - timeOnLap/1000 : time;
        return (t / 3600).format("%01d") + "'" + (t % 3600 / 60).format("%02d") + '"' + (t % 60).format("%02d");
    }

    public function getServiceState() as Number {
        return serviceState;
    }

    public function toggleWarmup() as Void {
        warmup = !warmup;
    }

    public function isWarmup() as Boolean {
        return warmup;
    }

    public function getFormattedField(field as LoopField.FieldId) as String {
        if      (field == LoopField.FIELD_DISTANCE) {
            return getSteps() + "\n" + (getDistance()/1000.0).format("%.2f") + LoopField.fieldUnits[LoopField.FIELD_DISTANCE];
        }
        else if (field == LoopField.FIELD_CALORIES) {
            return getKcal() + LoopField.fieldUnits[LoopField.FIELD_CALORIES];
        }
        else if (field == LoopField.FIELD_SCORE) {
            return getGames(RoundnetActivity.TEAM_PLAYER) + " - " + getGames(RoundnetActivity.TEAM_OPPONENT);
        }
        else if (field == LoopField.FIELD_TEMPERATURE) {
            var temp = getTemperature();
            return (temp!=null ? temp.format("%.1f") : "- - ") + LoopField.fieldUnits[LoopField.FIELD_TEMPERATURE];
        }
        else if (field == LoopField.FIELD_DAYTIME) {
            var daytime = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            return daytime.hour + ":" + daytime.min.format("%02d");
        }
        System.println("Unknown field id");
        return ". . .";
    }
}