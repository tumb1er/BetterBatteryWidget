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
	
	function onUpdate(dc) {
    	dc.setColor(0,0);
    	dc.clear();
    	dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
    	var y = 80;
    	for (var i=0; i<mState.mData.size(); i++) {
    		var item = mState.mData[i];
    		var ts = new Time.Moment(item[0]);
    		var value = item[1];
    		
	    	dc.drawText(120, y, 
	    			Graphics.FONT_SMALL, 
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
        popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}