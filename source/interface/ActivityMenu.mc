import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

(:notva3)
class ActivityMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var activity as RoundnetActivity;
    private var menu as Rez.Menus.ActivityMenu;
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

    public function onTimers() as Void {
        pushView(new Rez.Menus.TimersMenu(), null, SLIDE_IMMEDIATE);
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
        var menu = new Rez.Menus.SettingsMenu();
        pushView(menu, new SettingsDelegate(menu, null, null), SLIDE_IMMEDIATE);
    }

    public function onBack() as Void {
        var view = new RoundnetActivityView(activity);
        var delegate = new RoundnetActivityDelegate(view, activity);
        activity.registerDelegate(delegate);
        WatchUi.switchToView(view, delegate, SLIDE_DOWN);
    }
}