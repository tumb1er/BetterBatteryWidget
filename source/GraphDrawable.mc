import Toybox.Lang;
using Toybox.Graphics;
using Toybox.WatchUi;

typedef GraphParams as {
	:width as Number,
	:height as Number,
	:x as Number,
	:y as Number,
	:border as Graphics.ColorValue,
	:foreground as Graphics.ColorValue,
	:background as Graphics.ColorValue,
	:shade as Graphics.ColorValue?,
	:interval as Number,
	:scale as Float,
};


typedef GraphPoint as Array<Number>; // [x, y]
typedef GraphPoints as Array<GraphPoint>;


class GraphDrawable extends WatchUi.Drawable {
	var w as Number, h as Number, x as Number, y as Number; // coordinates
	var border as Graphics.ColorType, foreground as Graphics.ColorType, background as Graphics.ColorType, shade as Graphics.ColorType?; // colors
	var tick as Number = 5;
	var mData as StatePoints?;
	var interval as Number; // data interval
	var mExtremums as Array<Number or Float>?; // min/max points
	var start as Number = 0, end as Number = 0; // x axis margins
	var scale as Float; // y scale for animation
	var mShowExtremums as Boolean; // show extremums flag
	// var log as Log;
			
	public function initialize(params as GraphParams) {
		Drawable.initialize(params);
		// log = new Log("GraphDrawable");
		w = params.get(:width) as Number;
		h = params.get(:height) as Number;
		x = params.get(:x) as Number;
		y = params.get(:y) as Number;
		border = params.get(:border) as Graphics.ColorType;
		foreground = params.get(:foreground) as Graphics.ColorType;
		background = params.get(:background) as Graphics.ColorType;
		shade = params.get(:shade) as Graphics.ColorType?;
		interval = params.get(:interval) as Number;
		scale = params.get(:scale) as Float;
		mShowExtremums = true;
	}
	
	public function setData(data as PointsIterator) as Void {
		// log.debug("setData", data.size());
		
		// computing bounds for graph data
		end = (data.last() as BatteryPoint).getTS();
		start = end - interval;

		// get min/max coords
		mExtremums = extremums(data);
		// cleanup memory;
		mData = null;
		mData = points(data);
		// log.debug("setData extremums", mExtremums);
	}
	
	private function getTextJustify(tx as Number) as Graphics.TextJustification {
		if (tx > x + 3 * w / 4) {
			return Graphics.TEXT_JUSTIFY_RIGHT;
		}
		if (tx < x + w / 4) {
			return Graphics.TEXT_JUSTIFY_LEFT;
		}
		return Graphics.TEXT_JUSTIFY_CENTER;
	}
	
	
	public function draw(dc as Graphics.Dc) as Void {
		drawFrame(dc);		
		if (mExtremums != null) {
			if (shade != null) {
				drawGraphShade(dc);
			} else {
				drawGraphLine(dc);
			}
			if (mShowExtremums) {
				drawExtremums(dc);
			}
		}
	}
			
	private function drawFrame(dc as Graphics.Dc) as Void {
		dc.setColor(border, background);
		dc.drawRectangle(x, y, w, h);
		// ticks
		for (var i = 1; i <= 3; i++) {
			dc.drawLine(x + i * w/4, y + h, x + i * w/ 4, y + h + tick * 2);
			dc.drawLine(x, y + i * h/4, x - tick, y + i * h / 4);
			dc.drawLine(x + w, y + i * h/4, x + w + tick, y + i * h/4);
		}
	}
	
	private function extremums(data as PointsIterator) as Array<Float>? {
		if (data.size() < 2) {
			// log.msg("not enough extremums points");
			return null;
		}
		
		var minX = null, maxX = null;
		var minY = null, maxY = null;
		var point = null;
		var prev = null;
		
		data.start();
		while (true) {
			prev = point;
			point = data.next();
			if (point == null) {
				break;
			}
			point = point as BatteryPoint;
			var ts = point.getTS();
			var value = point.getValue(); 
			if (ts < start) {
				// Пропускаем точки, находящиеся левее границы графика
				continue;
			}
			if (minX == null || maxX == null) {
				// Если есть точки левее графика, интерполируем их.
				if (prev == null) {
					minX = ts; minY = value;
					maxX = ts; maxY = value;
				} else {
					value = interpolate((prev as BatteryPoint).getTS(), ts, start, (prev as BatteryPoint).getValue(), value);
					minX = start; minY = value;
					maxX = start; maxY = value;
				}
				continue;
			}
			minY = minY as Float;
			maxY = maxY as Float;
			if (minY > value) {minX = ts; minY = value;}
			if (maxY < value) {maxX = ts; maxY = value;}
		}
		if (minY == maxY) {
			// log.msg("extermums: minY == maxY");
			return [(data.last() as BatteryPoint).getTS(), minY, maxX, maxY] as Array<Float>?;
		}
		// log.debug("extremums", [minX, minY, maxX, maxY]);
		return [minX, minY, maxX, maxY] as Array<Float>?;		
	}
	
