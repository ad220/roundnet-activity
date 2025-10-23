import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;


class StopDelegate extends WatchUi.Menu2InputDelegate {

    private var activity as RoundnetActivity;

    public function initialize(activity as RoundnetActivity) {
        Menu2InputDelegate.initialize();

        self.activity = activity;
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        if (id==:resume) {
            activity.resume();
            var view = new RoundnetActivityView(activity);
            var delegate = new RoundnetActivityDelegate(view, activity);
            activity.registerDelegate(delegate);
            WatchUi.switchToView(view, delegate, SLIDE_DOWN);
        } else {
            if (id==:save) {
                activity.save();
            } else {
                activity.discard();
            }
            WatchUi.popView(SLIDE_DOWN);
        }
    }

    public function onBack() as Void {
    }
}