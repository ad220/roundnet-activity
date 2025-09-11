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
            WatchUi.pushView(menu, new SubDatafieldsDelegate(menu), SLIDE_LEFT);
        } else {
            var menu = new Rez.Menus.SensorsMenu();
            WatchUi.pushView(menu, new SubSensorsDelegate(menu), SLIDE_LEFT);
        }
    }
}


class SubSettingsDelegate extends WatchUi.Menu2InputDelegate {

    public static const subMenuId;
    public static const defaultsRezId;
    public static const itemIdMap;

    private var settings as Dictionary;

    public function initialize(menu as Menu2) {
        Menu2InputDelegate.initialize();
        
        settings = Application.Storage.getValue(subMenuId);
        if (settings == null) {
            settings = WatchUi.loadResource(defaultsRezId);
            syncSettings();
        }

        for (var i=0; i<itemIdMap.size(); i++) {
            var item = menu.getItem(i);
            if (item instanceof ToggleMenuItem) {
                var id = itemIdMap.get(item.getId());
                if (id instanceof String) {
                    System.println(id);
                    System.println(settings);
                    item.setEnabled(settings.get(id) as Boolean);
                }
            }
        }
    }

    private function syncSettings() {
        Application.Storage.setValue(subMenuId, settings);
    }

    public function onSelect(item as MenuItem) as Void {
        if (item instanceof WatchUi.ToggleMenuItem) {
            var id = itemIdMap.get(item.getId());
            if (id instanceof String) {
                settings.put(id, item.isEnabled());
                syncSettings();
            } else {
                System.println("Unknown "+subMenuId+" item");
            }
        }
    }
}

class SubDatafieldsDelegate extends SubSettingsDelegate {
    protected static const subMenuId = "datafieldsSettings";
    protected static const defaultsRezId = Rez.JsonData.DefaultDatafieldsSettings;
    protected static const itemIdMap = {
        :distance       => "distance",
        :calories       => "calories",
        :score          => "score",
        :temperature    => "temperature",
        :daytime        => "daytime",
    };

    public function initialize(menu as Menu2) {
        SubSettingsDelegate.initialize(menu);
    }
}

class SubSensorsDelegate extends SubSettingsDelegate {
    protected static const subMenuId = "sensorsSettings";
    protected static const defaultsRezId = Rez.JsonData.DefaultSensorsSettings;
    protected static const itemIdMap = {
        :temperature    => "temperature",
        :location       => "location",
    };

    public function initialize(menu as Menu2) {
        SubSettingsDelegate.initialize(menu);
    }
}