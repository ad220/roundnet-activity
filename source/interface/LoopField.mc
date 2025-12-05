import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Application;
import Toybox.Math;

using InterfaceComponentsManager as ICM;

class LoopField extends Drawable {

    public enum FieldId {
        FIELD_DISTANCE,
        FIELD_CALORIES,
        FIELD_SCORE,
        FIELD_TEMPERATURE,
        FIELD_DAYTIME,
        FIELD_SWITCH,
        FIELD_SERVICE,

        FIELD_COUNT,
    }

    private var activity as RoundnetActivity;
    private var stateIndex as Number;
    private var enabledFields as Array<FieldId>;
    private var currentIcon as BitmapResource?;
    private var label as String;
    private var icons as Array<ResourceId?>;
    private var autoScroll as Boolean;
    private var scrollSpeed as Number;
    private var units as Array<String?>;
    private var currentTimer as TimerCallback?;


    public function initialize(activity as RoundnetActivity) {
        Drawable.initialize({});

        self.activity = activity;
        self.enabledFields = [];
        self.stateIndex = -1;
        self.currentIcon = null;
        self.label = "";
        self.icons = [
            Rez.Drawables.Steps,
            Rez.Drawables.Calories,
            Rez.Drawables.Score,
            Rez.Drawables.Temperature,
            Rez.Drawables.Daytime,
            Rez.Drawables.Switch,
            null
        ];
        self.units = [
            loadResource(Rez.Strings.Kilometers),
            loadResource(Rez.Strings.KCalories),
            null,
            loadResource(Rez.Strings.Celsius),
            null,
            null
        ];
        self.autoScroll = getApp().settings.get("autoscroll") as Boolean;
        self.scrollSpeed = (2*(getApp().settings.get("scrollspeed") as Number - 1.5)).toNumber();

        retrieveFieldSettings();
        resetField();
    }

    private function retrieveFieldSettings() as Void {
        var settings = getApp().settings;
        if (settings.get("field_distance") as Boolean)      { enabledFields.add(FIELD_DISTANCE); }
        if (settings.get("field_calories") as Boolean)      { enabledFields.add(FIELD_CALORIES); }
        if (settings.get("field_score") as Boolean)         { enabledFields.add(FIELD_SCORE); }
        if (settings.get("field_temperature") as Boolean)   { enabledFields.add(FIELD_TEMPERATURE); }
        if (settings.get("field_daytime") as Boolean)       { enabledFields.add(FIELD_DAYTIME); }
        if (settings.get("field_service") as Boolean)       { enabledFields.add(FIELD_SERVICE); }
    }

    public function resetField() as Void  {
        var serviceIdx = enabledFields.indexOf(FIELD_SERVICE);
        if (serviceIdx != -1) {
            stateIndex = serviceIdx;
            refreshField();
        } else if (stateIndex == -1) {
            nextField();
        }
    }

    public function draw(dc as Dc) as Void {
        if (currentIcon == null) {
            drawService(dc);
            return;
        }

        dc.drawBitmap(ICM.scaleX(0.52), ICM.scaleY(0.45), currentIcon);
        dc.drawText(ICM.scaleX(0.65), ICM.scaleY(0.5), ICM.fontSmall, label, ICM.JTEXT_LEFT);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(ICM.scaleX(0.005));
        var count = enabledFields.size();
        for (var i=0; i<count; i++) {
            dc.drawCircle(ICM.scaleX(0.69) + ICM.scaleX(0.04)*(i-count/2), ICM.scaleY(0.62), ICM.scaleX(0.01));
            if (i==stateIndex) {
                dc.fillCircle(ICM.scaleX(0.69) + ICM.scaleX(0.04)*(i-count/2), ICM.scaleY(0.62), ICM.scaleX(0.01));
            }
        }
    }

    private function drawService(dc as Dc) as Void {
        var state = activity.getServiceState();

        // setup service helper
        if (state & 0x0F == 0) {
            dc.drawText(ICM.scaleX(0.7), ICM.scaleY(0.5), ICM.fontSmall, label, ICM.JTEXT_MID);
            return;
        }

        var radius = ICM.scaleX(0.085);
        var dotRadius = ICM.scaleX(0.032);
        
        dc.setPenWidth(ICM.scaleX(0.012));
        ICM.toggleAA(dc, true);

        for (var i=0; i<4; i++) {
            dc.setColor(state >> (i+4) & 1 ? Graphics.COLOR_DK_GRAY : 0xFFAA00, Graphics.COLOR_BLACK);
            var x = ICM.scaleX(0.69) + radius*Math.sin(i*Math.PI/2);
            var y = ICM.scaleY(0.5) + radius*Math.cos(i*Math.PI/2);

            if (state >> i & 1) {
                dc.drawCircle(x, y, dotRadius);
            } else {
                dc.fillCircle(x, y, dotRadius);
            }
        }

        ICM.toggleAA(dc, false);
    }

    public function nextField() as Void {
        stateIndex = (stateIndex+1) % enabledFields.size();
        refreshField();
    }

    public function previousField() as Void {
        stateIndex = (stateIndex-1 + enabledFields.size()) % enabledFields.size();
        refreshField();
    }

    public function refreshField() as Void {
        // refresh icon
        if (enabledFields[stateIndex] != FIELD_SERVICE) {
            currentIcon = loadResource(icons[enabledFields[stateIndex]]);
        } else {
            currentIcon = null;
        }

        // refresh label
        switch (enabledFields[stateIndex]) {
            case FIELD_DISTANCE:
                label = activity.getSteps() + "\n" + (activity.getDistance()/1000.0).format("%.2f") + units[FIELD_DISTANCE];
                break;
            case FIELD_CALORIES:
                label = activity.getKcal() + units[FIELD_CALORIES];
                break;
            case FIELD_SCORE:
                label = activity.getGames(RoundnetActivity.TEAM_PLAYER)+" - "+activity.getGames(RoundnetActivity.TEAM_OPPONENT);
                break;
            case FIELD_TEMPERATURE:
                var temp = activity.getTemperature();
                label = (temp!=null ? temp.format("%.1f") : "- - ") + units[FIELD_TEMPERATURE];
                break;
            case FIELD_DAYTIME:
                var daytime = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
                label = daytime.hour + ":" + daytime.min.format("%02d");
                break;
            case FIELD_SERVICE:
                var state = activity.getServiceState();
                if (state == 0xF0) {
                    label = loadResource(Rez.Strings.FirstPosition);
                } else if (state & 0x0F == 0) {
                    label = loadResource(Rez.Strings.FirstService);
                }
                break;
            default:
                System.println("Unknown field id");
                break;
        }

        // setup next automatic refresh
        getApp().timer.stop(currentTimer);
        if (autoScroll and activity.isHelperReady()) {
            currentTimer = getApp().timer.start(method(:nextField), scrollSpeed, false);
        }
    }

    public function showSwitchAlarm() as Void {
        currentIcon = loadResource(icons[FIELD_SWITCH]);
        label = loadResource(Rez.Strings.Switch);
        requestUpdate();
        getApp().timer.stop(currentTimer);
        currentTimer = getApp().timer.start(method(:refreshField), scrollSpeed, false);
    }

    public function stop() as Void {
        getApp().timer.stop(currentTimer);
    }
}