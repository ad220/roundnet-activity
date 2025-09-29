import Toybox.Lang;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Attention;

using InterfaceComponentsManager as ICM;

class RoundnetActivityView extends WatchUi.View {

    private var activity as RoundnetActivity;

    public var loopField as LoopField;

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

    private var view as RoundnetActivityView;
    private var activity as RoundnetActivity;
    private var uiTimer as TimerController;
    private var doubleClickSpeed as Number;
    private var swipeScroll as Boolean;
    private var currentTimer as TimerCallback?;
    private var lastInput as WatchUi.Key?;

    public function initialize(view as RoundnetActivityView, activity as RoundnetActivity) {
        BehaviorDelegate.initialize();

        self.view = view;
        self.activity = activity;
        self.uiTimer = new TimerController(80);
        self.doubleClickSpeed = getApp().settings.get("doubleclickspeed") as Number;
        self.swipeScroll = getApp().settings.get("swipescroll") as Boolean;
    }

    public function onSelect() as Boolean {
        return false;
    }

    public function onKey(keyEvent as KeyEvent) as Boolean {
        if (keyEvent.getKey()==KEY_ENTER and keyEvent.getType()==PRESS_TYPE_ACTION) {
            activity.stop();
            uiTimer.stopAll();
            view.loopField.stop();
            var menu = new Rez.Menus.StopMenu();
            menu.setTitle(activity.getFormattedTime());
            WatchUi.switchToView(menu, new StopDelegate(activity), WatchUi.SLIDE_UP);
            return true;
        } else if (keyEvent.getKey()==KEY_ESC and keyEvent.getType()==PRESS_TYPE_ACTION) {
            warnLap();
            return true;
        }
        return false;
    }

    (:va3)
    public function onMenu() as Boolean {
        warnLap();
        return true;
    }

    public function onBack() as Boolean {
        return false;
    }

    public function onSwipe(swipeEvent as SwipeEvent) as Boolean {
        if (swipeScroll) {
            if (swipeEvent.getDirection()==SWIPE_LEFT) {
                view.loopField.nextField();
            } else if (swipeEvent.getDirection()==SWIPE_RIGHT) {
                view.loopField.previousField();
            }
        }
        return true;
    }

    (:buttons)
    public function onTap(clickEvent as ClickEvent) as Boolean {
        return false;
    }
    
    (:buttons)
    public function onNextPage() as Boolean {
        scorePlayer();
        return true;
    }

    (:buttons)
    public function onPreviousPage() as Boolean {
        scoreOpponent();
        return true;
    }

    (:touch)
    public function onTap(tap as ClickEvent) as Boolean {
        var coord = tap.getCoordinates();
        if (coord[0]<ICM.scaleX(0.5) and coord[1]<ICM.scaleY(0.66) and coord[1]>ICM.scaleY(0.33)) {
            scoreOpponent();
            return true;
        } else if (coord[0]<ICM.scaleX(0.5) and coord[1]>ICM.scaleY(0.66)) {
            scorePlayer();
            return true;
        } 
        return false;
    }

    public function onTimer() as Void {
        lastInput = null;
    }

    public function scorePlayer() as Void {
        if (lastInput==KEY_DOWN) {
            lastInput = null;
            uiTimer.stop(currentTimer);
            activity.decrPlayerScore();
        } else {
            lastInput = KEY_DOWN;
            uiTimer.stop(currentTimer);
            uiTimer.start(method(:onTimer), doubleClickSpeed, false);
            currentTimer = uiTimer.start(activity.method(:incrPlayerScore), doubleClickSpeed, false);
        }
    }

    public function scoreOpponent() as Void {
        if (lastInput==KEY_UP) {
            lastInput = null;
            uiTimer.stop(currentTimer);
            activity.decrOpponentScore();
        } else {
            lastInput = KEY_UP;
            uiTimer.stop(currentTimer);
            uiTimer.start(method(:onTimer), doubleClickSpeed, false);
            currentTimer = uiTimer.start(activity.method(:incrOpponentScore), doubleClickSpeed, false);
        }
    }

    public function triggerSwitchAlarm() as Void {
        view.loopField.showSwitchAlarm();
    } 

    public function warnLap() as Void {
        var view = new LapView(activity, uiTimer);
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(80, 600)]);
        }
        if (Attention has :playTone) {
            Attention.playTone({:toneProfile => [new Attention.ToneProfile(690, 600)]});
        }
        WatchUi.pushView(view, new LapDelegate(view), SLIDE_IMMEDIATE);
    }
}
