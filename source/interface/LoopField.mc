import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

using InterfaceComponentsManager as ICM;

class LoopField extends WatchUi.Drawable {

    public enum FieldState {
        FIELD_STEPS,
        FIELD_CALORIES,
        FIELD_TEMPERATURE,

        FIELD_COUNT,
    }

    private var activity as SpikeballActivity;
    private var state as Number;
    private var icons as Array<WatchUi.BitmapResource>;
    private var units as Array<String>;
    private var label as String;


    public function initialize(activity as SpikeballActivity) {
        Drawable.initialize({});

        self.activity = activity;
        self.state = FIELD_COUNT-1;
        self.label = "";
        self.icons = [
            WatchUi.loadResource(Rez.Drawables.Steps),
            WatchUi.loadResource(Rez.Drawables.Calories),
            WatchUi.loadResource(Rez.Drawables.Temperature)
        ];
        self.units = [
            WatchUi.loadResource(Rez.Strings.Kilometers),
            WatchUi.loadResource(Rez.Strings.KCalories),
            WatchUi.loadResource(Rez.Strings.Celsius),
        ];
        nextField();
    }

    public function draw(dc as $.Toybox.Graphics.Dc) as Void {
        dc.drawBitmap(ICM.scaleX(0.52), ICM.scaleY(0.45), icons[state]);
        dc.drawText(ICM.scaleX(0.65), ICM.scaleY(0.5), ICM.fontSmall, label, ICM.JTEXT_LEFT);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        for (var i=0; i<FIELD_COUNT; i++) {
            dc.drawCircle(ICM.scaleX(0.69) + ICM.scaleX(0.04)*(i-FIELD_COUNT/2), ICM.scaleY(0.62), ICM.scaleX(0.01));
            if (i==state) {
                dc.fillCircle(ICM.scaleX(0.69) + ICM.scaleX(0.04)*(i-FIELD_COUNT/2), ICM.scaleY(0.62), ICM.scaleX(0.01));
            }
        }
    }

    public function nextField() as Void {
        state = (state+1) % FIELD_COUNT;
        if (state == FIELD_STEPS) {
            label = activity.getSteps() + "\n" + (activity.getDistance()/1000.0).format("%.2f") + units[FIELD_STEPS];
        } else if (state == FIELD_CALORIES) {
            label = activity.getKcal() + units[FIELD_CALORIES];
        } else if (state == FIELD_TEMPERATURE) {
            label = activity.getTemperature().format("%.1f") + units[FIELD_TEMPERATURE];
        }
    }
}