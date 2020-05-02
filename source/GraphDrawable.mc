using Toybox.WatchUi;


function interpolate(min_from, max_from, current, min_to, max_to) {
	var fraction = (current - min_from).toDouble() / (max_from - min_from).toDouble();
	var result = (min_to + (max_to - min_to).toDouble() * fraction).toNumber();
	return result;
	 
}


class GraphDrawable extends WatchUi.Drawable {
	var w, h, x, y; // coordinates
	var border, foreground, background; // colors
	var tick = 5;
	var mPoints, mCoords;
	var interval; // data interval
	var mExtremums; // min/max points
	var start, end; // x axis margins
	var scale; // y scale for animation
	var mShowExtremums; // show extremums flag
			
	function initialize(params) {
		Drawable.initialize(params);
		w = params.get(:width);
		h = params.get(:height);
		x = params.get(:x);
		y = params.get(:y);
		border = params.get(:border);
		foreground = params.get(:foreground);
		background = params.get(:background);
		interval = params.get(:interval);
		scale = params.get(:scale);
		mShowExtremums = true;
	}
	
	function setData(data) {
		mPoints = new [data.size()];
		mCoords = new[data.size()];
		for (var i=0; i< data.size(); i++) {
			mCoords[i] = data[i][0];
			mPoints[i] = data[i][1];
		}
		mExtremums = extremums();
		end = mCoords[mCoords.size() - 1];
		start = end - interval;
	}
	
	function getTextJustify(tx) {
		if (tx > x + 3 * w/4) {
			return Graphics.TEXT_JUSTIFY_RIGHT;
		}
		if (tx < x + w/4) {
			return Graphics.TEXT_JUSTIFY_LEFT;
		}
		return Graphics.TEXT_JUSTIFY_CENTER;
	}
	
	
	function draw(dc) {
		drawFrame(dc);		
		if (mExtremums != null) {
			drawPoints(dc);
			if (mShowExtremums) {
				drawExtremums(dc);
			}
		}
	}
			
	function drawFrame(dc) {
		dc.setColor(border, background);
		dc.drawRectangle(x, y, w, h);
		// ticks
		for (var i = 1; i <= 3; i++) {
			dc.drawLine(x + i * w/4, y + h, x + i * w/ 4, y + h + tick * 2);
			dc.drawLine(x, y + i * h/4, x - tick, y + i * h / 4);
			dc.drawLine(x + w, y + i * h/4, x + w + tick, y + i * h/4);
		}
	}
	
	function extremums() {
		if (mCoords.size() < 2) {
			return null;
		}
		var minX = mCoords[0], maxX = mCoords[0];
		var minY = mPoints[0], maxY = mPoints[0];
		for (var i = 1; i < mCoords.size(); i++) {
			var value = mPoints[i];
			if (minY > value) {minX = mCoords[i]; minY = value;}
			if (maxY < value) {maxX = mCoords[i]; maxY = value;}
		}
		if (minY == maxY) {
			return null;
		}
		return [minX, minY, maxX, maxY];		
	}
	
	function drawPoints(dc) {
		var minY = mExtremums[1];
		var maxY = mExtremums[3];
		dc.setColor(foreground, background);
		var px = null, py = null;
		for (var i = 0; i < mCoords.size(); i++) {
			if (mCoords[0] < start) {
				// Пропускаем точки, находящиеся левее границы графика
				continue;
			}
			if (px == null || py == null) {
				// Вычисляем начальную точку
				px = interpolate(start, end, mCoords[i], x, x + w - 1);
				py = interpolate(minY, maxY, mPoints[i], y + h - 1, y + h * (1-scale));
				continue;
			}
			// Вычисляем следующие точки и рисуем на графике
			var nx = interpolate(start, end, mCoords[i], x, x + w - 1);
			var ny = interpolate(minY, maxY, mPoints[i], y + h - 1, y + h * (1-scale));
			dc.drawLine(px, py, nx, ny);
			px = nx;
			py = ny;
		}
	}
	
	function drawExtremums(dc) {
		var minX = mExtremums[0];
		var minY = mExtremums[1];
		var maxX = mExtremums[2];
		var maxY = mExtremums[3];
		dc.setColor(border, background);
		var px = interpolate(start, end, minX, x, x + w - 1);
		var py = y + h;
		
		dc.fillPolygon([[px, py], [px + 5, py - 5], [px - 5, py - 5]]);
		dc.drawText(px, py - 25, Graphics.FONT_SYSTEM_XTINY, formatPercent(minY), getTextJustify(px));
		
		px = interpolate(start, end, maxX, x, x + w - 1);
		py = y;
		
		dc.fillPolygon([[px, py], [px + 5, py + 5], [px - 5, py + 5]]);
		dc.drawText(px, py + 5, Graphics.FONT_SYSTEM_XTINY, formatPercent(maxY), getTextJustify(px));
	}
}