import Toybox.Graphics;
import Toybox.WatchUi;

using InterfaceComponentsManager as ICM;

class SpikeballActivityView extends WatchUi.View {

    private var activity as SpikeballActivity;
    private var loopField as WatchUi.Drawable;

    function initialize(activity as SpikeballActivity, timer as TimerController) {
        View.initialize();

        self.activity = activity;
        self.loopField = new LoopField(activity);
        timer.start(loopField.method(:nextField), 10, true);
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.ScoreLayout(dc));
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(ICM.scaleX(0.219), ICM.scaleY(0.500), ICM.fontLarge, activity.getScore(SpikeballActivity.TEAM_GREY), ICM.JTEXT_MID);
        dc.drawText(ICM.scaleY(0.295), ICM.scaleY(0.816), ICM.fontLarge, activity.getScore(SpikeballActivity.TEAM_YELLOW), ICM.JTEXT_MID);
        dc.drawText(ICM.scaleX(0.475), ICM.scaleY(0.185), ICM.fontMedium, activity.getFormattedTime(), ICM.JTEXT_LEFT);

        var hr = activity.getHR();
        dc.drawText(ICM.scaleX(0.650), ICM.scaleY(0.816), ICM.fontMedium, hr!=null ? hr : "- -", ICM.JTEXT_LEFT);

        dc.setClip(ICM.scaleX(0.333), ICM.scaleY(0.333), ICM.scaleX(0.667), ICM.scaleY(0.333));
        loopField.draw(dc);
        dc.clearClip();

    }

    function onHide() as Void {
    }

}

class SpikeballActivityDelegate extends BehaviorDelegate {

    private var activity as SpikeballActivity;


    public function initialize(activity as SpikeballActivity, timer as TimerController) {
        BehaviorDelegate.initialize();

        self.activity = activity;
        timer.start(method(:updateView), 2, true);
    }

    public function onSelect() as $.Toybox.Lang.Boolean {
        activity.startStop();
        return true;
    }

    public function updateView() as Void {
        WatchUi.requestUpdate();
    }

    public function onPreviousPage() as $.Toybox.Lang.Boolean {
        activity.addScore(SpikeballActivity.TEAM_GREY);
        return true;
    }

    public function onNextPage() as $.Toybox.Lang.Boolean {
        activity.addScore(SpikeballActivity.TEAM_YELLOW);
        return true;
    }
}
