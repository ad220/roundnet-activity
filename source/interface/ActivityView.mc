import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;

using InterfaceComponentsManager as ICM;

class RoundnetActivityView extends WatchUi.View {

    private var activity as RoundnetActivity;
    private var loopField as WatchUi.Drawable;

    function initialize(activity as RoundnetActivity) {
        View.initialize();

        self.activity = activity;
        self.loopField = new LoopField(activity);
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.ActivityLayout(dc));
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ICM.scaleX(0.219), ICM.scaleY(0.500), ICM.fontLarge, activity.getScore(RoundnetActivity.TEAM_OPPONENT), ICM.JTEXT_MID);
        dc.drawText(ICM.scaleY(0.295), ICM.scaleY(0.816), ICM.fontLarge, activity.getScore(RoundnetActivity.TEAM_PLAYER), ICM.JTEXT_MID);
        dc.drawText(ICM.scaleX(0.460), ICM.scaleY(0.185), ICM.fontMedium, activity.getFormattedTime(), ICM.JTEXT_LEFT);

        var hr = activity.getHR();
        dc.drawText(ICM.scaleX(0.650), ICM.scaleY(0.816), ICM.fontMedium, hr!=null ? hr : "- -", ICM.JTEXT_LEFT);

        dc.setClip(ICM.scaleX(0.333), ICM.scaleY(0.333), ICM.scaleX(0.667), ICM.scaleY(0.333));
        loopField.draw(dc);
        dc.clearClip();
    }

    function onHide() as Void {
    }

}

class RoundnetActivityDelegate extends BehaviorDelegate {

    private var activity as RoundnetActivity;


    public function initialize(activity as RoundnetActivity) {
        BehaviorDelegate.initialize();

        self.activity = activity;
    }

    public function onSelect() as Boolean {
        activity.stop();
        var menu = new Rez.Menus.StopMenu();
        menu.setTitle(activity.getFormattedTime());
        WatchUi.switchToView(menu, new StopDelegate(activity), WatchUi.SLIDE_UP);
        return true;
    }

    public function onPreviousPage() as Boolean {
        activity.addScore(RoundnetActivity.TEAM_OPPONENT);
        return true;
    }

    public function onNextPage() as Boolean {
        activity.addScore(RoundnetActivity.TEAM_PLAYER);
        return true;
    }

    public function onBack() as Boolean {
        if (activity.isRecording()) {
            activity.lap();
        } else {
            WatchUi.popView(SLIDE_LEFT);
        }
        return true;
    }

    public function onMenu() as Boolean {
        activity.save();
        return true;
    }
}
