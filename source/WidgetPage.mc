using Toybox.Application;
using Toybox.Graphics;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
	

class WidgetPage extends WatchUi.View {
	var mState;
	var log;
	var mGaugeDrawable, mPercentText, mPredictText;
	
	var percent, predicted;

    function initialize(state) {
        View.initialize();
        log = new Log("WidgetPage");
    	//log.debug("initialize", state);
    	mState = state;
        mState.measure();
        mState.save();
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
    		:font => 2, // Graphics.FONT_SMALL
    		:justification => 5 // Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER
		});		
    	
    	var bitmap = new WatchUi.Bitmap({
    		:rezId => Rez.Drawables.BatteryIcon
    	});
    	var s = bitmap.getDimensions();
    	bitmap.setLocation(w2 - s[0] / 2, 7 * w2 / 12  - s[1] / 2);
    	
    	setLayout([mGaugeDrawable, mPercentText, bitmap, mPredictText]);
    }
    
    function onShow() {
		var stats = System.getSystemStats();
		percent = stats.battery;
        predicted = computePredicted(stats);
		mGaugeDrawable.color = colorize(percent);
		WatchUi.animate(mGaugeDrawable, :value, WatchUi.ANIM_TYPE_EASE_OUT, 0, percent, 0.5, null);
		WatchUi.animate(mPercentText, :percent, WatchUi.ANIM_TYPE_LINEAR, 0, percent, 0.5, null);    	
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
				predicted = "charging...";
			} else {
				predicted = "measuring...";
			}
		} else {
			predicted = formatInterval(predicted);
		}
		return predicted;		
	}
    
    function updateState(state) {
    	mState = state;
    	mState.save();
    }

}

class WidgetPageInputDelegate extends WatchUi.InputDelegate {
	var log;

    function initialize() {
        InputDelegate.initialize();
        log = new Log("WidgetPageInputDeletage");
    }
    
    function onTap(event) {
		//log.debug("onTap", event);
		var app = Application.getApp();
		var view = new GraphPage(app.mState);
		pushView(view, new GraphPageInputDelegate(view), WatchUi.SLIDE_IMMEDIATE);    
    	return true;
    }
}

(:test)
function testWidgetPageSmoke(logger) {
	var app = Application.getApp();
	var page = new WidgetPage(app.mState);
	assertViewDraw(logger, page);
	return true;
}
