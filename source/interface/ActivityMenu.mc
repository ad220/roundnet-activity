import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;


class ActivityMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var activity as RoundnetActivity;

    public function initialize(activity as RoundnetActivity) {
        Menu2InputDelegate.initialize();

        self.activity = activity;
    }

    public function onSelect(item as MenuItem) as Void {
        
    }
}