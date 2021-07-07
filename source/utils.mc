using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

(:background)
function formatTime(moment) {
	if (moment == null) {
		return "null";
	}
	var info = Time.Gregorian.info(moment, Time.FORMAT_MEDIUM);
	var ret = info.hour.format("%02d") + ":" +
	    info.min.format("%02d") + ":" +
	    info.sec.format("%02d");
    return ret;
}

function formatTimestamp(ts) {
	ts = Time.Gregorian.info(new Time.Moment(ts), Time.FORMAT_SHORT);
	return Lang.format(WatchUi.loadResource(Rez.Strings.DateTimeFormat), [
		ts.day,
		ts.month.format("%02d"),
		ts.hour.format("%02d"),
		ts.min.format("%02d")
	]);
}

function formatPercent(value) {
	if (value == null) {
		return "";
	}
	return Lang.format("$1$%", [value.format("%.1f")]);
}

function formatInterval(seconds) {
	var hours = seconds / 3600.0;
	if (hours >= 24) {
		return (hours / 24).format("%.1f") + WatchUi.loadResource(Rez.Strings.shortDay);
	} else {
		return hours.format("%.1f") + WatchUi.loadResource(Rez.Strings.shortHour);
	}
}

function colorize(percent) {
	if (percent > 90) {
		// blue
		return 0x00aaff;
	} else if (percent > 75) {
		// cyan
		return 0x55ffff;
	} else if (percent > 50) {
		// green
		return 0x55ff00;
	} else if (percent > 25) {
		// yellow
		return 0xffff00;
	} else if (percent > 10) {
		// orange
		return 0xffaa00;			
	} else {
		// red
		return 0xff0000;	
	}
}

(:debug)
function assertViewDraw(logger, page) {
	var s = System.getDeviceSettings();
	var display = new Graphics.BufferedBitmap({
		:width => s.screenWidth,
		:height => s.screenHeight
	});
	var dc = display.getDc();
	logger.debug("onLayout");
	page.onLayout(dc);
	logger.debug("onShow");
	page.onShow();
	logger.debug("onUpdate");
	page.onUpdate(dc);
	return dc;
}
