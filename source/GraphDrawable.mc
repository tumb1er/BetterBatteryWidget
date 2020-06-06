using Toybox.WatchUi;


function interpolate(min_from, max_from, current, min_to, max_to) {
	var fraction = 0.5;
	if (min_from != max_from) {
		fraction = (current - min_from).toDouble() / (max_from - min_from).toDouble();
	}
	var result = (min_to + (max_to - min_to).toDouble() * fraction);
	return result;
	 
}


class GraphDrawable extends WatchUi.Drawable {
	var w, h, x, y; // coordinates
	var border, foreground, background, shade; // colors
	var tick = 5;
	var mPoints, mCoords, mData;
	var interval; // data interval
	var mExtremums; // min/max points
	var start, end; // x axis margins
	var scale; // y scale for animation
	var mShowExtremums; // show extremums flag
	//var log;
			
	function initialize(params) {
		Drawable.initialize(params);
		//log = new Log("GraphDrawable");
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
	
	public function setData(data) {
		//log.debug("setData", data.size());
		
		// computing bounds for graph data
		end = data[data.size() - 1][0];
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
	
	private function extremums(data) {
		if (data.size() < 2) {
			//log.msg("not enough extremums points");
			return null;
		}
		var minX = null, maxX = null;
		var minY = null, maxY = null;
		for (var i = 0; i < data.size(); i++) {
			var ts = data[i][0];
			var value = data[i][1]; 
			if (ts < start) {
				// Пропускаем точки, находящиеся левее границы графика
				continue;
			}
			if (minX == null || maxX == null) {
				// Если есть точки левее графика, интерполируем их.
				if (i == 0) {
					minX = ts; minY = value;
					maxX = ts; maxY = value;
				} else {
					value = interpolate(data[i - 1][0], ts, start, data[i - 1][1], value);
					minX = start; minY = value;
					maxX = start; maxY = value;
				}
				continue;
			}
			if (minY > value) {minX = ts; minY = value;}
			if (maxY < value) {maxX = ts; maxY = value;}
		}
		if (minY == maxY) {
			//log.msg("extermums: minY == maxY");
			return [data[data.size() - 1][0], minY, maxX, maxY];
		}
		return [minX, minY, maxX, maxY];		
	}
	
	private function points(data) {
		if (mExtremums == null) {
			return null;
		}
		var minY = mExtremums[1];
		var maxY = mExtremums[3];
		var px = null, py = null;
		var prevTs = null, prevValue = null;
		var left = x, right = x + w - 1;
//		var top = y, bottom = y + h - 1;
		var top = h - 2, bottom = 0;
		var points = [];
		
		
		for (var i = 0; i < data.size(); i++) {
			var ts = data[i][0];
			var value = data[i][1];
			if (ts < start) {
				// skip points out of left bound
				prevTs = ts;
				prevValue = value;
				continue;
			}
			if (px == null || py == null) {
				if (i == 0) {
					// initial points
					px = interpolate(start, end, ts, left, right);
					py = interpolate(minY, maxY, value, bottom, top);
				} else {
					// interpolate point at left graph border
					px = x;
					var value = interpolate(prevTs, ts, start, prevValue, value);
					py = interpolate(minY, maxY, value, bottom, top);
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
		dc.setColor(shade, background);
		var s = mData.size();
		if (s < 2) {
			return;
		}
		var shadeCoords = [];
		var b = y + h - 2;
		var p;
		for (var i = 0; i < s; i++) {
			p = mData[i];
			shadeCoords.add([p[0], b - scale * p[1]]);
		}
		p = mData[s - 1];
		shadeCoords.add([p[0], b]);
		p = mData[0];
		shadeCoords.add([p[0], b]);
		dc.fillPolygon(shadeCoords);
		
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