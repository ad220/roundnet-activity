import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

using InterfaceComponentsManager as ICM;

class SpikeballApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
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
        return [ new SpikeballActivityView(), new SpikeballActivityDelegate() ];
    }

}

function getApp() as SpikeballApp {
    return Application.getApp() as SpikeballApp;
}