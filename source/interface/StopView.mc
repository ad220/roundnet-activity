import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;


class StopDelegate extends WatchUi.Menu2InputDelegate {

    private var activity as SpikeballActivity;

    public function initialize(activity as SpikeballActivity) {
        Menu2InputDelegate.initialize();

        self.activity = activity;
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        System.println(id);
        if (id==:resume) {
            activity.resume();
            WatchUi.switchToView(new SpikeballActivityView(activity), new SpikeballActivityDelegate(activity), SLIDE_DOWN);
        } else {
            if (id==:save) {
                activity.save();
            } else {
                activity.discard();
            }
            WatchUi.popView(SLIDE_DOWN);
            var delegate = WatchUi.getCurrentView()[1];
            if (delegate instanceof StartDelegate) {
                delegate.registerUpdates();
            }
        }
    }
}