using Toybox.Application;
using Toybox.Graphics;
import Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
import Toybox.Test;
using Toybox.WatchUi;
    

class WidgetPage extends WatchUi.View {
    var mState as State;
    //var log;
    var mGaugeDrawable as GaugeDrawable?;
    var mPercentText as PercentText?;
    var mPredictText as WatchUi.Text?;
    
    var percent as Float = 0.0, predicted as String = "";

    public function initialize(state as State) {
        View.initialize();
        //log = new Log("WidgetPage");
        //log.debug("initialize", state);
        mState = state;
        mState.measure();
    }

    public function onLayout(dc as Graphics.Dc) as Void {
        var w2 = dc.getWidth() / 2;

        mGaugeDrawable = new GaugeDrawable({
            :radius => w2,
            :pen => Application.Properties.getValue("GP")
        });
        
        mPercentText = new PercentText({
            :locX => w2,
            :locY => w2,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_SYSTEM_NUMBER_HOT,
            :justification => Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER
        });
        
        mPredictText = new WatchUi.Text({
            :locX => w2,
            :locY => 4 * w2 / 3,
            :color => Graphics.COLOR_WHITE,
            :font => Graphics.FONT_SMALL,
            :justification => Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER
        });        
        
        var bitmap = new WatchUi.Bitmap({
            :rezId => Rez.Drawables.BatteryIcon
        });
        var s = bitmap.getDimensions();
        bitmap.setLocation(w2 - s[0] / 2, 7 * w2 / 12  - s[1] / 2);
        
        setLayout([mGaugeDrawable, mPercentText, bitmap, mPredictText] as Lang.Array<WatchUi.Drawable>);
    }
    
    public function onShow() as Void {
        var stats = System.getSystemStats();
        percent = stats.battery;
        predicted = computePredicted(stats);
        var gd = (mGaugeDrawable as GaugeDrawable);
        gd.color = colorize(percent);
        try {
            WatchUi.animate(mGaugeDrawable, :value, WatchUi.ANIM_TYPE_EASE_OUT, 0, percent, 0.5, null);
            WatchUi.animate(mPercentText, :percent, WatchUi.ANIM_TYPE_LINEAR, 0, percent, 0.5, null);
        } catch (e instanceof Lang.InvalidValueException) {
            throw new LogException(Lang.format("Invalid value $1$: $2$", [percent, e.getErrorMessage()]));
        }
    }
    
    public function onUpdate(dc as Graphics.Dc) as Void {
        (mPredictText as PercentText).setText(predicted);
        View.onUpdate( dc );
    }    
    
    private function computePredicted(stats as System.Stats) as String {
        var result = new Result(mState);
        result.predictWindow();
        result.predictCharged();
        var predicted = result.predictAvg(0.5);
        if (predicted == null) {
            if (stats.charging) {
                return loadResource(Rez.Strings.ChargingDot) as String;
            } else {
                return loadResource(Rez.Strings.MeasuringDot) as String;
            }
        } else {
            return formatInterval(predicted.toNumber());
        }
    }
}

class WidgetPageBehaviorDelegate extends WatchUi.InputDelegate {
    //var log;

    public function initialize() {
        InputDelegate.initialize();
        //log = new Log("WidgetPageBehaviorDelegate");
    }
    
    private function enterWidget() as Boolean {
        //log.msg("enterWidget");
        var app = getApp();
        var view = new GraphPage(app.getState());
        pushView(view, new GraphPageBehaviorDelegate(view), WatchUi.SLIDE_IMMEDIATE);   
        //log.msg("enterWidget done"); 
        return true;
    }
    
    public function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        //log.debug("onKey", keyEvent.getKey());
        if (keyEvent.getKey() == WatchUi.KEY_ENTER) {
            return enterWidget();
        }
        return false;
    }
    
    public function onTap(tapEvent as WatchUi.tapEvent) as Boolean {
           //log.msg("onTap");
           return enterWidget();
       }
       public function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
           //log.msg("onSwipe");
           return false;
       }
}

(:test)
function testWidgetPageSmoke(logger as Logger) as Boolean {
    var app = getApp();
    var page = new WidgetPage(app.getState());
    assertViewDraw(logger, page);
    return true;
}
