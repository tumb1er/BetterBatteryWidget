/** 
State describes current state of battery widget
*/
using Toybox.Time;

const STATE_PROPERTY = "state";
const KEY_POINTS = "p";
const MAX_POINTS = 3;

(:background)
class State {
	var mData;	
	
	function initialize(data) {
		log("State.initialize: passed", data);
		if (data == null) {
			data = objectStoreGet(STATE_PROPERTY, null);			
			log("State.initialize: loadede", data);
		}
		if (data == null) {
			mData = [];
		} else {
			mData = data[KEY_POINTS];
		}
	}
	
	function getData() {
		return {
			KEY_POINTS => mData
		};
		
	}
	
	function save() {
		log("State.save", getData());
		objectStorePut(STATE_PROPERTY, getData());
	}
	
	function measure() {
		var ts = Time.now().value();
		var value = System.getSystemStats().battery;
		log("State.measure", [ts, value]);
		var ready = mData.size() > 0;
		mData.add([ts, value]);
		if (mData.size() > MAX_POINTS) {
			mData = mData.slice(1, null);
		}
		return ready;
	}
}