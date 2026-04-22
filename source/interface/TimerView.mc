import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Graphics;

using InterfaceComponentsManager as ICM;

class TimerView extends WatchUi.View {

    private var delegate as TimerDelegate;
    private var layoutId        as Symbol;
    private var icon            as ResourceId or BitmapType;
    private var label           as String?;


    public function initialize(
        delegate    as TimerDelegate,
        layoutId    as Symbol,
        icon        as ResourceId or BitmapType,
        label       as String?
    ) {
        View.initialize();

        self.delegate   = delegate;
        self.layoutId   = layoutId;
        self.icon       = icon;
        self.label      = label;
    }

    
    public function onLayout(dc as Dc) as Void {
        var layout = (new Method(Rez.Layouts, layoutId)).invoke(dc);
        var width = dc.getWidth();
        var height = dc.getHeight();

        var titleIcon = new Bitmap({:rezId => Rez.Drawables.Ball});
        var titleTxt = new Text({
            :text => "",
            :color => Graphics.COLOR_WHITE,
            :backgroundColor => Graphics.COLOR_BLACK,
            :font => ICM.fontMedium,
            :locX => 0.46 * width,
            :locY => 0.185 * height,
        });

        var options = {:locX => 0.45*width, :locY =>0.45*height};
        if (icon instanceof ResourceId) { options[:rezId] = icon; }
        else                            { options[:bitmap] = icon; }
        var labelIcon = new Bitmap(options);

        layout.addAll([titleIcon, titleTxt, labelIcon]);
        setLayout(layout);
        adjustLayout();
    }

    (:notva3)
    private function adjustLayout() as Void {}

    (:va3)
    private function adjustLayout() as Void {
        var bmpIds = ["Confirm", "Pause", "Cancel"];

        for (var i=0; i<bmpIds.size(); i+=1)
        {
            var bmp = findDrawableById(bmpIds[i]) as Bitmap?;
            if (bmp != null) { bmp.setLocation(0,0); } // setVisible unavailable for va3
        }
    }

    public function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);

        var width = dc.getWidth();
        var height = dc.getHeight();
        var currentTick = delegate.getCurrentTick();
        var maxTicks = delegate.getDurationTicks();

        dc.setPenWidth(0.025 * width);
        dc.setColor(delegate.isPaused() ? Graphics.COLOR_DK_GRAY : 0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(0.5*width, 0.5*height, 0.5*width, Graphics.ARC_CLOCKWISE, 90, 90 + (currentTick * 360 / maxTicks));

        currentTick = maxTicks - currentTick;
        var labelText = label!=null ? label : currentTick/60 + ":" + (currentTick%60).format("%02d");
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0.5*width, 0.64*height, ICM.fontLarge, labelText, ICM.JTEXT_MID);
    }

}

class TimerDelegate extends BehaviorDelegate {

    private var activity        as RoundnetActivity;
    private var timerController as TimerController;
    private var animationTimer  as TimerCallback?;
    private var currentTick     as Number;
    private var durationTicks   as Number;

    public function initialize(
        activity        as RoundnetActivity,
        timer           as TimerController,
        durationTicks   as Number
    ) {
        BehaviorDelegate.initialize();

        self.activity = activity;
        self.timerController = timer;
        self.animationTimer = timer.start(method(:animate), 1, true);
        self.currentTick = 0;
        self.durationTicks = durationTicks;

        if (timer == getApp().timer) { activity.stop(); }
    }

    (:buttons)
    public function onKey(keyEvent as KeyEvent) as Boolean {
        if (keyEvent.getType() != PRESS_TYPE_ACTION) { return false; }
        return onInput(keyEvent.getKey());
    }

    (:touch)
    public function onKey(keyEvent as KeyEvent) as Boolean {
        if (keyEvent.getType() != PRESS_TYPE_ACTION) { return false; }

        var key = keyEvent.getKey();
        if (key == KEY_ESC) { key = KEY_DOWN; }
        return onInput(key);
    }

    (:va3)
    public function onBack() as Boolean {
        return onInput(KEY_DOWN);
    }

    
    public function onInput(key as Key) as Boolean {
        var isLap = timerController != getApp().timer;

        if      (key == KEY_ENTER) 
        {
            if (isLap) {
                activity.lap();
                animationTimer.stop();
                exit();
            }
            else {
                if (animationTimer == null) {
                    animationTimer = timerController.start(method(:animate), 1, true);
                }
                else {
                    animationTimer.stop();
                    animationTimer = null;
                }
                requestUpdate();
            }
            return true;
        }
        else if (key == KEY_ESC)
        {
            if (isLap)
            {
                activity.lap();
                animationTimer.stop();
                
                self.initialize(activity, getApp().timer, 180);
                var nview = new TimerView(self, :TimerLayout, Rez.Drawables.Bottle, null);
                switchToView(nview, self, SLIDE_IMMEDIATE);
            }
            return true;
        }
        else if (key == KEY_DOWN)
        {
            if (!isLap) { activity.resume(); }
            if (animationTimer!=null) { animationTimer.stop(); }

            exit();
            return true;
        }
        return false;
    }

    public function animate() as Void {
        if (currentTick < durationTicks) {
            currentTick += 1;
            requestUpdate();
        } else {
            animationTimer.stop();
            if (timerController != getApp().timer)  { activity.lap(); }
            else                                    { activity.resume(); }
            exit();
        }
    }

    private function exit() as Void {
        var view = new RoundnetActivityView(activity);
        var delegate = new RoundnetActivityDelegate(view, activity);
        activity.registerDelegate(delegate);
        switchToView(view, delegate, SLIDE_IMMEDIATE);
    }

    public function getCurrentTick() as Number {
        return currentTick;
    }

    public function getDurationTicks() as Number {
        return durationTicks;
    }

    public function isPaused() as Boolean {
        return animationTimer == null;
    }
}