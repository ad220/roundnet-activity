import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.ActivityRecording;
import Toybox.Position;
import Toybox.Timer;

using InterfaceComponentsManager as ICM;

class RoundnetApp extends Application.AppBase {

    public const version = "v0.13";
    
    public var timer as TimerController;
    public var preciseTimer as Timer.Timer;
    public var settings as Dictionary<String, Object>;

    function initialize() {
        AppBase.initialize();

        self.timer = new TimerController(1000);
        self.preciseTimer = new Timer.Timer();

        self.settings = Storage.getValue("settings") as Dictionary;
        var defaults = WatchUi.loadResource(Rez.JsonData.DefaultSettings) as Dictionary;
        var version = defaults.get("version") as Number;
        
        if (settings == null or settings.get("version")==null) {
            Storage.clearValues();
            settings = defaults;
        } else if (settings.get("version") as Number < version) {
            var keys = defaults.keys();
            for (var i=0; i<keys.size(); i++) {
                var param = settings.get(keys[i]);
                if (param != null) {
                    defaults.put(keys[i], param);
                }
            }
            settings = defaults;
            settings.put("version", version);
        }
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        ICM.loadFonts();
        ICM.computeInterfaceConstants();
        Position.enableLocationEvents(getLocationSetting(), null);
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        timer.stopAll();
        ICM.unloadFonts();
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        Storage.setValue("settings", settings);
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new StartView();
        return [view, new StartDelegate(view)];
    }

    public function getLocationSetting() as Position.LocationAcquisitionType {
        return settings.get("sensor_location") as Boolean ? Position.LOCATION_CONTINUOUS : Position.LOCATION_DISABLE;
    }
}

function getApp() as RoundnetApp {
    return Application.getApp() as RoundnetApp;
}