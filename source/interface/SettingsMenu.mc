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
            WatchUi.pushView(menu, new SubSensorsDelegate(menu), SLIDE_LEFT);
        } else if (id==:datafield) {
            var menu = new Rez.Menus.DatafieldMenu();
            WatchUi.pushView(menu, self, SLIDE_LEFT);
        } else if (id==:doubleclick) {
            var menu = new Rez.Menus.SpeedMenu();
            var callback = item.method(:setSubLabel);
            var delegate = new SpeedPickerDelegate("doubleclickspeed", callback);
            menu.setTitle(item.getLabel());
            menu.setFocus(getApp().settings.get("doubleclickspeed") as Number - 2);
            WatchUi.pushView(menu, delegate, SLIDE_LEFT);
        } else if (id==:fields) {
            var menu = new Rez.Menus.FieldsMenu();
            WatchUi.pushView(menu, new SubDatafieldsDelegate(menu), SLIDE_LEFT);
        } else if (id==:scrolling) {
            var menu = new Rez.Menus.ScrollingMenu();
            WatchUi.pushView(menu, new SubScrollingDelegate(menu), SLIDE_LEFT);
        }
    }
}


class SubSettingsDelegate extends WatchUi.Menu2InputDelegate {

    public static const itemIdMap;
    
    private var settings as Dictionary;

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
            var id = item.getId();
            if (id==:scrollspeed) {
                var menu = new Rez.Menus.SpeedMenu();
                var callback = item.method(:setSubLabel);
                var delegate = new SpeedPickerDelegate("scrollspeed", callback);
                menu.setTitle(item.getLabel());
                menu.setFocus(settings.get("scrollspeed") as Number - 2);
                WatchUi.pushView(menu, delegate, SLIDE_LEFT);
            }
        }
    }
}

class SubDatafieldsDelegate extends SubSettingsDelegate {
    protected static const itemIdMap = {
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
    protected static const itemIdMap = {
        :temperature    => "sensor_temperature",
        :location       => "sensor_location",
    };

    public function initialize(menu as Menu2) {
        SubSettingsDelegate.initialize(menu);
    }
}

class SubScrollingDelegate extends SubSettingsDelegate {
    protected static const itemIdMap = {
        :autoscroll     => "autoscroll",
        :scrollspeed    => "scrollspeed",
        :swipescroll    => "swipescroll",
    };

    public function initialize(menu as Menu2) {
        SubSettingsDelegate.initialize(menu);
    }
}


class PickerDelegate extends Menu2InputDelegate {

    public static const itemIdMap;
    
    private var settings as Dictionary;
    private var key as Object;
    private var selectCallback as Method(label as String or ResourceId or Null) as Void;

    public function initialize(key as Object, selectCallback as Method(label as String or ResourceId or Null) as Void) {
        Menu2InputDelegate.initialize();
        
        self.settings = getApp().settings;
        self.key = key;
        self.selectCallback = selectCallback;
    }

    public function onSelect(item as MenuItem) as Void {
        if (item instanceof WatchUi.MenuItem) {
            var value = itemIdMap.get(item.getId());
            if (value!=null) {
                settings.put(key, value);
                selectCallback.invoke(item.getLabel());
                WatchUi.popView(SLIDE_RIGHT);
            }
        }
    }
}

class SpeedPickerDelegate extends PickerDelegate {
    protected static const itemIdMap = {
        :vfast => 2,
        :fast => 3,
        :normal => 4,
        :slow => 5,
        :vslow => 7,
    };

    public function initialize(key as Object, selectCallback as Method(label as String or ResourceId or Null) as Void) {
        PickerDelegate.initialize(key, selectCallback);
    }
}
