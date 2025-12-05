import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;


module InterfaceComponentsManager {
    
    var screenH as Number?;
    var screenW as Number?;

    var fontSmall as FontResource?;
    var fontMedium as FontResource?;
    var fontLarge as FontResource?;
    
    const JTEXT_MID = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    const JTEXT_LEFT = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;


    function computeInterfaceConstants() {
        var deviceSettings = System.getDeviceSettings();
        screenH = deviceSettings.screenHeight;
        screenW = deviceSettings.screenWidth;
    }

    function scaleX(xPercent as Float) as Number {
        return (xPercent*screenW as Float).toNumber();
    }

    function scaleY(yPercent as Float) as Number {
        return (yPercent*screenH as Float).toNumber();
    }

    function loadFonts() as Void{
        fontSmall = WatchUi.loadResource(Rez.Fonts.Small);
        fontMedium = WatchUi.loadResource(Rez.Fonts.Medium);
        fontLarge = WatchUi.loadResource(Rez.Fonts.Large);
    }

    function unloadFonts() as Void {
        fontSmall = null;
        fontMedium = null;
        fontLarge = null;
    }

    function toggleAA(dc as Dc, state as Boolean) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(state);
        }
    }
}
