using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

const gw = 200, gh = 80, gcx=120, gcy=140, top=90, tick=5;



/**
Shows discharge graph
*/
class GraphPage extends WatchUi.View {
	var mState;
	var mMode;
	var mGraph;

    function initialize(state) {
    	View.initialize();
		mState = state;
		mMode = 0;
	}
	
    function onLayout( dc ) {
    	mGraph = new GraphDrawable({
	    	:width => 200,
	    	:height => 80,
	    	:x => 20,
	    	:y => 100,
	    	:border => Graphics.COLOR_WHITE,
	    	:background => Graphics.COLOR_TRANSPARENT,
	    	:foreground => Graphics.COLOR_RED,
	    	:interval => 3600 * 4,
	    	:scale => 0
    	});
    	mGraph.mShowExtremums = false;
    	mGraph.setData(mState.mPoints);
    	setLayout([mGraph]);
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
		var predictions = [result.chargedSpeed, result.windowSpeed];
		var texts = [["since", "charged"], ["over last", "30 min"]];
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
		return [percent, text[0], text[1]];  
    }
    
    function drawPredictions(dc) {
    	dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
    	dc.fillRectangle(0, 0, 240, 80);
		var predictions = getPredictions();				
		if (predictions[0] != null) {
			var percent = formatPercent(predictions[0] * 3600);
			dc.setColor(colorize(System.getSystemStats().battery), Graphics.COLOR_TRANSPARENT);
			dc.drawText(gcx-20, top-60, Graphics.FONT_XTINY, predictions[1], Graphics.TEXT_JUSTIFY_RIGHT);
			dc.drawText(gcx-20, top-45, Graphics.FONT_XTINY, predictions[2], Graphics.TEXT_JUSTIFY_RIGHT);
			dc.drawText(gcx-10, top-66, Graphics.FONT_NUMBER_MEDIUM, percent, Graphics.TEXT_JUSTIFY_LEFT);
		}
    }
	
	function onUpdate(dc) {
		dc.setColor(0xFFFFFF, 0x000000);
		dc.setPenWidth(1);
		dc.clear();
		
		drawPredictions(dc);
		
		mGraph.draw(dc);

		dc.fillPolygon([[120, 235], [125, 230], [115, 230]]);
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


class GraphPageInputDelegate extends WatchUi.InputDelegate {
	var mView;

    function initialize(view) {
        InputDelegate.initialize();
        mView = view;
    }
    
    function onBack() {
		log("GraphPageInputDelegate.onBack", null);
        popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
    
    function onSwipe(swipeEvent) {
		log("GraphPageInputDelegate.onSwipe", swipeEvent);
		if (swipeEvent.getDirection() == WatchUi.SWIPE_UP) {
			var app = Application.getApp();
			switchToView(new InfoPage(app.mState), new InfoPageInputDelegate(), WatchUi.SLIDE_UP);    
		}
		if (swipeEvent.getDirection() == WatchUi.SWIPE_RIGHT) {
			popView(WatchUi.SLIDE_RIGHT);
		}
		return true;
    }
    
    function onTap(clickEvent) {
    	log("GraphPageInputDelegate.onTap", clickEvent);
    	mView.nextMode();
    	
    }
}