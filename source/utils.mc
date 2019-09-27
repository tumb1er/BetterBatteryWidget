using Toybox.Application;
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
