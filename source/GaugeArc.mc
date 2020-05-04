class GaugeArc {
	var cx, cy, r, p, start, end, color, value;
	var bx, by, bs, be, br, ballStart = null;
	
	function initBall(a, isStart) {
		ballStart = isStart;
		if (isStart) {
			bs = a - 180;
			be = a; 
		} else {
			bs = a;
			be = a + 180;
		}
		
		a = Math.toRadians(a);
		bx = Math.round(cx + r * Math.cos(a));
		by = Math.round(cy - r * Math.sin(a));
	}
	
	function initialize(params) {
		cx = params.get(:cx);
		cy = params.get(:cy);
		r = params.get(:radius);
		p = params.get(:pen);
		start = params.get(:startAngle);
		end = params.get(:endAngle);
		color = params.get(:color);
		value = params.get(:value);
		
		if (start % 90 != 0) {
			initBall(start, true);
		}
		if (end % 90 != 0) {
			initBall(end, false);
		}
		br = p / 2 - 1;
	}
	
	function draw(dc) {
		dc.setColor(0xFFFFFF, -1); // Graphics.COLOR_TRANSPARENT
		dc.setPenWidth(1);
		dc.drawArc(cx, cy, r + (p / 2 - 1), 1, start, end); // Graphics.ARC_CLOCKWISE
		dc.drawArc(cx, cy, r - (p / 2 - 1), 1, start, end);
		if (ballStart != null) {
			dc.drawArc(bx, by, br, 1, bs, be);
		}
		if (value < start) {
			dc.setPenWidth(p);
			dc.setColor(color, -1);
			if (ballStart) {
				dc.fillCircle(bx, by, br);
			}
			dc.drawArc(cx, cy, r, 1, start, (value > end)? value: end);
			if (value >= end) {
				var a = Math.toRadians(value);
				var vx = Math.round(cx + r * Math.cos(a));
				var vy = Math.round(cy - r * Math.sin(a));
				dc.fillCircle(vx, vy, br);
			}
		}
	}
}