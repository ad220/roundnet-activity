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

    private var lastGpsAccuracy as Position.Quality or Number;
    private var locationSetting as Position.LocationAcquisitionType;
    private var updater as TimerCallback?;

    public function initialize() {
        View.initialize();

        self.locationEnabled = true;
        self.temperatureEnabled = true;
        self.lastGpsAccuracy = Position.QUALITY_NOT_AVAILABLE;
        self.locationSetting = Position.LOCATION_CONTINUOUS;
    }

    public function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.StartLayout(dc));
    }

    public function onShow() as Void {
        (findDrawableById("title") as Text).setText(Rez.Strings.AppName);
        locationEnabled = getApp().settings.get("sensor_location") as Boolean;
        temperatureEnabled = getApp().settings.get("sensor_temperature") as Boolean;
        lastGpsAccuracy = Position.getInfo().accuracy;
        locationSetting = getApp().getLocationSetting();
        updater = getApp().timer.start(method(:update), 10, true);
        Position.enableLocationEvents(locationSetting, method(:onPosition));
    }

    public function onPosition(loc as Position.Info) as Void {
        if (lastGpsAccuracy != loc.accuracy) {
            lastGpsAccuracy = loc.accuracy;
            requestUpdate();
        }
    }

    public function update() as Void {
        requestUpdate();
    }

    public function onUpdate(dc as Graphics.Dc) as Void {
        View.onUpdate(dc);
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(ICM.scaleX(0.06), ICM.scaleY(0.465), ICM.scaleX(0.007));
        dc.fillCircle(ICM.scaleX(0.06), ICM.scaleY(0.5), ICM.scaleX(0.007));
        dc.fillCircle(ICM.scaleX(0.06), ICM.scaleY(0.535), ICM.scaleX(0.007));

        var daytime = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        daytime = daytime.hour + ":" + daytime.min.format("%02d");
        dc.drawText(ICM.scaleX(0.5), ICM.scaleY(0.9), ICM.fontMedium, daytime, ICM.JTEXT_MID);

        if (locationEnabled) {
            dc.setPenWidth(ICM.scaleX(0.005));
            dc.setColor([0xFF0000, 0xFF5500, 0xAAAA00, 0x55AA00, 0x00AA00][lastGpsAccuracy], Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(ICM.scaleX(0.46), ICM.scaleY(0.29), ICM.scaleX((lastGpsAccuracy+1)*0.015), ICM.scaleY(0.02));
            dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
            dc.drawRectangle(ICM.scaleX(0.46), ICM.scaleY(0.29), ICM.scaleX(0.08), ICM.scaleY(0.02));
        } else {
            dc.setPenWidth(ICM.scaleX(0.008));
            dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(ICM.scaleX(0.515), ICM.scaleY(0.255), ICM.scaleX(0.54), ICM.scaleY(0.28));
            dc.drawLine(ICM.scaleX(0.515), ICM.scaleY(0.28), ICM.scaleX(0.54), ICM.scaleY(0.255));
        }

        dc.setPenWidth(ICM.scaleX(0.008));
        if (temperatureEnabled) {
            dc.setColor(0x00AA00, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(ICM.scaleX(0.515), ICM.scaleY(0.1675), ICM.scaleX(0.525), ICM.scaleY(0.18));
            dc.drawLine(ICM.scaleX(0.525), ICM.scaleY(0.18), ICM.scaleX(0.54), ICM.scaleY(0.155));
        } else {
            dc.setColor(0xFF0000, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(ICM.scaleX(0.515), ICM.scaleY(0.155), ICM.scaleX(0.54), ICM.scaleY(0.18));
            dc.drawLine(ICM.scaleX(0.515), ICM.scaleY(0.18), ICM.scaleX(0.54), ICM.scaleY(0.155));
        }
    }

    public function onHide() as Void {
        Position.enableLocationEvents(locationSetting, null);
        updater.stop();
        updater = null;
    }
}

class StartDelegate extends WatchUi.BehaviorDelegate {

    private var view as StartView;

    public function initialize(view as StartView) {
        BehaviorDelegate.initialize();

        self.view = view;
    }
    
    public function onSelect() as Boolean {
        return false;
    }

    public function onKey(keyEvent as KeyEvent) as Boolean {
        if (keyEvent.getKey()==KEY_ENTER and keyEvent.getType()==PRESS_TYPE_ACTION) {
            var activity = new RoundnetActivity();
            if (activity.isRecording()) {
                var view = new RoundnetActivityView(activity);
                var delegate = new RoundnetActivityDelegate(view, activity);
                activity.registerDelegate(delegate);
                WatchUi.pushView(view, new RoundnetActivityDelegate(view, activity), SLIDE_UP);
            } else {
                (view.findDrawableById("title") as Text).setText(Rez.Strings.StartFailed);
                requestUpdate();
            }
            return true;
        }
        return false;
    }

    public function onMenu() as Boolean {
        pushView(new Rez.Menus.SettingsMenu(), new SettingsDelegate(), SLIDE_LEFT);
        return true;
    }

    public function onPreviousPage() as Boolean {
        return onMenu();
    }
}