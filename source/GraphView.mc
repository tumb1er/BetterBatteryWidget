using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

const gw = 200, gh = 80, gcx=120, gcy=140, tick=5;



/**
Shows debug data in text
*/
class GraphView extends WatchUi.View {
	var mState;

    function initialize(state) {
    	View.initialize();
		mState = state;
	}
	
	function getTextJustify(x) {
		if (x > gcx + gw/4) {
			return Graphics.TEXT_JUSTIFY_RIGHT;
		}
		if (x < gcx - gw/4) {
			return Graphics.TEXT_JUSTIFY_LEFT;
		}
		return Graphics.TEXT_JUSTIFY_CENTER;
	}
	
	function onUpdate(dc) {
		dc.setColor(0xFFFFFF, 0x000000);
		dc.setPenWidth(1);
		dc.clear();
		
		// frame
		var left = gcx - gw/2;
		var right = gcx + gw/2;
		var bottom = gcy + gh/2;
		var top = gcy - gh/2;
		dc.drawLine(left, bottom, right, bottom);
		dc.drawLine(left, bottom, left, top);
		dc.drawLine(right, bottom, right, top);
		// ticks
		for (var i = -1; i <= 1; i++) {
			dc.drawLine(gcx + i * gw/4, bottom, gcx + i * gw/4, bottom + 10);
			dc.drawLine(left, gcy + i * gh/4, left - tick, gcy + i * gh/4);
			dc.drawLine(right, gcy + i * gh/4, right + tick, gcy + i * gh/4);
		}
		dc.drawText(gcx, bottom + 10, Graphics.FONT_SYSTEM_TINY, "Last 4 Hours", Graphics.TEXT_JUSTIFY_CENTER);
		
		// predictions
		var result = new Result(mState);
		result.predictCharged();
		result.predictWindow();
		
		if (result.windowPredict != null) {
			colorize(dc, System.getSystemStats().battery);
			dc.drawText(gcx-5, top-80, Graphics.FONT_XTINY, "since", Graphics.TEXT_JUSTIFY_RIGHT);
			dc.drawText(gcx-5, top-65, Graphics.FONT_XTINY, "charged", Graphics.TEXT_JUSTIFY_RIGHT);
			dc.drawText(gcx+5, top-86, Graphics.FONT_NUMBER_MEDIUM, formatPercent(result.windowSpeed * 3600), Graphics.TEXT_JUSTIFY_LEFT);
		}
		if (result.chargedPredict != null) {
			dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
			dc.drawText(gcx-5, top-40, Graphics.FONT_XTINY, "over last", Graphics.TEXT_JUSTIFY_RIGHT);
			dc.drawText(gcx-5, top-25, Graphics.FONT_XTINY, "30 min", Graphics.TEXT_JUSTIFY_RIGHT);
			dc.drawText(gcx+5, top-46, Graphics.FONT_NUMBER_MEDIUM, formatPercent(result.chargedSpeed * 3600), Graphics.TEXT_JUSTIFY_LEFT);
		}
		dc.setColor(0xFF0000, 0x000000);
		
		// graph 4 hours
		var points = mState.mPoints;
		log("GraphView.onUpdate points", points.size());
		if (points.size() < 2) {
			return;
		}
		var min = points[0], max=points[0];
		var end = points[points.size() - 1][0];
		var start = end - 3600 * 4;
		for (var i = 1; i < points.size(); i++) {
			var value = points[i][1];
			if (min[0] > value) {min = points[i];}
			if (max[0] < value) {max = points[i];}
		}
		if (min[1] == max[1]) {
			log("GraphView.onUpdate min=max", min[1]);
			return;
		}
		
		// Graph
		var x = interpolate(start, end, points[0][0], left, right - 1);
		var y = interpolate(min[1], max[1], points[0][1], bottom, top);
		for (var i = 1; i < points.size(); i++) {
			var nx = interpolate(start, end, points[i][0], left, right - 1);
			var ny = interpolate(min[1], max[1], points[i][1], bottom, top);
			dc.drawLine(x,y, nx,ny);
			x = nx;
			y = ny;
		}
		
		dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
		// Min point
		x = interpolate(start, end, min[0], left, right - 1);
		y = bottom;
		
		dc.fillPolygon([[x,y], [x+5, y-5], [x-5, y-5]]);
		dc.drawText(x, y - 25, Graphics.FONT_SYSTEM_XTINY, formatPercent(min[1]), getTextJustify(x));

		// Max point
		x = interpolate(start, end, max[0], left, right - 1);
		y = top;
		
		dc.fillPolygon([[x,y], [x+5, y+5], [x-5, y+5]]);
		dc.drawText(x, y + 5, Graphics.FONT_SYSTEM_XTINY, formatPercent(max[1]), getTextJustify(x));

	}
	
	function interpolate(min_from, max_from, current, min_to, max_to) {
		var fraction = (current - min_from).toDouble() / (max_from - min_from).toDouble();
		return (min_to + (max_to - min_to).toDouble() * fraction).toNumber(); 
	}
	
    function updateState(state) {
    	mState = state;
    }
}


class GraphViewInputDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    function onBack() {
		log("GraphViewInputDelegate.onBack", null);
        popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}