using Toybox.Application;
using Toybox.Graphics;
import Toybox.Lang;
using Toybox.System;
using Toybox.Time;
import Toybox.Test;
using Toybox.WatchUi;

/**
Shows discharge graph
*/
class GraphPage extends WatchUi.View {
	var mState as State;
	var mTriText as TriText?;
	var mGraph as GraphDrawable?;

	var mMode as Number;
	var mGraphDuration as Number;
	var mGraphMode as Number;
	// var log as Log;
	var mx as Number = 0, my as Number = 0, offset as Number = 0;

    public function initialize(state as State) {
    	View.initialize();
		// log = new Log("GraphPage");
		mState = state;
		mMode = 0;
		var app = getApp();
		mGraphDuration = app.getGraphDuration();
		mGraphMode = app.getGraphMode();
	}
	
    public function onLayout(dc as Graphics.Dc ) as Void {
    	var w = dc.getWidth();
    	var h = dc.getHeight();
    	
    	var RS = Rez.Strings;
		var RJ = Rez.JsonData;
    	
    	var gw = loadNumberFromStringResource(RS.GraphWidth);
    	var gh = loadNumberFromStringResource(RS.GraphHeight);
    	var th = loadNumberFromStringResource(RS.GraphStatusHeight);
    	var ty = loadNumberFromStringResource(RS.GraphStatusY);
    	offset = loadNumberFromStringResource(RS.GraphIntervalOffset);
    	mx = w / 2;
    	my = h - 10;
    	var graphMargin = (w - gw) / 2;

    	var graph = new GraphDrawable({
	    	:width => gw,
	    	:height => gh,
	    	:x => graphMargin,
	    	:y => h / 2 - graphMargin,
	    	:border => Graphics.COLOR_WHITE,
	    	:foreground => Graphics.COLOR_RED,
	    	:background => Graphics.COLOR_TRANSPARENT,
	    	:shade => (mGraphMode == 1)? Graphics.COLOR_LT_GRAY: null,
	    	:interval => mGraphDuration as Number,
	    	:scale => 0.0
    	});
    	graph.mShowExtremums = false;
    	//log.debug("setData", mState.mPoints);
    	graph.setData(mState.getPointsIterator());

		mGraph = graph;
    	mTriText = new TriText({
    		:width => w,
    		:height => th,
    		:locX => 0,
    		:locY => ty,
    		:color => Graphics.COLOR_WHITE,
    		:suffix => true,
    		:text => loadResource(Rez.Strings.Computing) as String
    	});
    	setLayout([mGraph, mTriText] as Array<GraphDrawable or TriText>);
    }
    
    public function onShow() as Void {
		WatchUi.animate(mGraph, :scale, WatchUi.ANIM_TYPE_EASE_OUT, 0, 1, 0.2, method(:onAnimateEnd));
    }

    public function onAnimateEnd() as Void {
		var g = (mGraph as GraphDrawable);
    	g.mShowExtremums = true;
    	requestUpdate();
    }
    
    private function getPredictions() as Array<Float or Null or Array<String or Null or Boolean> > {
    	var result = new Result(mState);
		result.predictCharged();
		result.predictWindow();
		var RS = Rez.Strings;
		var windowPredict = result.getWindowPredict();
		var windowSpeed = (windowPredict != null)? windowPredict.getValue() * 3600: null;
		var predictions = [result.chargedDuration(), windowSpeed] as Array<Float>;
		var texts = [[loadResource(RS.Since), loadResource(RS.Charged), true], 
					 [loadResource(RS.OverLast), loadResource(RS.Minutes30), false]];
		var percent = null;
		var text = [null, null, false] as Array<String or Null or Boolean>;
		
		var i = 0;
		for (var j = mMode; i < 2; j=(j + 1) % 2) {
			i++;
			if (predictions[j] != null) {
				percent = predictions[j];
				text = texts[j] as Array<String or Null or Boolean>;
				break;
			}
		}
		return [percent, text[0], text[1], text[2]] as Array<Float or Null or Array<String or Null or Boolean> >;  
    }
    
