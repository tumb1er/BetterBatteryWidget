/** 
State describes current state of battery widget
*/
using Toybox.System;
using Toybox.Time;

const STATE_PROPERTY = "s";
const KEY_POINTS = "p";
const KEY_CHARGED = "c";
const MAX_POINTS = 5;

class Result {
	var mStats;
	var chargedTs, chargedPercent;
	var chargedSpeed, chargedPredict;
	var windowSpeed, windowPredict;
	var avgSpeed, avgPredict;
	
	function initialize(stats) {
		mStats = stats;
		if (mStats.mCharged != null) { 
			chargedTs = mStats.mCharged[0];
			chargedPercent = mStats.mCharged[1];
		}
	}
	
	function predict(first, last) {
		var duration = (last[0] - first[0]).toDouble();
		var delta = (last[1] - first[1]).abs();
		if (delta == 0 || duration == 0) {
			return [null, null];
		}
		var speed = delta / duration;
		return [speed, last[1] / speed];		
	}
	
	function predictWindow() {
		windowSpeed = null;
		windowPredict = null;
		var data = mStats.mData;
		if (data.size() < 2) {
			return;
		}
		var first = data[0];
		var last = data[data.size() - 1];
		var result = predict(first, last);
		windowSpeed = result[0];
		windowPredict = result[1];
	}
	
	function predictCharged() {
		chargedSpeed = null;
		chargedPredict = null;
		var first = mStats.mCharged;
		if (first == null) {
			return;
		}
		var data = mStats.mData;
		if (data.size() == 0) {
			return;
		}
		var last = data[data.size() - 1];
		var result = predict(first, last);
		chargedSpeed = result[0];
		chargedPredict = result[1];
	}
	
}


(:background)
class State {
	var mData;	
	var mCharged;
	
	function initialize(data) {
		log("State.initialize: passed", data);
		if (data == null) {
			data = objectStoreGet(STATE_PROPERTY, null);			
			log("State.initialize: loaded", data);
		}
		if (data == null) {
			mData = [];
			mCharged = null;
		} else {
			mData = data[KEY_POINTS];
			mCharged = data[KEY_CHARGED];
		}
	}
	
	function getData() {
		return {
			KEY_POINTS => mData,
			KEY_CHARGED => mCharged
		};
		
	}
	
	function save() {
		log("State.save", getData());
		objectStorePut(STATE_PROPERTY, getData());
	}
	
	function measure() {
		var ts = Time.now().value();
		var stats = System.getSystemStats();
		log("State.measure", [ts, stats.battery, stats.charging, mCharged]);
		if (mCharged == null) {
			mCharged = [ts, stats.battery];
		}
		if (stats.charging) {
			log("State.measure charging, reset at", stats.battery);
			mData = [];
			mCharged = [ts, stats.battery];
		}
		if (mData.size() > 0) {
			if (stats.battery > mData[mData.size() - 1][1]) {
				log("State.measure, value increase, reset at", stats.battery);
				mCharged = mData[mData.size() - 1];
				mData = [];
			}
		}
		if (mData.size() > 0) {
			if (stats.battery < mData[mData.size() - 1][1]) {
				mData.add([ts, stats.battery]);
			} else {
				log("State.measure, same value", stats.battery);
			}			
		} else {
			mData.add([ts, stats.battery]);
		}
		if (mData.size() > MAX_POINTS) {
			mData = mData.slice(1, null);
		}
		return mData.size() > 0;
	}
	
}