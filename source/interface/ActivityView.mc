import Toybox.Graphics;
import Toybox.WatchUi;

using InterfaceComponentsManager as ICM;

class SpikeballActivityView extends WatchUi.View {

    private var activity as SpikeballActivity;

    function initialize(activity as SpikeballActivity) {
        View.initialize();

        self.activity = activity;
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
        dc.drawText(ICM.scaleX(0.219), ICM.scaleY(0.500), ICM.fontLarge, activity.getScore(SpikeballActivity.TEAM_GREY), ICM.JTEXT_MID);
        dc.drawText(ICM.scaleY(0.295), ICM.scaleY(0.816), ICM.fontLarge, activity.getScore(SpikeballActivity.TEAM_YELLOW), ICM.JTEXT_MID);
        dc.drawText(ICM.scaleX(0.574), ICM.scaleY(0.185), ICM.fontMedium, activity.getFormattedTime(), ICM.JTEXT_MID);
        dc.drawText(ICM.scaleX(0.718), ICM.scaleY(0.816), ICM.fontMedium, activity.getHR(), ICM.JTEXT_MID);
    }

    function onHide() as Void {
    }

}

class SpikeballActivityDelegate extends BehaviorDelegate {

    private var activity as SpikeballActivity;
    private var timer as TimerController;

    private var updateTimer as TimerCallback?;

    public function initialize(activity as SpikeballActivity, timer as TimerController) {
        BehaviorDelegate.initialize();

        self.activity = activity;
        self.timer = timer;
    }

    public function onSelect() as $.Toybox.Lang.Boolean {
        var isStarted = activity.startStop();
        if (isStarted) {
            updateTimer = timer.start(method(:updateView), 2, true);
        } else {
            timer.stop(updateTimer);
        }
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
