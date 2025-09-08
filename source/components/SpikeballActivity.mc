import Toybox.Lang;
import Toybox.System;
import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Sensor;


class SpikeballActivity {

    public enum Team {
        TEAM_YELLOW,
        TEAM_GREY,
    }

    private var session as ActivityRecording.Session;
    private var scoreYellow as Number;
    private var scoreGrey as Number;

    public function initialize() {
        self.scoreYellow = 0;
        self.scoreGrey = 0;

        if (Toybox.Sensor has :enableSensorType) { // API level >= 3.2.0
            Sensor.enableSensorType(Sensor.SENSOR_HEARTRATE);
            self.session = ActivityRecording.createSession({    // set up recording session
                :name=>"Spikeball",                             // set session name
                :sport=>Activity.SPORT_GENERIC,                 // set sport type
                :subSport=>Activity.SUB_SPORT_GENERIC           // set sub sport type
            });
        } else {
            System.println("Older device"); // API level < 3.2.0
            Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
            self.session = ActivityRecording.createSession({
                :name=>"Spikeball",
                :sport=>ActivityRecording.SPORT_GENERIC,
                :subSport=>ActivityRecording.SUB_SPORT_GENERIC,
            });
        }
    }

    public function startStop() as Boolean {
        if (session.isRecording()) {
            return !session.stop();
        } else {
            return session.start();
        }
    }

    public function getScore(teamId as Team) as Number {
        return teamId ? scoreGrey : scoreYellow;
    }

    public function addScore(teamId as Team) as Void {
        if (teamId) {
            scoreGrey++;
        } else {
            scoreYellow++;
        }
        WatchUi.requestUpdate();
    }

    public function getHR() as Number {
        var hr = Sensor.getInfo().heartRate;
        return hr!=null ? hr : 134;
    }

    public function getFormattedTime() as String{
        var time = Activity.getActivityInfo().timerTime / 1000;
        return (time/3600).format("%01d") + 146.toChar() + (time%3600/60).format("%02d") + 148.toChar() + (time%60).format("%02d");
    }
}