using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
	

class WidgetPage extends WatchUi.View {
	var mState;
	//var log;
	var mGaugeDrawable, mPercentText, mPredictText;
	
	var percent, predicted;

    function initialize(state) {
        View.initialize();
        //log = new Log("WidgetPage");
    	//log.debug("initialize", state);
    	mState = state;
        mState.measure();
    }

    function onLayout(dc) {
    	var w2 = dc.getWidth() / 2;

    	mGaugeDrawable = new GaugeDrawable({
	    	:radius => w2,
	    	:pen => loadResource(Rez.Strings.GaugePen).toNumber()
    	});
    	
    	mPercentText = new PercentText({
    		:locX => w2,
    		:locY => w2,
    		:color => 0xFFFFFF,
    		:font => 16, // Graphics.FONT_SYSTEM_NUMBER_HOT
    		:justification => 5 // Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER
    	});
    	
		mPredictText = new WatchUi.Text({
    		:locX => w2,
    		:locY => 4 * w2 / 3,
    		:color => 0xFFFFFF,
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
    
    function onShow() {
		var stats = System.getSystemStats();
		percent = stats.battery;
        predicted = computePredicted(stats);
		mGaugeDrawable.color = colorize(percent);
		try {
			WatchUi.animate(mGaugeDrawable, :value, WatchUi.ANIM_TYPE_EASE_OUT, 0, percent, 0.5, null);
			WatchUi.animate(mPercentText, :percent, WatchUi.ANIM_TYPE_LINEAR, 0, percent, 0.5, null);
		} catch (e instanceof Lang.InvalidValueException) {
			throw new LogException(Lang.format("Invalid value $1$: $2$", [percent, e.getErrorMessage()]));
		}
    }
    
    function onUpdate( dc ) {
    	mPredictText.setText(predicted);
        View.onUpdate( dc );
	}    
	
	function computePredicted(stats) {
		var result = new Result(mState);
		result.predictWindow();
		result.predictCharged();
		var predicted = result.predictAvg(0.5);
		if (predicted == null) {
			if (stats.charging) {
				predicted = loadResource(Rez.Strings.ChargingDot);
			} else {
				predicted = loadResource(Rez.Strings.MeasuringDot);
			}
		} else {
			predicted = formatInterval(predicted);
		}
		return predicted;		
	}
    
    function updateState(state) {
    	mState = state;
    }

}

class WidgetPageBehaviorDelegate extends WatchUi.InputDelegate {
	//var log;

    function initialize() {
        InputDelegate.initialize();
        //log = new Log("WidgetPageBehaviorDelegate");
    }
    
    function enterWidget() {
		//log.msg("enterWidget");
		var app = Application.getApp() as BetterBatteryWidgetApp;
		var view = new GraphPage(app.mState);
		pushView(view, new GraphPageBehaviorDelegate(view), WatchUi.SLIDE_IMMEDIATE);   
		//log.msg("enterWidget done"); 
    	return true;
    }
    
    function onKey(keyEvent) {
    	//log.debug("onKey", keyEvent.getKey());
    	if (keyEvent.getKey() == WatchUi.KEY_ENTER) {
    		return enterWidget();
    	}
    	return false;
    }
    
    function onTap(tapEvent) {
   		//log.msg("onTap");
   		return enterWidget();
   	}
   	function onSwipe(swipeEvent) {
   		//log.msg("onSwipe");
   		return false;
   	}
}

(:test)
function testWidgetPageSmoke(logger) {
	var app = Application.getApp() as BetterBatteryWidgetApp;
	var page = new WidgetPage(app.mState);
	assertViewDraw(logger, page);
	return true;
}
