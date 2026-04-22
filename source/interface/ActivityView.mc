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
        // if (dc has :setAntiAlias) {
        //     dc.setAntiAlias(true);
        // }
        View.onUpdate(dc);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var scorePlayer = activity.getScore(RoundnetActivity.TEAM_PLAYER);
        var scoreOpponent = activity.getScore(RoundnetActivity.TEAM_OPPONENT);
        var scoreFont = ICM.fontLarge;
        if (!activity.isHelperReady()) {
            var state = activity.getServiceState() == 0xF0;
            var obsMode = getApp().settings["observer_mode"] as Boolean;

            if (obsMode) { 
                if (state) {
                    // skip team mate position setup
                    activity.initServiceHelper(RoundnetActivity.TEAM_PLAYER);
                }
                scorePlayer = loadResource(Rez.Strings.Yellow);
                scoreOpponent = loadResource(Rez.Strings.Gray);
            } else {
                scorePlayer = loadResource(state ? Rez.Strings.Right : Rez.Strings.Us);
                scoreOpponent = loadResource(state ? Rez.Strings.Left : Rez.Strings.Them);
            }
            scoreFont = ICM.fontMedium;
        }

        dc.drawText(ICM.scaleX(0.219), ICM.scaleY(0.500), scoreFont, scoreOpponent, ICM.JTEXT_MID);
        dc.drawText(ICM.scaleY(0.295), ICM.scaleY(0.816), scoreFont, scorePlayer, ICM.JTEXT_MID);
        dc.drawText(ICM.scaleX(0.440), ICM.scaleY(0.185), ICM.fontMedium, activity.getFormattedTime(), ICM.JTEXT_LEFT);

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
    private var doubleClickTimer as TimerCallback?;
    private var lastInput as Key?;
    private var obsModeEnabled as Boolean;

    public function initialize(view as RoundnetActivityView, activity as RoundnetActivity) {
        BehaviorDelegate.initialize();

        self.view = view;
        self.activity = activity;
        self.uiTimer = new TimerController(80);

        var settings = getApp().settings;
        self.doubleClickSpeed = settings.get("doubleclickspeed") as Number;
        self.swipeScroll = settings.get("swipescroll") as Boolean;
        self.obsModeEnabled = settings.get("observer_mode") as Boolean;
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
            switchToView(menu, new StopDelegate(activity), SLIDE_UP);
            return true;
        } else if (keyEvent.getKey()==KEY_ESC and keyEvent.getType()==PRESS_TYPE_ACTION) {
            if (obsModeEnabled) { onObserverLap(); }
            else                { warnLap(); }
            return true;
        }
        return false;
    }

    (:va3)
    public function onMenu() as Boolean {
        warnLap();
        return true;
    }

    (:notva3)
    public function onMenu() as Boolean {
        var menu = new Rez.Menus.ActivityMenu();
        switchToView(menu, new ActivityMenuDelegate(menu, activity), SLIDE_UP);
        return true;
    }

    public function onBack() as Boolean {
        return false;
    }

    public function onSwipe(swipeEvent as SwipeEvent) as Boolean {
        if (swipeScroll and activity.isHelperReady()) {
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

    public function onClickTimeout() as Void {
        lastInput = null;
    }

    public function scorePlayer() as Void {
        if (activity.isHelperReady()) {

            if (lastInput == KEY_DOWN) {
                lastInput = null;
                uiTimer.stop(doubleClickTimer);
                activity.decrPlayerScore();
            } else {
                lastInput = KEY_DOWN;
                uiTimer.stop(doubleClickTimer);
                uiTimer.start(method(:onClickTimeout), doubleClickSpeed, false);
                doubleClickTimer = uiTimer.start(activity.method(:incrPlayerScore), doubleClickSpeed, false);
            }
        } else {
            activity.initServiceHelper(RoundnetActivity.TEAM_PLAYER);
            view.loopField.refreshField();
        }
    }

    public function scoreOpponent() as Void {
        if (activity.isHelperReady()) {

            if (lastInput == KEY_UP) {
                lastInput = null;
                uiTimer.stop(doubleClickTimer);
                activity.decrOpponentScore();
            } else {
                lastInput = KEY_UP;
                uiTimer.stop(doubleClickTimer);
                uiTimer.start(method(:onClickTimeout), doubleClickSpeed, false);
                doubleClickTimer = uiTimer.start(activity.method(:incrOpponentScore), doubleClickSpeed, false);
            }
        } else {
            activity.initServiceHelper(RoundnetActivity.TEAM_OPPONENT);
            view.loopField.refreshField();
        }
    }

    public function triggerSwitchAlarm() as Void {
        view.loopField.showSwitchAlarm();
    } 

    public function warnLap() as Void {
        var dlgt = new TimerDelegate(activity, uiTimer, 100);
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(80, 600)]);
        }
        if (Attention has :playTone) {
            Attention.playTone({:toneProfile => [new Attention.ToneProfile(690, 600)]});
        }
        var label = activity.getScore(RoundnetActivity.TEAM_PLAYER) + " - " + activity.getScore(RoundnetActivity.TEAM_OPPONENT);
        switchToView(new TimerView(dlgt, :LapLayout, Rez.Drawables.Score, label), dlgt, SLIDE_IMMEDIATE);
    }

    public function onLap() as Void {
        view.loopField.resetField();
    }

    public function onObserverLap() as Void {
        if (activity.isHelperReady()) {
            if (lastInput == KEY_ESC) {
                lastInput = null;
                cancelServiceTimer();
                warnLap();
            } else {
                lastInput = KEY_ESC;
                uiTimer.stop(doubleClickTimer);
                uiTimer.start(method(:onClickTimeout), doubleClickSpeed, false);
                startServiceTimer();
            }
        } else {
            warnLap();
        }
    }

    private function startServiceTimer() as Void {
        getApp().preciseTimer.start(method(:onServiceTimer), 3000, false);
    }

    private function cancelServiceTimer() as Void {
        getApp().preciseTimer.start(method(:onClickTimeout), 0, false);
    }

    public function onServiceTimer() as Void {
        if (Attention has :vibrate) { Attention.vibrate([new Attention.VibeProfile(100, 200)]); }
    }
}
