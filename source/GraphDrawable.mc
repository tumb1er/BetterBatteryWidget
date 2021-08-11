import Toybox.Lang;
using Toybox.WatchUi;


function interpolate(min_from, max_from, current, min_to, max_to) as Double {
	var fraction = 0.5;
	if (min_from != max_from) {
		fraction = (current - min_from).toDouble() / (max_from - min_from).toDouble();
	}
	var result = 0.0d;
	try {
		 result = (min_to + (max_to - min_to).toDouble() * fraction);
		
	} catch (ex) {
		var log = new Log("interpolate");
		log.debug("interpolate: ", [min_from, max_from, current, min_to, max_to]);
		log.error("interpolate error", ex);
		throw ex;
	}
	return result;
}


class GraphDrawable extends WatchUi.Drawable {
	var w, h, x, y; // coordinates
	var border, foreground, background, shade; // colors
	var tick = 5;
	var mPoints, mCoords, mData as Array<Array<Number or Float> >?;
	var interval; // data interval
	var mExtremums as Array<Number or Float>?; // min/max points
	var start, end; // x axis margins
	var scale; // y scale for animation
	var mShowExtremums; // show extremums flag
	// var log;
			
	function initialize(params) {
		Drawable.initialize(params);
		// log = new Log("GraphDrawable");
		w = params.get(:width);
		h = params.get(:height);
		x = params.get(:x);
		y = params.get(:y);
		border = params.get(:border);
		foreground = params.get(:foreground);
		background = params.get(:background);
		shade = params.get(:shade);
		interval = params.get(:interval);
		scale = params.get(:scale);
		mShowExtremums = true;
	}
	
	public function setData(data as PointsIterator) {
		//log.debug("setData", data.size());
		
		// computing bounds for graph data
		end = data.last().getTS();
		start = end - interval;

		// get min/max coords
		mExtremums = extremums(data);
		// cleanup memory;
		mData = null;
		mData = points(data);
//
//
//		mPoints = new[data.size()];
//		mCoords = new[data.size()];
//		for (var i = 0; i < data.size(); i++) {
//			mCoords[i] = data[i][0];
//			mPoints[i] = data[i][1];
//		}
		//log.debug("setData extremums", mExtremums);
	}
	
	private function getTextJustify(tx) {
		if (tx > x + 3 * w / 4) {
			return 0; // Graphics.TEXT_JUSTIFY_RIGHT
		}
		if (tx < x + w / 4) {
			return 2; // Graphics.TEXT_JUSTIFY_LEFT
		}
		return 1; // Graphics.TEXT_JUSTIFY_CENTER
	}
	
	
	public function draw(dc) {
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
			
	private function drawFrame(dc) {
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
		
		data.reset();
		while (true) {
			prev = point;
			point = data.next();
			if (point == null) {
				break;
			}
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
			if (minY > value) {minX = ts; minY = value;}
			if (maxY < value) {maxX = ts; maxY = value;}
		}
		if (minY == maxY) {
			// log.msg("extermums: minY == maxY");
			return [data.last().getTS(), minY, maxX, maxY] as Array<Float>?;
		}
		// log.debug("extremums", [minX, minY, maxX, maxY]);
		return [minX, minY, maxX, maxY] as Array<Float>?;		
	}
	
	private function points(data as PointsIterator) {
		if (mExtremums == null) {
			// log.msg("no extremums - no points");
			return null;
		}
		var minY = mExtremums[1];
		var maxY = mExtremums[3];
		var px = null, py = null;
		var prevTs = null, prevValue = null;
		var left = x, right = x + w - 2;
//		var top = y, bottom = y + h - 1;
		var top = h - 2, bottom = 0;
		var points = [];
		var point = null;
		var prev = null;
		var i = -1;
		data.reset();
		while (true) {
			prev = point;
			point = data.next();
			// log.debug("point", point);
			i += 1;
			if (point == null) {
				// log.debug("points", points);
				break;
			}
			var ts = point.getTS();
			var value = point.getValue();
			if (ts < start) {
				// skip points out of left bound
				prevTs = ts;
				prevValue = value;
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
					var v = interpolate(prevTs, ts, start, prevValue, value);
					py = interpolate(minY, maxY, v, bottom, top);
				}
				if (i == data.size() - 1) {
					// the only point withing graph boundaries, draw horizontal line
					return [[left, py], [right, py]];
				}
				points.add([px.toNumber(), py.toNumber()]);
				continue;
			}
			// Next points on graph
			var nx = interpolate(start, end, ts, left, right);
			var ny = interpolate(minY, maxY, value, bottom, top);
			points.add([px.toNumber(), py.toNumber()]);
//			dc.drawLine(px, py, nx, ny);
			px = nx;
			py = ny;
		}
		points.add([px.toNumber(), py.toNumber()]);
		return points;
	}
	
	private function drawGraphLine(dc) {
		dc.setColor(foreground, background);
		if (mData.size() < 2) {
			return;
		}
		var p = mData[0];
		var b = y + h-2;
		for (var i = 1; i < mData.size(); i++) {
			var n = mData[i];
			if (p != null) {
				// Draw next line
				dc.drawLine(p[0], b - scale * p[1], n[0], b - scale * n[1]);
			}
			p = n;
		}	
	}
	
	private function drawGraphShade(dc) {
		//log.msg("drawGraphShade");
		dc.setColor(shade, background);
		var s = mData.size();
		if (s < 2) {
			//log.msg("skip draw, size too small");
			return;
		}
		var start = 0;
		var next = null;
		while (start < s) {
			//log.debug("start at", [start, s]);
			var shadeCoords = [];
			var b = y + h - 2;
			var p;
			for (var i = start; i < s && i < start + 60; i++) {
				p = mData[i];
				shadeCoords.add([p[0], b - scale * p[1]]);
				next = i;
			}
			// Add two points for drawing bottom line of polygon,
			// first bottom-right and then bottom-left point.
			p = mData[next];
			shadeCoords.add([p[0], b]);
			p = mData[start];
			shadeCoords.add([p[0], b]);
			dc.fillPolygon(shadeCoords);
			// We need to overlap points to exclude holes in graph, but for last iteration it leads to 
			// infinite loop. So we disable overlap for last iteration. 
			start = (next == start)? next + 1: next;
		}
		//log.msg("done drawGraphShade");		
	}
	
	private function drawExtremums(dc) {
		var minX = mExtremums[0];
		var minY = mExtremums[1];
		var maxX = mExtremums[2];
		var maxY = mExtremums[3];
		dc.setColor(border, background);
		var px = interpolate(start, end, minX, x, x + w - 1);
		var py = (minY == maxY)? y + h / 2: y + h;
		
		dc.fillPolygon([[px, py], [px + 5, py - 5], [px - 5, py - 5]]);
		dc.drawText(px, py - 25, 9, formatPercent(minY), getTextJustify(px));  // Graphics.FONT_SYSTEM_XTINY
		
		px = interpolate(start, end, maxX, x, x + w - 1);
		py = (minY == maxY)? y + h / 2: y;
		
		dc.fillPolygon([[px, py], [px + 5, py + 5], [px - 5, py + 5]]);
		dc.drawText(px, py + 5, 9, formatPercent(maxY), getTextJustify(px));  // Graphics.FONT_SYSTEM_XTINY
	}
}