using Toybox.Application;
using Toybox.System;
using Toybox.Time;

(:background)
function now() {
	var myTime = System.getClockTime(); // ClockTime object
	var ret = myTime.hour.format("%02d") + ":" +
	    myTime.min.format("%02d") + ":" +
	    myTime.sec.format("%02d");
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
function getPercentTs() {
	var stats = System.getSystemStats();
	return [stats.battery, Time.now().value()];
}