using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Math;


class GaugeDrawable extends WatchUi.Drawable {
	var mArcs;
	var mText;
	var mIcon;
	var value = 0;
	var color = Graphics.COLOR_WHITE;
	
	function initArc(arc, cx, cy, start, end) {
		arc.put(:cx, cx);
		arc.put(:cy, cy);
		arc.put(:startAngle, start);
		arc.put(:endAngle, end);
		return new GaugeArc(arc);
	}
	
	function initialize(params) {
		Drawable.initialize(params);
		var w = params.get(:width);
		var h = params.get(:height);
		color = params.get(:color);
		var arc = {
			:pen => 16,
			:radius => w / 2 - 8,
			:color => color
		};
		mArcs = [
			initArc(arc, w/2-1, w/2,   600, 540),
			initArc(arc, w/2-1, w/2-1, 540, 450),
			initArc(arc, w/2,   w/2-1, 450, 360),
			initArc(arc, w/2,   w/2,   360, 300)
		];		
	}
	
	function draw(dc) {
		for (var i = 0; i < mArcs.size(); i++) {
			var arc = mArcs[i];
			arc.value = 600 - 3 * value;
			arc.color = color;
			arc.draw(dc);
		}
	}
}