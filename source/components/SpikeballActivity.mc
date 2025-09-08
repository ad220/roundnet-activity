import Toybox.Lang;
import Toybox.System;
import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.ActivityMonitor;
import Toybox.Sensor;


class SpikeballActivity {

    public enum Team {
        TEAM_YELLOW,
        TEAM_GREY,
    }

    private var session as ActivityRecording.Session;
    private var scoreYellow as Number;
    private var scoreGrey as Number;

    private var stepsOnStart as Number;

    public function initialize() {
        self.scoreYellow = 0;
        self.scoreGrey = 0;
        self.stepsOnStart = ActivityMonitor.getInfo().steps;

        if (Toybox.Sensor has :enableSensorType) { // API level >= 3.2.0
            Sensor.enableSensorType(Sensor.SENSOR_HEARTRATE);
            Sensor.enableSensorType(Sensor.SENSOR_TEMPERATURE);
            self.session = ActivityRecording.createSession({    // set up recording session
                :name=>"Spikeball",                             // set session name
                :sport=>Activity.SPORT_GENERIC,                 // set sport type
                :subSport=>Activity.SUB_SPORT_GENERIC           // set sub sport type
            });
        } else {
            System.println("Older device"); // API level < 3.2.0
            Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE, Sensor.SENSOR_TEMPERATURE]);
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
            stepsOnStart = ActivityMonitor.getInfo().steps;
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
        return Sensor.getInfo().heartRate;
    }

    public function getSteps() as Number {
        var steps = ActivityMonitor.getInfo().steps - stepsOnStart;
        return steps!=null ? steps : 6942;
    }

    public function getDistance() as Number {
        var distance = Activity.getActivityInfo().elapsedDistance;
        return distance!=null ? distance.toNumber() : 4269;
    }

    public function getKcal() as Number {
        var kcal = Activity.getActivityInfo().calories;
        return kcal!=null ? kcal : 420;
    }

    public function getTemperature() as Float {
        var temp = Sensor.getInfo().temperature;
        return temp!=null ? temp : 21.6;
    }

    public function getFormattedTime() as String{
        var time = Activity.getActivityInfo().timerTime / 1000;
        return (time/3600).format("%01d") + 146.toChar() + (time%3600/60).format("%02d") + 148.toChar() + (time%60).format("%02d");
    }
}