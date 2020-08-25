using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

/**
Shows discharge graph
*/
class GraphPage extends WatchUi.View {
	var mState;
	var mTriText;
	var mMode;
	var mGraph;
	var mGraphDuration;
	var mGraphMode;
	//var log;
	var mx, my, offset;

    function initialize(state) {
    	View.initialize();
		//log = new Log("GraphPage");
		mState = state;
		mMode = 0;
		var app = Application.getApp();
		mGraphDuration = 3600 * app.mGraphDuration;
		mGraphMode = app.mGraphMode;
	}
	
    function onLayout( dc ) {
    	var w = dc.getWidth();
    	var h = dc.getHeight();
    	
    	var RS = Rez.Strings;
    	
    	var gw = loadResource(RS.GraphWidth).toNumber();
    	var gh = loadResource(RS.GraphHeight).toNumber();
    	var th = loadResource(RS.GraphStatusHeight).toNumber();
    	var ty = loadResource(RS.GraphStatusY).toNumber();
    	offset = loadResource(RS.GraphIntervalOffset).toNumber();
    	mx = w / 2;
    	my = h - 10;
    	var graphMargin = (w - gw) / 2;
    	mGraph = new GraphDrawable({
	    	:width => gw,
	    	:height => gh,
	    	:x => graphMargin,
	    	:y => h / 2 - graphMargin,
	    	:border => 0xFFFFFF,
	    	:background => -1, // Graphics.COLOR_TRANSPARENT
	    	:shade => (mGraphMode == 1)? 0xAAAAAA: null,
	    	:foreground => 0xFF0000,
	    	:interval => mGraphDuration,
	    	:scale => 0
    	});
    	mGraph.mShowExtremums = false;
    	//log.debug("setData", mState.mPoints);
    	mGraph.setData(mState.mPoints);
    	mTriText = new TriText({
    		:width => w,
    		:height => th,
    		:locX => 0,
    		:locY => ty,
    		:color => 0xFFFFFF,
    		:suffix => true,
    		:text => "computing"
    	});
    	setLayout([mGraph, mTriText]);
    }
    
    function onShow() {
		WatchUi.animate(mGraph, :scale, WatchUi.ANIM_TYPE_EASE_OUT, 0, 1, 0.2, method(:onAnimateEnd));
    }
    function onAnimateEnd() {
    	mGraph.mShowExtremums = true;
    	requestUpdate();
    }
    
    function getPredictions() {
    	var result = new Result(mState);
		result.predictCharged();
		result.predictWindow();
		var predictions = [result.chargedDuration(), (result.windowSpeed != null)? result.windowSpeed * 3600: null];
		var texts = [["since", "charged", true], ["over last", "30 min", false]];
		var percent = null;
		var text = [null, null];
		
		var i = 0;
		for (var j = mMode; i < 2; j=(j + 1) % 2) {
			i++;
			if (predictions[j] != null) {
				percent = predictions[j];
				text = texts[j];
				break;
			}
		}
		return [percent, text[0], text[1], text[2]];  
    }
    
    function drawPredictions(dc) {
    	dc.setColor(0x00AAFF, 0x00AAFF);
    	dc.fillRectangle(0, 0, mTriText.width, mTriText.height);
		var predictions = getPredictions();
		var stats = System.getSystemStats();
    	//log.debug("drawPredictions", predictions[0]);
		if (predictions[0] != null) {
			if (predictions[3]) {
				mTriText.value = formatInterval(predictions[0]);				
			} else { 
				mTriText.value = formatPercent(predictions[0]);				
			}
			mTriText.title = predictions[1];
			mTriText.desc = predictions[2];
			
		} else {
			mTriText.value = null;
			if (stats.charging) {
				mTriText.text = "charging...";
			} else {
				mTriText.text = "computing...";
			}
		}
		mTriText.draw(dc);	
    }
	
	function onUpdate(dc) {
		dc.setColor(0xFFFFFF, 0x000000);
		dc.setPenWidth(1);
		dc.clear();
		
		drawPredictions(dc);
		
		mGraph.draw(dc);

		dc.fillPolygon([[mx, my + 5], [mx + 5, my], [mx - 5, my]]);
		
		dc.drawText(
			mx, my-offset, 
			0, // FONT_XTINY
			formatInterval(mGraph.interval), 
			5 // TEXT_JUSTIFY_CENTER | TEXT_JUSTIFY_VCENTER
		);
	}
	
	
    function updateState(state) {
    	mState = state;
    	mGraph.setData(mState.mPoints);
    }
    
    function nextMode() {
    	mMode = (mMode + 1) % 2;
    	requestUpdate();
    }
}


class GraphPageBehaviorDelegate extends WatchUi.BehaviorDelegate {
	var mView;
	//var log;
	var handleSelect;

    function initialize(view) {
        BehaviorDelegate.initialize();
        //log = new Log("GraphPageBehaviorDelegate");
        mView = view;
        var s = System.getDeviceSettings();
        handleSelect = !s.isTouchScreen;
    }
    
    function onBack() {
		//log.msg("onBack");
        popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
    
    function onNextPage() {
    	//log.msg("onNextPage");
		var app = Application.getApp();
		var infoPage = new InfoPage(app.mState);
		switchToView(infoPage, new InfoPageBehaviorDelegate(infoPage), WatchUi.SLIDE_UP);    
	}

	function onSelect() {
		if (handleSelect) {
			//log.msg("onSelect");
			mView.nextMode();
		}
		return handleSelect;
    }
    
    function onTap(clickEvent) {
    	var coords = clickEvent.getCoordinates();
    	var type = clickEvent.getType();
    	//log.debug("onTap", [coords, type]);
    	if (type == WatchUi.CLICK_TYPE_TAP && coords[1] <= 80) {
	    	mView.nextMode();
    	}	
    }
}


(:test)
function testGraphPageSmoke(logger) {
	var app = Application.getApp();
	var page = new GraphPage(app.mState);
	var dc = assertViewDraw(logger, page);
	logger.debug("onAnimateEnd");
	page.onAnimateEnd();
	return true;
}

(:test)
function testGraphPageEmptyData(logger) {
	var app = Application.getApp();
	var page = new GraphPage(app.mState);
	var ts = Time.now().value();
	app.mState.handleMeasurements(ts, 75.5, true);
	assertViewDraw(logger, page);
	return true;
}
