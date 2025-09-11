import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Time;
import Toybox.Position;

using InterfaceComponentsManager as ICM;

class StartView extends WatchUi.View {

    public function initialize() {
        View.initialize();

    }

    public function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.StartLayout(dc));
    }

    public function onShow() as Void {
        
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        View.onUpdate(dc);
        dc.setAntiAlias(true);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(ICM.scaleX(0.06), ICM.scaleY(0.465), ICM.scaleX(0.007));
        dc.fillCircle(ICM.scaleX(0.06), ICM.scaleY(0.5), ICM.scaleX(0.007));
        dc.fillCircle(ICM.scaleX(0.06), ICM.scaleY(0.535), ICM.scaleX(0.007));

        var daytime = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        daytime = daytime.hour + ":" + daytime.min;
        dc.drawText(ICM.scaleX(0.5), ICM.scaleY(0.9), ICM.fontMedium, daytime, ICM.JTEXT_MID);

        var gpsQuality = Position.getInfo().accuracy;
        dc.setColor([0xFF0000, 0xFF5500, 0xAAAA00, 0x55AA00, 0x00AA00][gpsQuality], Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(ICM.scaleX(0.46), ICM.scaleY(0.29), ICM.scaleX((gpsQuality+1)*0.015), ICM.scaleY(0.02));
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(ICM.scaleX(0.46), ICM.scaleY(0.29), ICM.scaleX(0.08), ICM.scaleY(0.02));
    }

    public function onHide() as Void {
        
    }
}

class StartDelegate extends WatchUi.BehaviorDelegate {

    private var timer as TimerController;
    private var updater as TimerCallback;
    private var lastGpsAccuracy as Number;

    public function initialize(timer as TimerController) {
        BehaviorDelegate.initialize();

        self.timer = timer;
        self.updater = timer.start(method(:update), 10, true);
        self.lastGpsAccuracy = Position.getInfo().accuracy;
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    public function onSelect() as Boolean {
        timer.stop(updater);
        var activity = new SpikeballActivity(timer);
        WatchUi.pushView(new SpikeballActivityView(activity), new SpikeballActivityDelegate(activity, timer), SLIDE_UP);
        return true;
    }

    public function onPosition(loc as Position.Info) as Void {
        if (loc.accuracy != lastGpsAccuracy) {
            WatchUi.requestUpdate();
        }
    }

    public function update() as Void {
        WatchUi.requestUpdate();
    }
}