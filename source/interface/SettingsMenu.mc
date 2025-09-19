import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Application;


class SettingsDelegate extends WatchUi.Menu2InputDelegate {

    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        if (id==:sensors){
            var menu = new Rez.Menus.SensorsMenu();
            pushView(menu, new SubSensorsDelegate(menu), SLIDE_LEFT);
        } else if (id==:datafield) {
            var menu = new Rez.Menus.DatafieldMenu();
            pushView(menu, self, SLIDE_LEFT);
        } else if (id==:game) {
            var menu = new Rez.Menus.GameMenu();
            pushView(menu, new SubGameDelegate(menu), SLIDE_LEFT);
        } else if (id==:doubleclick) {
            var menu = new Rez.Menus.SpeedMenu();
            var callback = item.method(:setSubLabel);
            var delegate = new SpeedPickerDelegate("doubleclickspeed", callback);
            menu.setTitle(item.getLabel());
            menu.setFocus(getApp().settings.get("doubleclickspeed") as Number - 2);
            pushView(menu, delegate, SLIDE_LEFT);
        } else if (id==:fields) {
            var menu = new Rez.Menus.FieldsMenu();
            pushView(menu, new SubDatafieldsDelegate(menu), SLIDE_LEFT);
        } else if (id==:scrolling) {
            var menu = new Rez.Menus.ScrollingMenu();
            pushView(menu, new SubScrollingDelegate(menu), SLIDE_LEFT);
        }
    }
}


class SubSettingsDelegate extends WatchUi.Menu2InputDelegate {

    public const itemIdMap;
    
    protected var settings as Dictionary;

    public function initialize(menu as Menu2) {
        Menu2InputDelegate.initialize();
        
        self.settings = getApp().settings;

        for (var i=0; i<itemIdMap.size(); i++) {
            var item = menu.getItem(i);
            if (item instanceof ToggleMenuItem) {
                var id = itemIdMap.get(item.getId());
                if (id instanceof String) {
                    item.setEnabled(settings.get(id) as Boolean);
                }
            } else {
                var array = itemIdMap.get(item.getId());
                if (array instanceof Array and array.size()>0) {
                    item.setSubLabel(settings.get(array[0]).toString());
                }
            }
        }
    }

    public function onSelect(item as MenuItem) as Void {
        if (item instanceof WatchUi.ToggleMenuItem) {
            var id = itemIdMap.get(item.getId());
            if (id instanceof String) {
                settings.put(id, item.isEnabled());
            } else {
                System.println("Unknown menu item");
            }
        } else if (item instanceof MenuItem) {
            var array = itemIdMap.get(item.getId());
            if (array instanceof Array and array.size()>0) {
                (array[1] as Method).invoke(item);
            } else {
                System.println("Unknown menu item");
            }
        }
    }
}

class SubDatafieldsDelegate extends SubSettingsDelegate {
    protected const itemIdMap = {
        :distance       => "field_distance",
        :calories       => "field_calories",
        :score          => "field_score",
        :temperature    => "field_temperature",
        :daytime        => "field_daytime",
    };

    public function initialize(menu as Menu2) {
        SubSettingsDelegate.initialize(menu);
    }
}

class SubSensorsDelegate extends SubSettingsDelegate {
    protected const itemIdMap = {
        :temperature    => "sensor_temperature",
        :location       => "sensor_location",
    };

    public function initialize(menu as Menu2) {
        SubSettingsDelegate.initialize(menu);
    }
}

class SubScrollingDelegate extends SubSettingsDelegate {
    protected const itemIdMap = {
        :autoscroll     => "autoscroll",
        :scrollspeed    => ["scrollspeed", method(:createSpeedMenu)],
        :swipescroll    => "swipescroll",
    };

    public function initialize(menu as Menu2) {
        SubSettingsDelegate.initialize(menu);
    }

    public function createSpeedMenu(item as MenuItem) as Void{
        var menu = new Rez.Menus.SpeedMenu();
        var callback = item.method(:setSubLabel);
        var delegate = new SpeedPickerDelegate("scrollspeed", callback);
        menu.setTitle(item.getLabel());
        menu.setFocus(settings.get("scrollspeed") as Number - 2);
        pushView(menu, delegate, SLIDE_LEFT);
    }
}

class SubGameDelegate extends SubSettingsDelegate {
    protected const itemIdMap = {
        :game_win_auto          => "game_win_auto",
        :game_win_two_pt_diff   => "game_win_two_pt_diff",
        :game_win_points        => ["game_win_points", method(:createWinPointsMenu)],
        :game_win_retry         => "game_win_retry",
        :game_switch_alarm      => "game_switch_alarm",
        :game_switch_points     => ["game_switch_points", method(:createSwitchPointsMenu)],
    };

    public function initialize(menu as Menu2) {
        SubSettingsDelegate.initialize(menu);
    }

    public function createWinPointsMenu(item as MenuItem) as Void {
        createPointsMenu(item, "game_win_points", 5, 51);
    }

    public function createSwitchPointsMenu(item as MenuItem) as Void {
        createPointsMenu(item, "game_switch_points", 3, 10);
    }

    private function createPointsMenu(item as MenuItem, key as String, min as Number, max as Number) as Void {
        var menu = new Menu2(null);
        var callback = item.method(:setSubLabel);
        var delegate = new NumberPickerDelegate(key, callback, menu, min, max, settings.get(key) as Number);
        menu.setTitle(item.getLabel());
        pushView(menu, delegate, SLIDE_LEFT);
    }
}


class SettingPickerDelegate extends Menu2InputDelegate {

    public static const itemIdMap;
    
    protected var settings as Dictionary;
    protected var key as Object;
    protected var selectCallback as Method(label as String or ResourceId or Null) as Void;

    public function initialize(key as Object, selectCallback as Method(label as String or ResourceId or Null) as Void) {
        Menu2InputDelegate.initialize();
        
        self.settings = getApp().settings;
        self.key = key;
        self.selectCallback = selectCallback;
    }

    public function onSelect(item as MenuItem) as Void {
        var value = itemIdMap.get(item.getId());
        if (value!=null) {
            settings.put(key, value);
            selectCallback.invoke(item.getLabel());
            popView(SLIDE_RIGHT);
        }
    }
}

class SpeedPickerDelegate extends SettingPickerDelegate {
    protected static const itemIdMap = {
        :vfast => 2,
        :fast => 3,
        :normal => 4,
        :slow => 5,
        :vslow => 7,
    };

    public function initialize(key as Object, selectCallback as Method(label as String or ResourceId or Null) as Void) {
        SettingPickerDelegate.initialize(key, selectCallback);
    }
}

class NumberPickerDelegate extends SettingPickerDelegate {
    public function initialize(
        key as Object,
        selectCallback as Method(label as String or ResourceId or Null) as Void,
        menu as Menu2,
        min as Number,
        max as Number,
        selected as Number
    ) {
        SettingPickerDelegate.initialize(key, selectCallback);

        for (var i=min; i<=max; i++) {
            menu.addItem(new MenuItem(i.toString(), null, i, {:alignement => MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT}));
        }
        menu.setFocus(selected-min);
    }

    public function onSelect(item as MenuItem) as Void {
        settings.put(key, item.getId());
        selectCallback.invoke(item.getLabel());
        popView(SLIDE_RIGHT);
    }
}