    private function drawPredictions(dc as Graphics.Dc) as Void {
    	dc.setColor(0x00AAFF, 0x00AAFF);
		var tt = mTriText as TriText;
    	dc.fillRectangle(0, 0, tt.width, tt.height);
		var predictions = getPredictions();
		var stats = System.getSystemStats();
    	//log.debug("drawPredictions", predictions[0]);
		if (predictions[0] != null) {
			if (predictions[3] as Boolean) {
				tt.value = formatInterval(predictions[0] as Number);				
			} else { 
				tt.value = formatPercent(predictions[0]);				
			}
			tt.title = predictions[1] as String;
			tt.desc = predictions[2] as String;
			
		} else {
			tt.value = "";
			if (stats.charging) {
				tt.text = loadResource(Rez.Strings.ChargingDot) as String;
			} else {
				tt.text = loadResource(Rez.Strings.ComputingDot) as String;
			}
		}
		tt.draw(dc);	
    }
	
	public function onUpdate(dc as Graphics.Dc) as Void {
		dc.setColor(0xFFFFFF, 0x000000);
		dc.setPenWidth(1);
		dc.clear();
		
		drawPredictions(dc);
		var g = mGraph as GraphDrawable;
		g.draw(dc);
		dc.setColor(0xFFFFFF, 0x000000);

		dc.fillPolygon([
			[mx, my + 5] as Array<Number>, 
			[mx + 5, my] as Array<Number>, 
			[mx - 5, my] as Array<Number>
		] as Array<Array<Number> >);
		
		dc.drawText(
			mx, my-offset, 
			Graphics.FONT_XTINY,
			formatInterval(g.interval), 
			Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
		);
	}
	
	
    private function updateState(state as State) as Void {
    	mState = state;
		var g = mGraph as GraphDrawable;
    	g.setData(state.getPointsIterator());
    }
    
    public function nextMode() as Void {
    	mMode = (mMode + 1) % 2;
    	requestUpdate();
    }
}


class GraphPageBehaviorDelegate extends WatchUi.InputDelegate {
	var mView as GraphPage;
	//var log;

    public function initialize(view as GraphPage) {
        InputDelegate.initialize();
        //log = new Log("GraphPageBehaviorDelegate");
        mView = view;
        var s = System.getDeviceSettings();
    }
    
    public function onBack() as Boolean {
		//log.msg("onBack");
        popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
    
    public function onNextPage() as Boolean {
    	//log.msg("onNextPage");
		var app = getApp();
		var infoPage = new InfoPage(app.mState);
		switchToView(infoPage, new InfoPageBehaviorDelegate(infoPage), WatchUi.SLIDE_UP);    
		return true;
	}

	public function onSelect() as Boolean {
		//log.msg("onSelect");
		mView.nextMode();
		return true;
    }
    
    public function onTap(clickEvent) as Boolean {
    	var coords = clickEvent.getCoordinates();
    	var type = clickEvent.getType();
    	//log.debug("onTap", [coords, type]);
    	if (type == WatchUi.CLICK_TYPE_TAP && coords[1] <= 80) {
    		//log.msg("nextMode()");
	    	mView.nextMode();
    	}
    	return true;
    }
    
        
    public function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
    	//log.debug("onKey", keyEvent.getKey());
    	switch(keyEvent.getKey()) {
			case WatchUi.KEY_ENTER:
				return onSelect();
			case WatchUi.KEY_DOWN:
				return onNextPage();
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
   			case WatchUi.SWIPE_UP:
   				return onNextPage();
			case WatchUi.SWIPE_RIGHT:
   				return onBack();
   			default:
   				return false;
   		}
   	}
}


(:test)
function testGraphPageSmoke(logger as Logger) as Boolean {
	var app = getApp();
	var page = new GraphPage(app.getState());
	var dc = assertViewDraw(logger, page);
	logger.debug("onAnimateEnd");
	page.onAnimateEnd();
	return true;
}

(:test)
function testGraphPageEmptyData(logger as Logger) as Boolean {
	var app = getApp();
	var page = new GraphPage(app.getState());
	var ts = Time.now().value();
	app.getState().handleMeasurements(ts, 75.5, true);
	assertViewDraw(logger, page);
	return true;
}
