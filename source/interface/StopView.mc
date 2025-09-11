import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;


class StopDelegate extends WatchUi.Menu2InputDelegate {

    private var activity as SpikeballActivity;
    private var timer as TimerController;

    public function initialize(activity as SpikeballActivity, timer as TimerController) {
        Menu2InputDelegate.initialize();

        self.activity = activity;
        self.timer = timer;
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        System.println(id);
        if (id==:resume) {
            activity.resume();
            WatchUi.switchToView(new SpikeballActivityView(activity), new SpikeballActivityDelegate(activity, timer), SLIDE_DOWN);
        } else if (id==:save) {
            activity.save();
            WatchUi.popView(SLIDE_DOWN);
        } else {
            activity.discard();
            WatchUi.popView(SLIDE_DOWN);
        }
    }
}