using Toybox.Lang;
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

    function initialize(state) {
    	View.initialize();
		mState = state;
	}
	
    function onLayout( dc ) {
    	var params = {
    		:width => 240,
    		:height => 30,
    		:locX => 0,
    		:locY => 30,
    		:color => Graphics.COLOR_WHITE,
    		:title => "charged",
    		:suffix => true,
    		:text => "no charge date"
    	};
    	mChargedText = new TriText(params);
    	params.put(:title, "last 30m");
    	params.put(:locY, 70);
    	params.put(:text, "no interval data");
    	mIntervalText = new TriText(params);
    	params.put(:title, "mark");
    	params.put(:locY, 110);
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
    	dc.drawText(120, 40, 
    			Graphics.FONT_XTINY, 
				data,
				Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
	}
	
	function drawMark(dc) {
		var mark = mState.mMark;
		var percent = "Mark";
		var marked = "press to put mark";
		if (mark != null) {
			marked = formatTimestamp(mark[0]);
			percent = Lang.format("Marked $1$", [formatPercent(mark[1])]);
		}
		dc.setColor(Graphics.COLOR_PINK, Graphics.COLOR_PINK);
    	dc.fillRectangle(0, 160, 240, 240);
		dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
		dc.drawText(120, 170, 
			Graphics.FONT_MEDIUM,
			percent,
			Graphics.TEXT_JUSTIFY_CENTER);
		dc.drawText(120, 200,
			Graphics.FONT_XTINY,
			marked,
			Graphics.TEXT_JUSTIFY_CENTER);
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
		// drawCharged(dc, result.chargedTs, result.chargedPercent, stats.charging);
		dc.fillPolygon([[120, 5], [125, 10], [115, 10]]);   
		drawMark(dc); 	
	}
	
	function mark() {
		mState.mark();
		mState.save();
		requestUpdate();
	}
}

class InfoPageInputDelegate extends WatchUi.InputDelegate {
	var mView;
	var log;

    function initialize(view) {
        InputDelegate.initialize();
        log = new Log("InfoPageInputDelegate");
        mView = view;
    }
    
    function onBack() {
		log.msg("onBack");
        popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
    
    function onSwipe(swipeEvent) {
		log.debug("InfoPageInputDelegate.onSwipe", swipeEvent);
		if (swipeEvent.getDirection() == WatchUi.SWIPE_DOWN) {
			var app = Application.getApp();
			var view = new GraphPage(app.mState);
			switchToView(view, new GraphPageInputDelegate(view), WatchUi.SLIDE_DOWN);    
		}
		if (swipeEvent.getDirection() == WatchUi.SWIPE_RIGHT) {
			popView(WatchUi.SLIDE_RIGHT);
		}		
		return true;
    }
       
    function onTap(clickEvent) {
    	var coords = clickEvent.getCoordinates();
    	var type = clickEvent.getType();
    	log.debug("InfoPageInputDelegate.onTap", [coords, type]);
    	if (type == WatchUi.CLICK_TYPE_TAP && coords[1] >= 160) {
	    	mView.mark();
    	}	
    }
   
}