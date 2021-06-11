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
    		:title => loadResource(RS.Charged),
    		:suffix => true,
    		:text => loadResource(RS.NoChargeData)
    	};
    	mChargedText = new TriText(params);
    	params.put(:title, loadResource(RS.Last30Min));
    	params.put(:locY, sy + ss);
    	params.put(:text, loadResource(RS.NoIntervalData));
    	mIntervalText = new TriText(params);
    	params.put(:title, loadResource(RS.mark));
    	params.put(:locY, sy + 2 * ss);
    	params.put(:text, loadResource(RS.NoMarkSet));
    	mMarkText = new TriText(params);
    	setLayout([mChargedText, mIntervalText, mMarkText]);
    }
	
	function drawCharged(dc, ts, percent, charging) {
		var now = Time.now().value();
		var data;
		var RS = Rez.Strings;
		if (charging){
			data = loadResource(RS.Charging);
		} else {
			data = Lang.format(loadResource(RS.OnBatteryWithParam), [formatInterval(now - ts)]);
		}
    	dc.drawText(cx, 40, 
    			0, // Graphics.FONT_XTINY 
				data,
				5 // Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
		);
	}
	
	function drawMark(dc) {
		var mark = mState.mMark;
		var RS = Rez.Strings;
		var percent = loadResource(RS.Mark);
		var marked = loadResource(RS.PressToPutMark);
		if (mark != null) {
			marked = formatTimestamp(mark[0]);
			percent = Lang.format(loadResource(RS.MarkedWithParam), [formatPercent(mark[1])]);
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
			view.desc = Lang.format(loadResource(Rez.Strings.perHourWithParam), [formatPercent(speed * 3600)]);
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

class InfoPageBehaviorDelegate extends WatchUi.InputDelegate {
	var mView;
	//var log;

    function initialize(view) {
        InputDelegate.initialize();
        //log = new Log("InfoPageBehaviorDelegate");
        mView = view;
        var s = System.getDeviceSettings();
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
		return true;
    }
    
    function onSelect() {
		mView.mark();
    	return true;
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
        
    function onKey(keyEvent) {
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
    
    function onSwipe(swipeEvent) {
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
function testInfoPageSmoke(logger) {
	var app = Application.getApp();
	var page = new InfoPage(app.mState);
	assertViewDraw(logger, page);
	return true;
}
