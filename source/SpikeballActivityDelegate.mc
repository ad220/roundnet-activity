import Toybox.Lang;
import Toybox.WatchUi;

class SpikeballActivityDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        // WatchUi.pushView(new Rez.Menus.MainMenu(), new SpikeballActivityMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}