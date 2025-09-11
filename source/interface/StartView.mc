import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Time;
import Toybox.Position;

using InterfaceComponentsManager as ICM;

class StartView extends WatchUi.View {

    private var locationEnabled as Boolean;
    private var temperatureEnabled as Boolean;

    public function initialize() {
        View.initialize();

        self.locationEnabled = true;
        self.temperatureEnabled = true;
    }

    public function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.StartLayout(dc));
    }

    public function onShow() as Void {
        var sensorsSettings = getApp().sensorsSettings;
        locationEnabled = sensorsSettings.get("location") as Boolean;
        temperatureEnabled = sensorsSettings.get("temperature") as Boolean;
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        View.onUpdate(dc);
        dc.setAntiAlias(true);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(ICM.scaleX(0.06), ICM.scaleY(0.465), ICM.scaleX(0.007));
        dc.fillCircle(ICM.scaleX(0.06), ICM.scaleY(0.5), ICM.scaleX(0.007));
        dc.fillCircle(ICM.scaleX(0.06), ICM.scaleY(0.535), ICM.scaleX(0.007));

        var daytime = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        daytime = daytime.hour + ":" + daytime.min.format("%02d");
        dc.drawText(ICM.scaleX(0.5), ICM.scaleY(0.9), ICM.fontMedium, daytime, ICM.JTEXT_MID);

        if (locationEnabled) {
            var gpsQuality = Position.getInfo().accuracy;
            dc.setColor([0xFF0000, 0xFF5500, 0xAAAA00, 0x55AA00, 0x00AA00][gpsQuality], Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(ICM.scaleX(0.46), ICM.scaleY(0.29), ICM.scaleX((gpsQuality+1)*0.015), ICM.scaleY(0.02));
            dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
            dc.drawRectangle(ICM.scaleX(0.46), ICM.scaleY(0.29), ICM.scaleX(0.08), ICM.scaleY(0.02));
        } else {
            dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(ICM.scaleX(0.52), ICM.scaleY(0.26), ICM.scaleX(0.54), ICM.scaleY(0.28));
            dc.drawLine(ICM.scaleX(0.52), ICM.scaleY(0.28), ICM.scaleX(0.54), ICM.scaleY(0.26));
        }

        if (temperatureEnabled) {
            dc.setColor(0x00AA00, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(ICM.scaleX(0.52), ICM.scaleY(0.17), ICM.scaleX(0.53), ICM.scaleY(0.18));
            dc.drawLine(ICM.scaleX(0.53), ICM.scaleY(0.18), ICM.scaleX(0.54), ICM.scaleY(0.16));
        } else {
            dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(ICM.scaleX(0.52), ICM.scaleY(0.16), ICM.scaleX(0.54), ICM.scaleY(0.18));
            dc.drawLine(ICM.scaleX(0.52), ICM.scaleY(0.18), ICM.scaleX(0.54), ICM.scaleY(0.16));
        }
    }

    public function onHide() as Void {
        
    }
}

class StartDelegate extends WatchUi.BehaviorDelegate {

    private var lastGpsAccuracy as Number;
    private var locationSetting as Position.LocationAcquisitionType?;
    private var updater as TimerCallback?;

    public function initialize() {
        BehaviorDelegate.initialize();

        self.lastGpsAccuracy = Position.getInfo().accuracy;
        registerUpdates();
    }

    public function registerUpdates() {
        self.locationSetting = getApp().getLocationSetting();
        self.updater = getApp().timer.start(method(:update), 10, true);
        Position.enableLocationEvents(locationSetting, method(:onPosition));
    }
    
    public function onSelect() as Boolean {
        getApp().timer.stop(updater);
        Position.enableLocationEvents(locationSetting, null);
        var activity = new SpikeballActivity();
        WatchUi.pushView(new SpikeballActivityView(activity), new SpikeballActivityDelegate(activity), SLIDE_UP);
        return true;
    }

    public function onMenu() as Boolean {
        getApp().timer.stop(updater);
        Position.enableLocationEvents(locationSetting, null);
        WatchUi.pushView(new Rez.Menus.SettingsMenu(), new SettingsDelegate(), SLIDE_LEFT);
        return true;
    }

    public function onPreviousPage() as Boolean {
        return onMenu();
    }


    public function onPosition(loc as Position.Info) as Void {
        if (lastGpsAccuracy != loc.accuracy) {
            lastGpsAccuracy = loc.accuracy;
            WatchUi.requestUpdate();
        }
    }

    public function update() as Void {
        WatchUi.requestUpdate();
    }
}