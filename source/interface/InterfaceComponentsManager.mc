import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;


module InterfaceComponentsManager {

    (:initialized) var screenH as Number;
    (:initialized) var screenW as Number;

    const fontSmall     as FontResource = WatchUi.loadResource(Rez.Fonts.Small)  as FontResource;
    const fontMedium    as FontResource = WatchUi.loadResource(Rez.Fonts.Medium) as FontResource;
    const fontLarge     as FontResource = WatchUi.loadResource(Rez.Fonts.Large)  as FontResource;

    const JTEXT_MID = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    const JTEXT_LEFT = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

    function toggleAA(dc as Dc, state as Boolean) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(state);
        }
    }
}
