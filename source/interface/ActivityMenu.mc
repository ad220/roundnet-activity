import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

(:notva3)
class ActivityMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var activity as RoundnetActivity;
    private var menu as Menu2;
    private var modeCachedItem as IconMenuItem;

    public function initialize(menu as Rez.Menus.ActivityMenu, activity as RoundnetActivity) {
        Menu2InputDelegate.initialize();

        self.activity = activity;
        self.menu = menu;
        self.modeCachedItem = menu.getItem(3) as IconMenuItem;

        menu.deleteItem(3);

        if (getApp().settings["observer_mode"] as Boolean) {
            updateObserver();
        }
    }

    public function onSelect(item as MenuItem) as Void {
        method(item.getId() as Symbol).invoke();
    }

    public function onBack() as Void {
        if (menu instanceof Rez.Menus.ActivityMenu){
            var view = new RoundnetActivityView(activity);
            var delegate = new RoundnetActivityDelegate(view, activity);
            activity.registerDelegate(delegate);
            switchToView(view, delegate, SLIDE_DOWN);
        }
        else {
            initialize(new Rez.Menus.ActivityMenu(), activity);
            switchToView(menu, self, SLIDE_RIGHT);
        }
    }


    public function onTimers() as Void {
        menu = new Rez.Menus.TimersMenu();
        switchToView(menu, self, SLIDE_IMMEDIATE);
    }

    public function onObserver() as Void {
        var settings = getApp().settings;
        settings["observer_mode"] = !(settings["observer_mode"] as Boolean);
        updateObserver();
    }

    private function updateObserver() as Void {
        var cache = menu.getItem(1) as IconMenuItem;
        menu.updateItem(modeCachedItem, 1);
        modeCachedItem = cache;
    }


    public function onSettings() as Void {
        var nmenu = new Rez.Menus.SettingsMenu();
        pushView(nmenu, new SettingsDelegate(nmenu, null, null), SLIDE_LEFT);
    }

    public function onTimeout() as Void {
        var dlgt = new TimerDelegate(activity, getApp().timer, 60);
        switchToView(new TimerView(dlgt, :TimerLayout, Rez.Drawables.Timeout, null), dlgt, SLIDE_IMMEDIATE); 
    }

    public function onSet() as Void {
        var dlgt = new TimerDelegate(activity, getApp().timer, 180);
        switchToView(new TimerView(dlgt, :TimerLayout, Rez.Drawables.Bottle, null), dlgt, SLIDE_IMMEDIATE); 
    }

    public function onInjury() as Void {
        var dlgt = new TimerDelegate(activity, getApp().timer, 300);
        switchToView(new TimerView(dlgt, :TimerLayout, Rez.Drawables.Injury, null), dlgt, SLIDE_IMMEDIATE); 
    }

}
