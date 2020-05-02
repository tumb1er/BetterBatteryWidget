/** 
State describes current state of battery widget
*/
using Toybox.Activity;
using Toybox.System;
using Toybox.Time;

const STATE_PROPERTY = "s";
const KEY_DATA = "d";
const KEY_POINTS = "p";
const KEY_CHARGED = "c";
const KEY_ACTIVITY = "a";
const KEY_MARK = "m";
const MAX_POINTS = 5;

class Result {
	var mStats;
	var chargedTs, chargedPercent;
	var chargedSpeed, chargedPredict;
	var windowSpeed, windowPredict;
	var markSpeed, markPredict;
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
	
	function predictAvg(weight) {
		if (windowPredict == null) {
			return chargedPredict;
		}
		if (chargedPredict == null) {
			return windowPredict;
		}
		return windowPredict * weight + chargedPredict * (1.0 - weight);
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
	
	function chargedDuration() {
		var first = mStats.mCharged;
		if (first == null) {
			return 0;
		}
		var data = mStats.mData;
		if (data.size() == 0) {
			return 0;
		}
		var last = data[data.size() - 1];
		var duration = (last[0] - first[0]).toDouble();
		return duration;
	}
	
	function predictMark() {
		markSpeed = null;
		markPredict = null;
		var first = mStats.mMark;
		if (first == null) {
			return;
		}
		var data = mStats.mData;
		if (data.size() == 0) {
			return;
		}
		var last = data[data.size() - 1];
		var result = predict(first, last);
		markSpeed = result[0];
		markPredict = result[1];
	}
	
}


(:background)
class State {
	var mData;	
	var mPoints;
	var mCharged;
	var mMark;
	var mActivityRunning;
	var log;
	var mGraphWidth;
	
	function initialize(data) {
		log = new Log("State");
		mGraphWidth = 3600 * Application.getApp().mGraphWidth;
		log.debug("initialize: passed", data);
		if (data == null) {
			data = objectStoreGet(STATE_PROPERTY, null);			
			log.debug("initialize: loaded", data);
		}
		if (data == null) {
			mData = [];
			mCharged = null;
			mActivityRunning = false;
			mPoints = [];
			mMark = null;
		} else {
			mData = data[KEY_DATA];
			mPoints = data[KEY_POINTS];
			mCharged = data[KEY_CHARGED];
			mMark = data[KEY_MARK];
			if (mMark == false) {
				mMark = null;
			}
			mActivityRunning = data[KEY_ACTIVITY];
		}
	}
	
	public function getData() {
		return {
			KEY_DATA => mData,
			KEY_POINTS => mPoints,
			KEY_CHARGED => mCharged,
			KEY_ACTIVITY => mActivityRunning,
			KEY_MARK => (mMark != null)?mMark:false
		};
		
	}
	
	public function save() {
		log.debug("save", getData());
		try {
			objectStorePut(STATE_PROPERTY, getData());
		} catch (ex) {
			log.error("save error", ex);
		}
	}
	
	/**
	Сохраняет отмеченное значение
	*/
	public function mark() {
		var ts = Time.now().value();
		var stats = System.getSystemStats();
		log.debug("mark", stats.battery);
		mMark = [ts, stats.battery];
	}
	
	/**
	Добавляет точки для графика. 
	*/
	private function pushPoint(ts, value) {
		// Если массив пуст, добавляем точку без условий
		if (mPoints.size() == 0) {
			mPoints.add([ts, value]);
			return;
		}
		// Не добавляем точку, если интервал времени между ними слишком мал
		var prev = mPoints[mPoints.size() - 1];
		if (ts - prev[0] < 1) {
			return;
		}
		// Если значения одинаковые, сдвигаем имеющуюся точку вправо (кроме первой точки)
		if (value == prev[1]) {
			if (mPoints.size() > 1) {
				prev[0] = ts;
			}
			return;
		}
		
		mPoints.add([ts, value]);
		
		// Храним точки не дольше N часов
		var i;
		for (i=0; mPoints[i][0] < ts - mGraphWidth; i++) {}
		if (i != 0) {
			mPoints = mPoints.slice(i, null);
		}
	}
	
	public function measure() {
		var ts = Time.now().value();
		var stats = System.getSystemStats();
		var ml = log.child("measure");
		ml.debug("values", [ts, stats.battery, stats.charging, mCharged]);
		
		// Точку на график добавляем всегда
		pushPoint(ts, stats.battery);
		
		// Если данные отсутствуют, просто добавляем одну точку.
		if (mCharged == null) {
			ml.debug("data is empty, initializing", stats.battery);
			return reset(ts, stats.battery);
		}
		
		// На зарядке сбрасываем состояние
		if (stats.charging) {
			ml.debug("charging, reset at", stats.battery);
			return reset(ts, stats.battery);
		}

		// При изменении статуса активности сбрасываем состояние.
		var info = Activity.getActivityInfo();
		var activityRunning = info != null && info.timerState != Activity.TIMER_STATE_OFF;
		if (activityRunning != mActivityRunning) {
			ml.debug("activity state changed, reset at", stats.battery);
			mActivityRunning = activityRunning;
			// Стираем только данные, отметка о последней зарядке остается на месте
			mData = [[ts, value]];
			return;
		}
			
		// Добавляем точку для отслеживания показаний за последние полчаса.
		pushData(ts, stats.battery);
	}
	
	/**
	Добавляет новую точку для измерений
	*/
	private function pushData(ts, value) {
		var ml = log.child("pushData");
		// Первую точку добавляем всегда.
		if (mData.size() == 0) {
			mData.add([ts, value]);
			return;		
		}

		var prev = mData[mData.size() - 1][1];
			
		// Одинаковые значения не добавляем
		if (prev == value) {
			ml.debug("same value, skip", [value, prev]);
			return;
		}	
		// Слишком быстрый рост заряда - это показатель пропущенных данных, сбрасываем.
		if (value > prev + 1.0) {
			ml.debug("value increase, reset at", value);
			reset(ts, value);
			return;
		}

		// Добавляем точку и удаляем устаревшие
		mData.add([ts, value]);
		if (mData.size() > MAX_POINTS) {
			mData = mData.slice(1, null);
		}
		return;
	}
	
	
	/**
	Сбрасывает данные для измерений. 
	*/
	private function reset(ts, value) {
		mData = [[ts, value]];
		mCharged = [ts, value];
		mMark = null;
	}
	
	
}