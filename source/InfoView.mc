using Toybox.Lang;
using Toybox.Time;
using Toybox.WatchUi;


/**
Shows debug data in text
*/
class InfoView extends WatchUi.View {
	var mState;

    function initialize() {
    	View.initialize();
		mState = new State(null);
	}
	
	function drawCharged(dc, ts, percent, y) {
		ts = Time.Gregorian.info(new Time.Moment(ts), Time.FORMAT_MEDIUM);
		ts = Lang.format("$1$ $2$ $3$ $4$:$5$:$6$", [
			ts.day,
			ts.month,
			ts.year,
			ts.hour.format("%02d"),
			ts.min.format("%02d"),
			ts.sec.format("%02d")
		]);
		
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
	}
}

class InfoViewInputDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    function onBack() {
		log("InfoViewInputDelegate.onBack", null);
        popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}