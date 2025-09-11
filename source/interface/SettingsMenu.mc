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
        if (id==:datafields) {
            var menu = new Rez.Menus.DatafieldsMenu();
            var settings = getApp().fieldsSettings;
            WatchUi.pushView(menu, new SubDatafieldsDelegate(menu, settings), SLIDE_LEFT);
        } else {
            var menu = new Rez.Menus.SensorsMenu();
            var settings = getApp().sensorsSettings;
            WatchUi.pushView(menu, new SubSensorsDelegate(menu, settings), SLIDE_LEFT);
        }
    }

    public function onBack() as Void {
        Menu2InputDelegate.onBack();

        var delegate = WatchUi.getCurrentView()[1];
        if (delegate instanceof StartDelegate) {
            delegate.registerUpdates();
        }
    }
}


class SubSettingsDelegate extends WatchUi.Menu2InputDelegate {

    public static const itemIdMap;
    
    private var settings as Dictionary;

    public function initialize(menu as Menu2, settings as Dictionary) {
        Menu2InputDelegate.initialize();
        
        self.settings = settings;

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
        }
    }
}

class SubDatafieldsDelegate extends SubSettingsDelegate {
    protected static const itemIdMap = {
        :distance       => "distance",
        :calories       => "calories",
        :score          => "score",
        :temperature    => "temperature",
        :daytime        => "daytime",
    };

    public function initialize(menu as Menu2, settings as Dictionary) {
        SubSettingsDelegate.initialize(menu, settings);
    }
}

class SubSensorsDelegate extends SubSettingsDelegate {
    protected static const itemIdMap = {
        :temperature    => "temperature",
        :location       => "location",
    };

    public function initialize(menu as Menu2, settings as Dictionary) {
        SubSettingsDelegate.initialize(menu, settings);
    }
}