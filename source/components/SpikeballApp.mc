import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.ActivityRecording;
import Toybox.Position;

using InterfaceComponentsManager as ICM;

class SpikeballApp extends Application.AppBase {

    public var timer as TimerController;
    public var fieldsSettings as Dictionary;
    public var sensorsSettings as Dictionary;

    function initialize() {
        AppBase.initialize();

        self.timer = new TimerController(1000);

        self.fieldsSettings = Storage.getValue("fieldsSettings");
        if (fieldsSettings == null) {
            self.fieldsSettings = WatchUi.loadResource(Rez.JsonData.DefaultDatafieldsSettings);
        }

        self.sensorsSettings = Storage.getValue("sensorsSettings");
        if (sensorsSettings == null) {
            self.sensorsSettings = WatchUi.loadResource(Rez.JsonData.DefaultSensorsSettings);
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
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        Storage.setValue("fieldsSettings", fieldsSettings);
        Storage.setValue("sensorsSettings", sensorsSettings);
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var delegate = new StartDelegate(); 
        return [new StartView(delegate.method(:registerUpdates)), delegate];
    }

    public function getLocationSetting() as Position.LocationAcquisitionType {
        return sensorsSettings.get("location") as Boolean ? Position.LOCATION_CONTINUOUS : Position.LOCATION_DISABLE;
    }
}

function getApp() as SpikeballApp {
    return Application.getApp() as SpikeballApp;
}