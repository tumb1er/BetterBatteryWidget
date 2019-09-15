using Toybox.Time;
using Toybox.WatchUi;


/**
Shows debug data in text
*/
class DebugView extends WatchUi.View {
	var mState;

    function initialize() {
    	View.initialize();
		mState = new State(null);
	}
	
	function onUpdate(dc) {
    	dc.setColor(0,0);
    	dc.clear();
    	dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
    	var y = 80;
    	for (var i=0; i<mState.mData.size(); i++) {
    		var item = mState.mData[i];
    		var ts = new Time.Moment(item[0]);
    		ts = Time.Gregorian.info(ts, Time.FORMAT_MEDIUM);
    		var value = item[1];
    		
	    	dc.drawText(120, y, 
	    			Graphics.FONT_SMALL, 
					Lang.format("$1$:$2$:$3$ -> $4$", 
						[
							ts.hour.format("%02d"), 
							ts.min.format("%02d"), 
							ts.sec.format("%02d"), 
							value.format("%.2f")
						]),
					Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    		y += 20;
    	}	
	}
}