	private function points(data as PointsIterator) as GraphPoints? {
		if (mExtremums == null) {
			// log.msg("no extremums - no points");
			return null;
		}
		var minY = (mExtremums as Array<Float>)[1];
		var maxY = (mExtremums as Array<Float>)[3];
		var px = null, py = null;
		var prevTs = null, prevValue = null;
		var left = x, right = x + w - 2;
//		var top = y, bottom = y + h - 1;
		var top = h - 2, bottom = 0;
		var points = [];
		var point = null;
		var prev = null;
		var i = -1;
		data.start();
		while (true) {
			prev = point;
			point = data.next();
			// log.debug("point", point);
			i += 1;
			if (point == null) {
				// log.debug("points", [points, i]);
				break;
			}
			point = point as BatteryPoint;
			var ts = point.getTS();
			var value = point.getValue();
			if (ts < start) {
				// skip points out of left bound
				prevTs = ts;
				prevValue = value;
				// log.debug("continue", [ts, start]);
				continue;
			}
			if (px == null || py == null) {
				if (prev == null) {
					// initial points
					px = interpolate(start, end, ts, left, right);
					py = interpolate(minY, maxY, value, bottom, top);
				} else {
					// interpolate point at left graph border
					px = x;
					prevTs = prevTs as Number;
					prevValue = prevValue as Float;
					var v = interpolate(prevTs, ts, start, prevValue, value);
					py = interpolate(minY, maxY, v, bottom, top);
				}
				if (i == data.size() - 1) {
					// the only point withing graph boundaries, draw horizontal line
					return [
						[left, py.toNumber()] as GraphPoint, 
						[right, py.toNumber()] as GraphPoint
					] as GraphPoints;
				}
				points.add([px.toNumber(), py.toNumber()]);
				continue;
			}
			// Next points on graph
			var nx = interpolate(start, end, ts, left, right);
			var ny = interpolate(minY, maxY, value, bottom, top);
			px = px as Double;
			py = py as Double;
			points.add([px.toNumber(), py.toNumber()]);
//			dc.drawLine(px, py, nx, ny);
			px = nx;
			py = ny;
		}
		px = px as Double;
		py = py as Double;
		points.add([px.toNumber(), py.toNumber()]);
		return points as GraphPoints;
	}
	
	private function drawGraphLine(dc as Graphics.Dc) as Void {
		// log.msg("drawGraphLine");
		dc.setColor(foreground, background);
		var data = (mData as StatePoints);
		if (data.size() < 2) {
			return;
		}
		var p = data[0] as StatePoint;
		var b = y + h-2;
		for (var i = 1; i < data.size(); i++) {
			var n = data[i] as StatePoint;
			// Draw next line
			dc.drawLine(
				p[0] as Double, 
				(b - scale * p[1]) as Double, 
				n[0] as Double, 
				(b - scale * n[1]) as Double
			);
			p = n;
		}	
	}
	
	private function drawGraphShade(dc as Graphics.Dc) as Void {
		// log.msg("drawGraphShade");
		dc.setColor(shade, background);
		var data = mData as StatePoints;
		var s = data.size();
		if (s < 2) {
			// log.msg("skip draw, size too small");
			return;
		}
		var start = 0;
		var next = null;
		while (start < s) {
			// log.debug("start at", [start, s]);
			var shadeCoords = [] as GraphPoints;
			var b = y + h - 2;
			var p;
			for (var i = start; i < s && i < start + 60; i++) {
				p = data[i] as StatePoint;
				var px = p[0] as Number;
				var py = ((b - scale * p[1]) as Float).toNumber();
				shadeCoords.add([px, py] as GraphPoint);
				next = i;
			}
			// Add two points for drawing bottom line of polygon,
			// first bottom-right and then bottom-left point.
			p = data[next] as StatePoint;
			shadeCoords.add([p[0] as Number, b] as GraphPoint);
			p = data[start] as StatePoint;
			shadeCoords.add([p[0] as Number, b] as GraphPoint);
			// log.debug("fp", shadeCoords);
			dc.fillPolygon(shadeCoords);
			// We need to overlap points to exclude holes in graph, but for last iteration it leads to 
			// infinite loop. So we disable overlap for last iteration. 
			start = (next == start)? (next as Number) + 1: next;
		}
		// log.msg("done drawGraphShade");		
	}
	
	private function drawExtremums(dc as Graphics.Dc) as Void {
		var e = mExtremums as Array<Number or Float>;
		var minX = e[0] as Number;
		var minY = e[1] as Float;
		var maxX = e[2] as Number;
		var maxY = e[3] as Float;
		dc.setColor(border, background);
		var px = interpolate(start, end, minX, x, x + w - 1).toNumber();
		var py = ((minY == maxY)? y + h / 2: y + h).toNumber();
		
		dc.fillPolygon([
			[px, py] as GraphPoint, 
			[px + 5, py - 5] as GraphPoint, 
			[px - 5, py - 5] as GraphPoint
		] as GraphPoints);
		dc.drawText(px, py - 25, Graphics.FONT_SYSTEM_XTINY, formatPercent(minY), getTextJustify(px));
		
		px = interpolate(start, end, maxX, x, x + w - 1).toNumber();
		py = ((minY == maxY)? y + h / 2: y).toNumber();
		
		dc.fillPolygon([
			[px, py] as GraphPoint, 
			[px + 5, py + 5] as GraphPoint, 
			[px - 5, py + 5] as GraphPoint
		] as GraphPoints);
		dc.drawText(px, py + 5, Graphics.FONT_SYSTEM_XTINY, formatPercent(maxY), getTextJustify(px));
	}
}