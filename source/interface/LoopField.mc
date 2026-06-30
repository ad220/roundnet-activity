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

    static const fieldUnits = [
        WatchUi.loadResource(Rez.Strings.Kilometers),
        WatchUi.loadResource(Rez.Strings.KCalories),
        null,
        WatchUi.loadResource(Rez.Strings.Celsius),
        null,
        null
    ] as Array<String>;

    private var activity as RoundnetActivity;
    private var stateIndex as Number;
    private var enabledFields as Array<FieldId>;
    private var currentIcon as BitmapResource?;
    private var label as String;
    private var icons as Array<ResourceId?>;
    private var autoScroll as Boolean;
    private var scrollSpeed as Number;
    private var currentTimer as TimerCallback?;
    private var serviceTagsEnabled as Boolean;
    private var obsModeEnabled as Boolean;


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
            Rez.Drawables.Medal,
            Rez.Drawables.Temperature,
            Rez.Drawables.Daytime,
            Rez.Drawables.Switch,
            null
        ];
        self.autoScroll = getApp().settings.get("autoscroll") as Boolean;
        self.scrollSpeed = (2*(getApp().settings.get("scrollspeed") as Number - 1.5)).toNumber();
        self.serviceTagsEnabled = true;
        self.obsModeEnabled = false;

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
        serviceTagsEnabled  = settings.get("field_service_tags") as Boolean;
        obsModeEnabled      = settings.get("observer_mode") as Boolean;
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

        dc.drawBitmap(Screen.WIDTH * 0.52, Screen.HEIGHT * 0.45, currentIcon);
        dc.drawText(Screen.WIDTH * 0.65, Screen.HEIGHT * 0.5, ICM.fontSmall, label, ICM.JTEXT_LEFT);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(Screen.WIDTH * 0.005);
        var count = enabledFields.size();
        for (var i=0; i<count; i++) {
            dc.drawCircle(Screen.WIDTH * 0.69 + Screen.WIDTH * 0.04*(i-count/2), Screen.HEIGHT * 0.62, Screen.WIDTH * 0.01);
            if (i==stateIndex) {
                dc.fillCircle(Screen.WIDTH * 0.69 + Screen.WIDTH * 0.04*(i-count/2), Screen.HEIGHT * 0.62, Screen.WIDTH * 0.01);
            }
        }
    }

    private function drawService(dc as Dc) as Void {
        var state = activity.getServiceState();

        // setup service helper
        if (state & 0x0F == 0) {
            dc.drawText(Screen.WIDTH * 0.7, Screen.HEIGHT * 0.5, ICM.fontSmall, label, ICM.JTEXT_MID);
            return;
        }

        var radius = Screen.WIDTH * 0.094;
        var dotRadius = Screen.WIDTH * 0.039;
        
        dc.setPenWidth(Screen.WIDTH * 0.014);
        ICM.toggleAA(dc, true);

        for (var i=0; i<4; i++) {
            var isOpponent = state >> (i+4) & 1;
            var color = isOpponent ? Graphics.COLOR_DK_GRAY : 0xFFAA00;
            dc.setColor(color, Graphics.COLOR_BLACK);
            var x = Screen.WIDTH * 0.7 + radius*Math.sin(i*Math.PI/2);
            var y = Screen.HEIGHT * 0.5 + radius*Math.cos(i*Math.PI/2);

            if (state >> i & 1) {
                dc.drawCircle(x, y, dotRadius);
            } else {
                dc.fillCircle(x, y, dotRadius);
                if (serviceTagsEnabled) {
                    dc.setColor(Graphics.COLOR_WHITE, color);
                    if (isOpponent) {
                        dc.drawText(x, y, ICM.fontSmall, state >> (8+i) & 1 ? "A" : "B", ICM.JTEXT_MID);
                    } else if (obsModeEnabled) {
                        dc.drawText(x, y, ICM.fontSmall, i ? "B" : "A", ICM.JTEXT_MID);
                    }
                }
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
        // refresh icon and label
        if (enabledFields[stateIndex] != FIELD_SERVICE) {
            currentIcon = loadResource(icons[enabledFields[stateIndex]] as ResourceId) as BitmapResource;
            label = activity.getFormattedField(stateIndex as FieldId);
        } else {
            currentIcon = null;

            var state = activity.getServiceState();
            if (state == 0xF0 and !obsModeEnabled)  { label = loadResource(Rez.Strings.FirstPosition) as String; }
            else if (state & 0x0F == 0)             { label = loadResource(Rez.Strings.FirstService) as String; }
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