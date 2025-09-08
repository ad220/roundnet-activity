import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.ActivityRecording;

using InterfaceComponentsManager as ICM;

class SpikeballApp extends Application.AppBase {

    private var activity as SpikeballActivity;
    private var timer as TimerController;

    function initialize() {
        AppBase.initialize();

        self.activity = new SpikeballActivity();
        self.timer = new TimerController();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        ICM.loadFonts();
        ICM.computeInterfaceConstants();
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new SpikeballActivityView(activity), new SpikeballActivityDelegate(activity, timer) ];
    }

}

function getApp() as SpikeballApp {
    return Application.getApp() as SpikeballApp;
}