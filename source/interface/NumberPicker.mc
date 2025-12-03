import Toybox.Lang;
import Toybox.WatchUi;


class NumberPickerDelegate extends SettingsDelegate {
    public function initialize(
        key as String,
        callback as Method(label as String or ResourceId or Null) as Void,
        menu as Menu2,
        min as Number,
        max as Number,
        selected as Number
    ) {
        SettingsDelegate.initialize(menu, key, callback);

        for (var i=min; i<=max; i++) {
            menu.addItem(new MenuItem(i.toString(), null, i, {:alignement => MenuItem.MENU_ITEM_LABEL_ALIGN_RIGHT}));
        }
        menu.setFocus(selected-min);
    }

    public function onSelect(item as MenuItem) as Void {
        getApp().settings.put(key, item.getId());
        callback.invoke(item.getLabel());
        popView(SLIDE_RIGHT);
    }
}