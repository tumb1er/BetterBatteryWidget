using Toybox.Lang;
using Toybox.Time;
using Toybox.WatchUi;


/**
Shows debug data in text
*/
class InfoPage extends WatchUi.View {
	var mState;

    function initialize(state) {
    	View.initialize();
		mState = state;
	}
	
	function drawCharged(dc, ts, percent, y) {
		ts = formatTimestamp(ts);
		
		var data = Lang.format("Charged to $1$%\n$2$", [percent.format("%.2f"), ts]);
		
    	dc.drawText(120, y, 
    			Graphics.FONT_XTINY, 
				data,
				Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		return y + 40;
	}
	
	function drawPredict(dc, tag, speed, remaining, y) {
		var data = Lang.format("$1$: $2$ ($3$ %/h)", [
			tag,
			formatInterval(remaining),
			(speed * 3600.0).format("%.1f")
		]);
		
    	dc.drawText(120, y, 
    			Graphics.FONT_TINY, 
				data,
				Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		return y + 30;
	}
	
	function onUpdate(dc) {
    	dc.setColor(0,0);
    	dc.clear();
    	dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
	
		var result = new Result(mState);
		result.predictCharged();
		result.predictWindow();
		var y = 40;
		if (result.chargedTs != null) {
			y = drawCharged(dc, result.chargedTs, result.chargedPercent, y);
		}
		if (result.chargedSpeed != null) {
			y = drawPredict(dc, "C", result.chargedSpeed, result.chargedPredict, y);
		}
		if (result.windowSpeed != null) {
			y = drawPredict(dc, "I", result.windowSpeed, result.windowPredict, y);
		}
    	for (var i=0; i<mState.mData.size(); i++) {
    		var item = mState.mData[i];
    		var ts = new Time.Moment(item[0]);
    		var value = item[1];
    		
	    	dc.drawText(120, y, 
	    			Graphics.FONT_XTINY, 
					Lang.format("$1$ -> $2$", 
						[
							formatTime(ts), 
							value.format("%.2f")
						]),
					Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    		y += 20;
    	}
    	
		dc.fillPolygon([[120, 5], [125, 10], [115, 10]]);    		
	}
}

class InfoPageInputDelegate extends WatchUi.InputDelegate {

    function initialize() {
        InputDelegate.initialize();
    }
    
    function onBack() {
		log("InfoPageInputDelegate.onBack", null);
        popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
    
    function onSwipe(swipeEvent) {
		log("InfoPageInputDelegate.onSwipe", swipeEvent);
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
   
}