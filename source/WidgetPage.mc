using Toybox.Application;
using Toybox.Graphics;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

const cxl=119, cxr=120, cyt=119, cyb=120, ro=119, ri=104;
const angle=60;
const window = 12.0;
const beta=2/(1+window);
const rm=(ro+ri)/2, rw=(ro-ri+1)/2;
	

class WidgetPage extends WatchUi.View {
	var mBitmap;
	var mPercentText;
	var mPredictText;
	var mGraphDrawable;
	var mState;
	
	var percent, predicted;

    function initialize(state) {
        View.initialize();
    	log("View.initialize", state);
    	mState = state;
        mState.measure();
        mState.save();
    }

    function onLayout(dc) {
    	var w = dc.getWidth();
    	var h = dc.getHeight();
    	mGraphDrawable = new GraphDrawable({
	    	:width => w,
	    	:height => h
    	});
    	
    	mPercentText = new PercentText({
    		:locX => w / 2,
    		:locY => h / 2,
    		:color => Graphics.COLOR_WHITE,
    		:font => Graphics.FONT_SYSTEM_NUMBER_HOT,
    		:justification => Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER
    	});
    	
		mPredictText = new WatchUi.Text({
    		:locX => w / 2,
    		:locY => 2 * h / 3,
    		:color => Graphics.COLOR_WHITE,
    		:font => Graphics.FONT_SMALL,
    		:justification => Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER
		});		
    	
    	mBitmap = new WatchUi.Bitmap({
    		:rezId => Rez.Drawables.BatteryIcon
    	});
    	var s = mBitmap.getDimensions();
    	mBitmap.setLocation((w - s[0]) / 2, 7 * h / 24  - s[1] / 2);
    	
    	setLayout([mGraphDrawable, mPercentText, mBitmap, mPredictText]);
    }
    
    function onShow() {
		var stats = System.getSystemStats();
		percent = stats.battery;
        predicted = computePredicted(stats);
		mGraphDrawable.color = colorize(percent);
		WatchUi.animate(mGraphDrawable, :value, WatchUi.ANIM_TYPE_EASE_OUT, 0, percent, 0.5, null);
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

    function initialize() {
        InputDelegate.initialize();
    }
    
    function onTap(event) {
		log("WidgetPageInputDelegate.onTap", event);
		var app = Application.getApp();
		var view = new GraphPage(app.mState);
		pushView(view, new GraphPageInputDelegate(view), WatchUi.SLIDE_IMMEDIATE);    
    	return true;
    }
}
