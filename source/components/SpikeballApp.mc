import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.ActivityRecording;
import Toybox.Position;

using InterfaceComponentsManager as ICM;

class SpikeballApp extends Application.AppBase {

    private var timer as TimerController;

    function initialize() {
        AppBase.initialize();

        self.timer = new TimerController();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        ICM.loadFonts();
        ICM.computeInterfaceConstants();
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, null);
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new StartView(), new StartDelegate(timer)];
    }

}

function getApp() as SpikeballApp {
    return Application.getApp() as SpikeballApp;
}