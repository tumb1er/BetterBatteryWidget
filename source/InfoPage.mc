using Toybox.Application;
using Toybox.Graphics;
import Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;
import Toybox.Test;

/**
Shows debug data in text
*/
class InfoPage extends WatchUi.View {
    var mState as State;

    var mChargedText as TriText?;
    var mIntervalText as TriText?;
    var mMarkText as TriText?;
    
    var cx as Number = 0, sw as Number = 0, sh as Number = 0, mh as Number = 0, my as Number = 0;
    var markDateOffset as Number = 0;

    public function initialize(state as State) {
        View.initialize();
        mState = state;
    }
    
    function onLayout( dc ) {
        var RS = Rez.Strings;
        sw = dc.getWidth();
        sh = dc.getHeight();
        cx = (sw / 2).toNumber();
        mh = Application.Properties.getValue("MBH");
        my = Application.Properties.getValue("MBY");
        var sy = loadNumberFromStringResource(RS.StatsY);
        var ss = loadNumberFromStringResource(RS.StatsSpacing);
        markDateOffset = Application.Properties.getValue("MDO");
        var params = {
            :width => sw,
            :height => Application.Properties.getValue("TTH"),
            :locX => 0,
            :locY => sy,
            :color => Graphics.COLOR_WHITE,
            :title => loadResource(RS.SinceCharged) as String,
            :suffix => true,
            :text => loadResource(RS.NoChargeData) as String
        };
        mChargedText = new TriText(params);
        params.put(:title, loadResource(RS.Last30Min) as String);
        params.put(:locY, sy + ss);
        params.put(:text, loadResource(RS.NoIntervalData) as String);
        mIntervalText = new TriText(params);
        params.put(:title, loadResource(RS.mark) as String);
        params.put(:locY, sy + 2 * ss);
        params.put(:text, loadResource(RS.NoMarkSet) as String);
        mMarkText = new TriText(params);
        setLayout([mChargedText, mIntervalText, mMarkText] as Lang.Array<WatchUi.Drawable>);
    }
    
    private function drawCharged(dc as Graphics.Dc, ts as Number, percent as Float, charging as Boolean) as Void {
        var now = Time.now().value();
        var data;
        var RS = Rez.Strings;
        if (charging){
            data = loadResource(RS.Charging) as String;
        } else {
            data = Lang.format(loadResource(RS.OnBatteryWithParam) as String, [formatInterval(now - ts)]);
        }
        dc.drawText(
            cx, 40, 
            Graphics.FONT_XTINY,
            data,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
    
    private function drawMark(dc as Graphics.Dc) as Void {
        var mark = mState.getMarkPoint();
        var RS = Rez.Strings;
        var percent = loadResource(RS.Mark) as String;
        var marked = loadResource(RS.PressToPutMark) as String;
        if (mark != null) {
            marked = formatTimestamp(mark.getTS());
            percent = Lang.format(loadResource(RS.MarkedWithParam) as String, [formatPercent(mark.getValue())]);
        }
        dc.setColor(Graphics.COLOR_PINK, Graphics.COLOR_PINK);
        dc.fillRectangle(0, sh - mh, sw, sh);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, my, 
            Graphics.FONT_MEDIUM,
            percent,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(cx, my + markDateOffset,
            Graphics.FONT_XTINY,
            marked,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
    
    private function setPredictValues(view as TriText, predict as BatteryPoint?) as Void {
        var speed = (predict != null)? predict.getValue(): null;
        if (speed != null) {
            view.value = formatInterval((predict as BatteryPoint).getTS());
            view.desc = Lang.format(loadResource(Rez.Strings.perHourWithParam) as String, [formatPercent(speed * 3600)]);
        } else {
            view.value = "";
            view.desc = "";
        }
    }
    
    public function onUpdate(dc as Graphics.Dc) as Void {
        var result = new Result(mState);
        var stats = System.getSystemStats();
        result.predictCharged();
        result.predictWindow();
        result.predictMark();
        setPredictValues(mChargedText as TriText, result.getChargedPredict());
        setPredictValues(mIntervalText as TriText, result.getWindowPredict());
        setPredictValues(mMarkText as TriText, result.getMarkPredict());

        var c = cx as Lang.Number;
        
        View.onUpdate(dc);    
        dc.fillPolygon([
            [c, 5] as Lang.Array<Lang.Numeric>, 
            [c + 5, 10] as Lang.Array<Lang.Numeric>, 
            [c - 5, 10] as Lang.Array<Lang.Numeric>
        ] as Lang.Array<Lang.Array<Lang.Numeric> >);   
        drawMark(dc);     
    }
    
    public function mark() as Void {
        mState.mark();
        mState.save();
        requestUpdate();
    }
}

class InfoPageBehaviorDelegate extends WatchUi.InputDelegate {
    var mView as InfoPage;
    //var log;

    public function initialize(view as InfoPage) {
        InputDelegate.initialize();
        //log = new Log("InfoPageBehaviorDelegate");
        mView = view;
    }
    
    public function onBack() as Boolean {
        //log.msg("onBack");
        popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
    
    public function onPreviousPage() as Boolean {
        //log.msg("onPreviousPage");
        var app = getApp();
        var view = new GraphPage(app.getState());
        switchToView(view, new GraphPageBehaviorDelegate(view), WatchUi.SLIDE_DOWN);    
        return true;
    }
    
    public function onSelect() as Boolean {
        mView.mark();
        return true;
    }
       
    public function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var coords = clickEvent.getCoordinates();
        var type = clickEvent.getType();
        //log.debug("onTap", [coords, type]);
        if (type == WatchUi.CLICK_TYPE_TAP && coords[1] >= 160) {
            mView.mark();
        }    
        return true;
    }
        
    public function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        //log.debug("onKey", keyEvent.getKey());
        switch(keyEvent.getKey()) {
            case WatchUi.KEY_ENTER:
                return onSelect();
            case WatchUi.KEY_UP:
                return onPreviousPage();
            case WatchUi.KEY_ESC:
                return onBack();            
            default:
                //log.msg("wrong button");
                return true;
        }
    }
    
    public function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
           //log.debug("onSwipe", swipeEvent.getDirection());
           switch (swipeEvent.getDirection()) {
               case WatchUi.SWIPE_DOWN:
                   return onPreviousPage();
            case WatchUi.SWIPE_RIGHT:
                   return onBack();
               default:
                   return false;
           }
       }
}


(:test)
function testInfoPageSmoke(logger as Logger) as Boolean {
    var app = getApp();
    var page = new InfoPage(app.getState());
    assertViewDraw(logger, page);
    return true;
}
