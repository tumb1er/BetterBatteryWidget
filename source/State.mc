/** 
State describes current state of battery widget
*/
using Toybox.System;
using Toybox.Time;

const STATE_PROPERTY = "stage";
const KEY_POINTS = "p";
const MAX_POINTS = 5;

(:background)
class State {
	var mData;	
	
	function initialize(data) {
		log("State.initialize: passed", data);
		if (data == null) {
			data = objectStoreGet(STATE_PROPERTY, null);			
			log("State.initialize: loaded", data);
		}
		if (data == null) {
			mData = [];
		} else {
			mData = data[KEY_POINTS];
		}
	}
	
	function getData() {
		return {
			KEY_POINTS => mData,
		};
		
	}
	
	function save() {
		log("State.save", getData());
		objectStorePut(STATE_PROPERTY, getData());
	}
	
	function measure() {
		var ts = Time.now().value();
		var stats = System.getSystemStats();
		log("State.measure", [ts, stats.battery, stats.charging]);
		if (stats.charging) {
			log("State.measure charging, reset at", stats.battery);
			mData = [];
		}
		if (mData.size() > 0) {
			if (stats.battery > mData[mData.size() - 1][1]) {
				log("State.measure, value increase, reset at", stats.battery);
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
	
	function predict() {
		if (mData.size() < 2) {
			return null;
		}
		var first = mData[0];
		var last = mData[mData.size() - 1];
		var duration = (last[0] - first[0]).toDouble();
		var delta = (last[1] - first[1]).abs();
		if (delta == 0 || duration == 0) {
			return null;
		}
		var speed = delta / duration;
		var left = last[1];
		return left / speed;
	}
}