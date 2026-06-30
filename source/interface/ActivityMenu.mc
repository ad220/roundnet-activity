import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

(:notva3)
class ActivityMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var activity    as RoundnetActivity;
    private var menu        as Menu2;

    public function initialize(menu as Rez.Menus.ActivityMenu, activity as RoundnetActivity) {
        Menu2InputDelegate.initialize();

        self.activity       = activity;
        self.menu           = menu;

        onWarmup(false);
        onObserver(false);
    }

    public function onSelect(item as MenuItem) as Void {
        method(item.getId() as Symbol).invoke(true);
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

    public function onTimers(selected as Boolean) as Void {
        menu = new Rez.Menus.TimersMenu();
        switchToView(menu, self, SLIDE_IMMEDIATE);
    }

    public function onWarmup(selected as Boolean) as Void {
        if (selected) { activity.toggleWarmup(); }
        var isWarmup = activity.isWarmup();
       
        if (selected or isWarmup) {
            var warmupItem = menu.getItem(1) as IconMenuItem;

            warmupItem.setLabel(isWarmup ? Rez.Strings.SetGame : Rez.Strings.SetWarmup);

            var bmp = new Bitmap({
                :rezId  => isWarmup ? Rez.Drawables.Trophy : Rez.Drawables.Warmup,
                :locX   => LAYOUT_HALIGN_CENTER,
                :locY   => LAYOUT_VALIGN_CENTER
            });
            warmupItem.setIcon(bmp);
        }
    }

    public function onObserver(selected as Boolean) as Void {
        var settings = getApp().settings;
        var isObsMode = settings["observer_mode"] as Boolean;

        if (selected) {
            settings["observer_mode"] = !isObsMode;
            isObsMode = !isObsMode;
        }

        if (selected or isObsMode) {
            var obsItem = menu.getItem(2) as IconMenuItem;

            obsItem.setLabel(isObsMode ? Rez.Strings.SetPlayer : Rez.Strings.SetObserver);

            var bmp = new Bitmap({
                :rezId  => isObsMode ? Rez.Drawables.Player : Rez.Drawables.Observer,
                :locX   => LAYOUT_HALIGN_CENTER,
                :locY   => LAYOUT_VALIGN_CENTER
            });
            obsItem.setIcon(bmp);
        }
    }

    public function onSettings(selected as Boolean) as Void {
        var nmenu = new Rez.Menus.SettingsMenu();
        pushView(nmenu, new SettingsDelegate(nmenu, null, null), SLIDE_LEFT);
    }

    public function onTimeout(selected as Boolean) as Void {
        var dlgt = new TimerDelegate(activity, getApp().timer, 60);
        switchToView(new TimerView(dlgt, :TimerLayout, Rez.Drawables.Timeout, null), dlgt, SLIDE_IMMEDIATE); 
    }

    public function onSet(selected as Boolean) as Void {
        var dlgt = new TimerDelegate(activity, getApp().timer, 180);
        switchToView(new TimerView(dlgt, :TimerLayout, Rez.Drawables.Bottle, null), dlgt, SLIDE_IMMEDIATE); 
    }

    public function onInjury(selected as Boolean) as Void {
        var dlgt = new TimerDelegate(activity, getApp().timer, 300);
        switchToView(new TimerView(dlgt, :TimerLayout, Rez.Drawables.Injury, null), dlgt, SLIDE_IMMEDIATE); 
    }

}
