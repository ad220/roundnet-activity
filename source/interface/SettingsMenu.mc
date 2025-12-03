import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Application;


class SettingsDelegate extends WatchUi.Menu2InputDelegate {

    private var menu as Menu2;
    protected var key as String?;
    protected var callback as Method(label as String or ResourceId or Null)?;

    public function initialize(menu as Menu2, key as String?, callback as Method(label as String or ResourceId or Null)?) {
        Menu2InputDelegate.initialize();

        self.menu = menu;
        self.key = key;
        self.callback = callback;

        var settings = getApp().settings;
        var i = 0; 
        var item = menu.getItem(i);
        while (item != null) {
            if (item instanceof ToggleMenuItem) {
                var id = item.getSubLabel();
                item.initialize(item.getLabel(), null, id, settings.get(id) as Boolean, null);
                menu.updateItem(item, i);
            } else {
                var sublabel = item.getSubLabel();
                if (sublabel != null) {
                    var id = item.getId();
                    if (id == :_) {
                        item.initialize(item.getLabel(), null, sublabel.toNumber(), null);
                    } else {
                        item.initialize(item.getLabel(), settings.get(sublabel).toString(), [item.getId(), sublabel], null);
                    }
                    menu.updateItem(item, i);
                }
            }
            i++;
            item = menu.getItem(i);
        }
    }

    public function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        if (callback != null) {
            callback.invoke(item.getLabel());
        }

        if (id instanceof Symbol) {
            if (self has id) { self.method(id).invoke(item); }
        } else if (id instanceof Array) {
            if (self has id[0]) { self.method(id[0]).invoke(item); }
        } else if (item instanceof ToggleMenuItem) {
            getApp().settings.put(item.getId() as String, item.isEnabled());
        } else {
            getApp().settings.put(key, item.getId());
            onBack();
        }
    }

    public function onBack() as Void {
        popView(SLIDE_RIGHT);
    }

    public function createSensorsMenu(item as MenuItem) as Void {
        var menu = new Rez.Menus.SensorsMenu();
        pushView(menu, new SettingsDelegate(menu, null, null), SLIDE_LEFT);
    }
    
    public function createDatafieldMenu(item as MenuItem) as Void {
        var menu = new Rez.Menus.DatafieldMenu();
        pushView(menu, new SettingsDelegate(menu, null, null), SLIDE_LEFT);
    }
    
    public function createGameMenu(item as MenuItem) as Void {
        var menu = new Rez.Menus.GameMenu();
        pushView(menu, new SettingsDelegate(menu, null, null), SLIDE_LEFT);
    }

    public function createSpeedMenu(item as MenuItem) as Void {
        var menu = new Rez.Menus.SpeedMenu();
        var callback = item.method(:setSubLabel);
        var key = (item.getId() as Array)[1];
        var delegate = new SettingsDelegate(menu, key, callback);
        menu.setTitle(item.getLabel());
        menu.setFocus(getApp().settings.get(key) as Number - 2);
        pushView(menu, delegate, SLIDE_LEFT);
    }

    public function createFieldsMenu(item as MenuItem) as Void {
        var menu = new Rez.Menus.FieldsMenu();
        pushView(menu, new SettingsDelegate(menu, null, null), SLIDE_LEFT);
    }
    
    public function createScrollingMenu(item as MenuItem) as Void {
        var menu = new Rez.Menus.ScrollingMenu();
        pushView(menu, new SettingsDelegate(menu, null, null), SLIDE_LEFT);
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
        var delegate = new NumberPickerDelegate(key, callback, menu, min, max, getApp().settings.get(key) as Number);
        menu.setTitle(item.getLabel());
        pushView(menu, delegate, SLIDE_LEFT);
    }
}
