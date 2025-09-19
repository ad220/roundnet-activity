import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Application;

using InterfaceComponentsManager as ICM;

class LoopField extends WatchUi.Drawable {

    public enum FieldId {
        FIELD_DISTANCE,
        FIELD_CALORIES,
        FIELD_SCORE,
        FIELD_TEMPERATURE,
        FIELD_DAYTIME,
        FIELD_SWITCH,

        FIELD_COUNT,
    }

    private var activity as RoundnetActivity;
    private var stateIndex as Number;
    private var enabledFields as Array<FieldId>;
    private var currentIcon as BitmapResource?;
    private var label as String;
    private var icons as Array<WatchUi.BitmapResource>;
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
            WatchUi.loadResource(Rez.Drawables.Steps),
            WatchUi.loadResource(Rez.Drawables.Calories),
            WatchUi.loadResource(Rez.Drawables.Score),
            WatchUi.loadResource(Rez.Drawables.Temperature),
            WatchUi.loadResource(Rez.Drawables.Daytime),
            WatchUi.loadResource(Rez.Drawables.Switch)
        ];
        self.units = [
            WatchUi.loadResource(Rez.Strings.Kilometers),
            WatchUi.loadResource(Rez.Strings.KCalories),
            null,
            WatchUi.loadResource(Rez.Strings.Celsius),
            null,
        ];
        self.autoScroll = getApp().settings.get("autoscroll") as Boolean;
        self.scrollSpeed = (2*(getApp().settings.get("scrollspeed") as Number - 1.5)).toNumber();

        retrieveFieldSettings();
        nextField();
    }

    private function retrieveFieldSettings() as Void {
        var settings = getApp().settings;
        if (settings.get("field_distance") as Boolean)      { enabledFields.add(FIELD_DISTANCE); }
        if (settings.get("field_calories") as Boolean)      { enabledFields.add(FIELD_CALORIES); }
        if (settings.get("field_score") as Boolean)         { enabledFields.add(FIELD_SCORE); }
        if (settings.get("field_temperature") as Boolean)   { enabledFields.add(FIELD_TEMPERATURE); }
        if (settings.get("field_daytime") as Boolean)       { enabledFields.add(FIELD_DAYTIME); }
    }

    public function draw(dc as $.Toybox.Graphics.Dc) as Void {
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

    public function nextField() as Void {
        stateIndex = (stateIndex+1) % enabledFields.size();
        refreshField();
    }

    public function previousField() as Void {
        stateIndex = (stateIndex-1 + enabledFields.size()) % enabledFields.size();
        refreshField();
    }

    public function refreshField() as Void {
        currentIcon = icons[enabledFields[stateIndex]];
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
            default:
                System.println("Unknown field id");
                break;
        }
        WatchUi.requestUpdate();
        if (autoScroll) {
            getApp().timer.stop(currentTimer);
            currentTimer = getApp().timer.start(method(:nextField), scrollSpeed, false);
        }
    }

    public function showSwitchAlarm() as Void {
        currentIcon = icons[FIELD_SWITCH];
        label = WatchUi.loadResource(Rez.Strings.Switch);
        WatchUi.requestUpdate();
        getApp().timer.stop(currentTimer);
        currentTimer = getApp().timer.start(method(:refreshField), 8, false);
    }
}