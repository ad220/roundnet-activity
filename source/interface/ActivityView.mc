import Toybox.Graphics;
import Toybox.WatchUi;

using InterfaceComponentsManager as ICM;

class SpikeballActivityView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.ScoreLayout(dc));
    }

    function onShow() as Void {
    }

    // Update the view*
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ICM.scaleX(0.219), ICM.scaleY(0.50), ICM.fontLarge, "21", ICM.JTEXT_MID);
        dc.drawText(ICM.scaleY(0.295), ICM.scaleY(0.816), ICM.fontLarge, "21", ICM.JTEXT_MID);
        dc.drawText(ICM.scaleX(0.574), ICM.scaleY(0.185), ICM.fontMedium, "1:42:09", ICM.JTEXT_MID);
        dc.drawText(ICM.scaleX(0.718), ICM.scaleY(0.816), ICM.fontMedium, "134", ICM.JTEXT_MID);

    }

    function onHide() as Void {
    }

}
