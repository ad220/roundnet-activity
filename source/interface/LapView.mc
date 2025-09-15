import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;

class LapView extends WatchUi.View {

    private var activity as RoundnetActivity;
    private var animationTimer as TimerCallback;
    private var angleIncrement as Float;
    private var currentAngle as Float;

    private const REVERT_DELAY_TICKS = 80; 

    public function initialize(activity as RoundnetActivity, uiTimer as TimerController) {
        View.initialize();

        self.activity = activity;
        self.animationTimer = uiTimer.start(method(:animate), 1, true);
        self.angleIncrement = 360.0/REVERT_DELAY_TICKS;
        self.currentAngle = 90.0 + angleIncrement;
    }

    (:buttons)
    public function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.LapLayoutButtons(dc));
        (findDrawableById("timer_lap") as Text).setText(activity.getFormattedTime());
        (findDrawableById("score_lap") as Text).setText(activity.getScore(RoundnetActivity.TEAM_PLAYER) + " - " + activity.getScore(RoundnetActivity.TEAM_OPPONENT));
    }

    (:touch :notva3)
    public function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.LapLayoutTouch(dc));
        (findDrawableById("timer_lap") as Text).setText(activity.getFormattedTime());
        (findDrawableById("score_lap") as Text).setText(activity.getScore(RoundnetActivity.TEAM_PLAYER) + " - " + activity.getScore(RoundnetActivity.TEAM_OPPONENT));
    }

    (:va3)
    public function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.LapLayoutTouch(dc));
        (findDrawableById("timer_lap") as Text).setText(activity.getFormattedTime());
        (findDrawableById("score_lap") as Text).setText(activity.getScore(RoundnetActivity.TEAM_PLAYER) + " - " + activity.getScore(RoundnetActivity.TEAM_OPPONENT));
        (findDrawableById("confirmicon_lap_touch") as Bitmap).setBitmap(null);
        (findDrawableById("reverticon_lap_touch") as Bitmap).setBitmap(null);
    }

    public function onShow() as Void {
        
    }

    public function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        dc.setPenWidth(11);
        dc.setColor(0x000000, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(ICM.scaleX(0.5), ICM.scaleY(0.5), ICM.scaleX(0.5), Graphics.ARC_CLOCKWISE, 90, currentAngle);
    }

    public function onHide() as Void {
        
    }

    public function animate() as Void {
        if (currentAngle<450.0) {
            WatchUi.requestUpdate();
            currentAngle += angleIncrement;
        } else {
            confirm();
        }
    }

    public function confirm() as Void {
        activity.lap();
        animationTimer.stop();
        WatchUi.popView(SLIDE_IMMEDIATE);
    }

    public function revert() as Void {
        animationTimer.stop();
        WatchUi.popView(SLIDE_IMMEDIATE);
    }
}

class LapDelegate extends BehaviorDelegate {

    private var view as LapView;

    public function initialize(view as LapView) {
        BehaviorDelegate.initialize();
        self.view = view;
    }

    public function onSelect() as Boolean {
        view.confirm();
        return true;
    }

    (:touch)
    public function onBack() as Boolean {
        view.revert();
        return true;
    }

    (:buttons)
    public function onBack() as Boolean {
        return true;
    }

    (:buttons)
    public function onNextPage() as Boolean {
        view.revert();
        return true;
    }
}