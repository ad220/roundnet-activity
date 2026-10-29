import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class StopMenuView extends Rez.Menus.StopMenu {

    private var dlgt as StopDelegate;

    public function initialize(dlgt as StopDelegate) {
        StopMenu.initialize();

        self.dlgt = dlgt;
    }

    public function onUpdate(dc as $.Toybox.Graphics.Dc) as Void {
        System.println("StopMenuView: onUpdate");
    }

    public function onShow() as Void {
        dlgt.onShow();
    }

    public function onHide() as Void {
        dlgt.onHide();
    }
}


class StopDelegate extends WatchUi.Menu2InputDelegate {

    private var activity as RoundnetActivity;
    private var itemSelected as Boolean;
    private var restoreActivity as Boolean;

    public function initialize(activity as RoundnetActivity) {
        Menu2InputDelegate.initialize();

        self.activity = activity;
        self.itemSelected = false;
        self.restoreActivity = false;
    }

    public function onSelect(item as MenuItem) as Void {
        itemSelected = true;
        var id = item.getId();
        if (id==:resume) {
            activity.resume();
            var view = new RoundnetActivityView(activity);
            var delegate = new RoundnetActivityDelegate(view, activity);
            activity.registerDelegate(delegate);
            switchToView(view, delegate, SLIDE_DOWN);
        } else {
            if (id==:save) {
                activity.save();
            } else {
                activity.discard();
            }
            popView(SLIDE_DOWN);
        }
    }

    public function onBack() as Void {
    }

    public function onShow() as Void {
        System.println("StopMenu: onShow");
        if (restoreActivity) {
            activity.restoreSession();
            onSelect(new MenuItem("", null, :resume, null));
        } 
    } 

    public function onHide() as Void {
        System.println("StopMenu: onHide");
        if (!itemSelected) { restoreActivity = true; }
    }
}