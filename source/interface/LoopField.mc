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

        FIELD_COUNT,
    }

    private var activity as SpikeballActivity;
    private var stateIndex as Number;
    private var enabledFields as Array<FieldId>;
    private var label as String;
    private var icons as Array<WatchUi.BitmapResource>;
    private var units as Array<String?>;


    public function initialize(activity as SpikeballActivity) {
        Drawable.initialize({});

        self.activity = activity;
        self.enabledFields = [];
        self.stateIndex = -1;
        self.label = "";
        self.icons = [
            WatchUi.loadResource(Rez.Drawables.Steps),
            WatchUi.loadResource(Rez.Drawables.Calories),
            WatchUi.loadResource(Rez.Drawables.Score),
            WatchUi.loadResource(Rez.Drawables.Temperature),
            WatchUi.loadResource(Rez.Drawables.Daytime),
        ];
        self.units = [
            WatchUi.loadResource(Rez.Strings.Kilometers),
            WatchUi.loadResource(Rez.Strings.KCalories),
            null,
            WatchUi.loadResource(Rez.Strings.Celsius),
            null
        ];

        retrieveFieldSettings();
        nextField();
        activity.registerField(self);
    }

    private function retrieveFieldSettings() as Void {
        var fieldSettings = Application.Storage.getValue("datafieldsSettings") as Dictionary;
        System.println(fieldSettings);
        if (fieldSettings.get("distance") as Boolean)       { enabledFields.add(FIELD_DISTANCE); }
        if (fieldSettings.get("calories") as Boolean)       { enabledFields.add(FIELD_CALORIES); }
        if (fieldSettings.get("score") as Boolean)          { enabledFields.add(FIELD_SCORE); }
        if (fieldSettings.get("temperature") as Boolean)    { enabledFields.add(FIELD_TEMPERATURE); }
        if (fieldSettings.get("daytime") as Boolean)        { enabledFields.add(FIELD_DAYTIME); }
    }

    public function draw(dc as $.Toybox.Graphics.Dc) as Void {
        dc.drawBitmap(ICM.scaleX(0.52), ICM.scaleY(0.45), icons[enabledFields[stateIndex]]);
        dc.drawText(ICM.scaleX(0.65), ICM.scaleY(0.5), ICM.fontSmall, label, ICM.JTEXT_LEFT);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
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
        switch (enabledFields[stateIndex]) {
            case FIELD_DISTANCE:
                label = activity.getSteps() + "\n" + (activity.getDistance()/1000.0).format("%.2f") + units[FIELD_DISTANCE];
                break;
            case FIELD_CALORIES:
                label = activity.getKcal() + units[FIELD_CALORIES];
                break;
            case FIELD_SCORE:
                label = activity.getGames(SpikeballActivity.TEAM_PLAYER)+" - "+activity.getGames(SpikeballActivity.TEAM_OPPONENT);
                break;
            case FIELD_TEMPERATURE:
                var temp = activity.getTemperature();
                label = (temp!=null ? temp.format("%.1f") : "- - ") + units[FIELD_TEMPERATURE];
                break;
            case FIELD_DAYTIME:
                var daytime = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
                label = daytime.hour + ":" + daytime.min.format("%02d");
            default:
                System.println("Unknown field id");
                break;
        }
    }
}