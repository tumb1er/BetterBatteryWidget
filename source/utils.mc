using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;

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
	return Lang.format("$1$.$2$ $3$:$4$", [
		ts.day,
		ts.month.format("%02d"),
		ts.hour.format("%02d"),
		ts.min.format("%02d")
	]);
}

function formatPercent(value) {
	return Lang.format("$1$%", [value.format("%.1f")]);
}

(:background)
function objectStoreGet(key, defaultValue) {
    var value = Application.getApp().getProperty(key);
    if((value == null) && (defaultValue != null)) {
        value = defaultValue;
        Application.getApp().setProperty(key, value);
        }
    return value;
}

(:background)
function objectStorePut(key, value) {
    Application.getApp().setProperty(key, value);
}

(:background)
function log(tag, data) {
	System.println(Lang.format("[$1$] $2$: $3$",  [formatTime(Time.now()), tag, data]));
}

function formatInterval(seconds) {
	var hours = seconds / 3600.0;
	if (hours >= 24) { 
		return (hours / 24).format("%.1f") + "d";
	} else {
		return hours.format("%.1f") + "h";
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
