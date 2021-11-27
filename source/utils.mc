using Toybox.Graphics;
import Toybox.Lang;
using Toybox.System;
using Toybox.Test;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;


(:background)
function formatTime(moment as Time.Moment?) as String {
	if (moment == null) {
		return "null";
	}
	var info = Time.Gregorian.info(moment as Time.Moment, Time.FORMAT_MEDIUM);
	var ret = info.hour.format("%02d") + ":" +
	    info.min.format("%02d") + ":" +
	    info.sec.format("%02d");
    return ret;
}

function formatTimestamp(ts as Number) as String {
	var t = Time.Gregorian.info(new Time.Moment(ts), Time.FORMAT_SHORT);
	return Lang.format(
		WatchUi.loadResource(Rez.Strings.DateTimeFormat) as String, 
		[
			t.day,
			(t.month as Number).format("%02d"),  // Зависит от формата FORMAT_SHORT
			t.hour.format("%02d"),
			t.min.format("%02d")
		]);
}

function formatPercent(value as Float?) as String {
	if (value == null) {
		return "";
	}
	return Lang.format("$1$%", [(value as Float).format("%.1f")]);
}

function formatInterval(seconds as Number) as String {
	var hours = seconds / 3600.0;
	if (hours >= 24) {
		return (hours / 24).format("%.1f") + WatchUi.loadResource(Rez.Strings.shortDay);
	} else {
		return hours.format("%.1f") + WatchUi.loadResource(Rez.Strings.shortHour);
	}
}

function colorize(percent as Float) as Graphics.ColorType {
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

function loadNumberFromStringResource(r as Symbol) as Number {
	return (WatchUi.loadResource(r) as String).toNumber() as Number;
}

(:debug)
function assertViewDraw(logger as Test.Logger, page as WatchUi.View) as Graphics.Dc {
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

(:debug)    
function assert_equal(v1 as Any, v2 as Any, msg as string) as Void {
    Test.assertEqualMessage(v1, v2, Lang.format("$1$: $2$ != $3$", [msg, v1, v2]));
}