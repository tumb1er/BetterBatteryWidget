using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;


/**
Shows debug data in text
*/
class InfoPage extends WatchUi.View {
	var mState;
	var mChargedText;
	var mIntervalText;
	var mMarkText;
	var cx, sw, sh, mh, my;
	var markDateOffset;

    function initialize(state) {
    	View.initialize();
		mState = state;
	}
	
    function onLayout( dc ) {
    	var RS = Rez.Strings;
    	sw = dc.getWidth();
    	sh = dc.getHeight();
    	cx = sw / 2;
    	mh = loadResource(RS.MarkButtonHeight).toNumber();
    	my = loadResource(RS.MarkButtonY).toNumber();
    	var sy = loadResource(RS.StatsY).toNumber();
    	var ss = loadResource(RS.StatsSpacing).toNumber();
    	markDateOffset = loadResource(RS.MarkDateOffset).toNumber();
    	var params = {
    		:width => sw,
    		:height => loadResource(RS.TriTextHeight).toNumber(),
    		:locX => 0,
    		:locY => sy,
    		:color => 0xFFFFFF,
    		:title => "charged",
    		:suffix => true,
    		:text => "no charge date"
    	};
    	mChargedText = new TriText(params);
    	params.put(:title, "last 30m");
    	params.put(:locY, sy + ss);
    	params.put(:text, "no interval data");
    	mIntervalText = new TriText(params);
    	params.put(:title, "mark");
    	params.put(:locY, sy + 2 * ss);
    	params.put(:text, "no mark set");
    	mMarkText = new TriText(params);
    	setLayout([mChargedText, mIntervalText, mMarkText]);
    }
	
	function drawCharged(dc, ts, percent, charging) {
		var now = Time.now().value();
		var data;
		if (charging){
			data = "charging";
		} else {
			data = Lang.format("On battery $1$", [formatInterval(now - ts)]);
		}
    	dc.drawText(cx, 40, 
    			0, // Graphics.FONT_XTINY 
				data,
				5 // Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
		);
	}
	
	function drawMark(dc) {
		var mark = mState.mMark;
		var percent = "Mark";
		var marked = "press to put mark";
		if (mark != null) {
			marked = formatTimestamp(mark[0]);
			percent = Lang.format("Marked $1$", [formatPercent(mark[1])]);
		}
		dc.setColor(0xFF00FF, 0xFF00FF);
    	dc.fillRectangle(0, sh - mh, sw, sh);
		dc.setColor(0xFFFFFF, -1); // Graphics.COLOR_TRANSPARENT
		dc.drawText(cx, my, 
			3, // Graphics.FONT_MEDIUM
			percent,
			1 // Graphics.TEXT_JUSTIFY_CENTER
		);
		dc.drawText(cx, my + markDateOffset,
			0, // Graphics.FONT_XTINY
			marked,
			1 // Graphics.TEXT_JUSTIFY_CENTER
		);
	}
	
	function setPredictValues(view, speed, remaining) {
		if (speed != null) {
			view.value = formatInterval(remaining);
			view.desc = Lang.format("$1$/h", [formatPercent(speed * 3600)]);
		} else {
			view.value = null;
		}
	}
	
	function onUpdate(dc) {
		var result = new Result(mState);
		var stats = System.getSystemStats();
		result.predictCharged();
		result.predictWindow();
		result.predictMark();
		setPredictValues(mChargedText, result.chargedSpeed, result.chargedPredict);
		setPredictValues(mIntervalText, result.windowSpeed, result.windowPredict);
		setPredictValues(mMarkText, result.markSpeed, result.markPredict);
    	
		View.onUpdate(dc);	
		dc.fillPolygon([[cx, 5], [cx + 5, 10], [cx - 5, 10]]);   
		drawMark(dc); 	
	}
	
	function mark() {
		mState.mark();
		mState.save();
		requestUpdate();
	}
}

class InfoPageBehaviorDelegate extends WatchUi.BehaviorDelegate {
	var mView;
	//var log;
	var handleSelect;

    function initialize(view) {
        BehaviorDelegate.initialize();
        //log = new Log("InfoPageBehaviorDelegate");
        mView = view;
        var s = System.getDeviceSettings();
        handleSelect = !s.isTouchScreen;
    }
    
    function onBack() {
		//log.msg("onBack");
        popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
    
    function onPreviousPage() {
    	//log.msg("onPreviousPage");
		var app = Application.getApp();
		var view = new GraphPage(app.mState);
		switchToView(view, new GraphPageBehaviorDelegate(view), WatchUi.SLIDE_DOWN);    
    }
    
    function onSelect() {
    	if (handleSelect) {
    		mView.mark();
    	}
    	return handleSelect;
    }
       
    function onTap(clickEvent) {
    	var coords = clickEvent.getCoordinates();
    	var type = clickEvent.getType();
    	//log.debug("onTap", [coords, type]);
    	if (type == WatchUi.CLICK_TYPE_TAP && coords[1] >= 160) {
	    	mView.mark();
    	}	
    	return true;
    }
}


(:test)
function testInfoPageSmoke(logger) {
	var app = Application.getApp();
	var page = new InfoPage(app.mState);
	assertViewDraw(logger, page);
	return true;
}
