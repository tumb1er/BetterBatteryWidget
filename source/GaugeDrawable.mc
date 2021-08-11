using Toybox.Lang;
using Toybox.WatchUi;


class GaugeDrawable extends WatchUi.Drawable {
	var mArcs as Lang.Array<GaugeArc>;
	var mText;
	var mIcon;
	var value = 0;
	var color = 0xFFFFFF;
	
	function initArc(arc, cx, cy, start, end) {
		arc.put(:cx, cx);
		arc.put(:cy, cy);
		arc.put(:startAngle, start);
		arc.put(:endAngle, end);
		return new GaugeArc(arc);
	}
	
	function initialize(params) {
		Drawable.initialize(params);
		var r = params.get(:radius);
		var r1 = r - 1;
		color = params.get(:color);
		var pen = params.get(:pen);
		var arc = {
			:pen => pen,
			:radius => r - pen / 2,
			:color => color
		};
		mArcs = [
			initArc(arc, r1, r,  600, 540),
			initArc(arc, r1, r1, 540, 450),
			initArc(arc, r,  r1, 450, 360),
			initArc(arc, r,  r,  360, 300)
		] as Lang.Array<GaugeArc>;		
	}
	
	function draw(dc) {
		var v = 600 - 3 * value;
		for (var i = 0; i < mArcs.size(); i++) {
			var arc = mArcs[i] as GaugeArc;
			arc.value = v;
			arc.color = color;
			arc.draw(dc);
		}
	}
}