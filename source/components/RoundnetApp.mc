import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.ActivityRecording;
import Toybox.Position;

using InterfaceComponentsManager as ICM;

class RoundnetApp extends Application.AppBase {

    public var timer as TimerController;
    public var settings as Dictionary<String, Object>;

    function initialize() {
        AppBase.initialize();

        self.timer = new TimerController(1000);

        self.settings = Storage.getValue("settings") as Dictionary;
        var defaults = WatchUi.loadResource(Rez.JsonData.DefaultSettings) as Dictionary;
        if (settings == null or settings.get("version")==null) {
            Storage.clearValues();
            settings = defaults;
        } else if (settings.get("version") as Number < defaults.get("version") as Number) {
            settings.put("version", defaults.get("version"));
            
            var keys = defaults.keys();
            for (var i=0; i<keys.size(); i++) {
                if (settings.get(keys[i])==null) {
                    settings.put(keys[i], defaults.get(keys[i]));
                }
            }
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