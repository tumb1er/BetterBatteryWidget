/** 
State describes current state of battery widget
*/
using Toybox.Activity;
using Toybox.Application;
import Toybox.Lang;
using Toybox.System;
using Toybox.Test;
using Toybox.Time;

const STATE_PROPERTY = "s";
const KEY_DATA = "d";
const KEY_POINTS = "p";
const KEY_CHARGED = "c";
const KEY_ACTIVITY = "a";
const KEY_MARK = "m";
const MAX_POINTS = 5;

(:background)
class State {
	private var mData as Array<Array<Number or Float> >;	
	private var mPoints as Array<Array<Number or Float> >;
	private var mCharged as Array<Number or Float>?;
	private var mMark as Array<Number or Float>?;
	private var mActivityRunning as Boolean;
	//var log;
	var mGraphDuration;
	
	public function initialize(data as Dictionary<String, Array<Array<Number or Float> > or Array<Number or Float> or Boolean>?) {
		//log = new Log("State");
		var app = Application.getApp() as BetterBatteryWidgetApp;
		mGraphDuration = 3600 * app.mGraphDuration;
		//log.debug("initialize: passed", data);
		if (data == null) {
			data = app.getProperty(STATE_PROPERTY) as Dictionary<String, Array<Array<Number or Float> > or Array<Number or Float> or Boolean>?;		
		}
		if (data == null) {
			mData = [] as Array<Array<Number or Float> >;
			mPoints = [] as Array<Array<Number or Float> >;
			mCharged = null;
			mMark = null;
			mActivityRunning = false;
		} else {
			mData = data[KEY_DATA] as Array<Array<Number or Float> >;
			mPoints = data[KEY_POINTS] as Array<Array<Number or Float> >;
			mCharged = ((data[KEY_CHARGED])? data[KEY_CHARGED]: null) as Array<Number or Float>?;
			mMark = ((data[KEY_MARK])? data[KEY_MARK]: null) as Array<Number or Float>?;
			mActivityRunning = data[KEY_ACTIVITY] as Boolean;
		}
		//log.debug("initialize: data", mData);
	}

	public function getPointsIterator() as PointsIterator {
		return new PointsIterator(mPoints);
	}

	public function getDataIterator() as PointsIterator {
		return new PointsIterator(mData);
	}

	public function getChargedPoint() as BatteryPoint? {
		if (mCharged == null) {
			return null;
		}
		return new BatteryPoint(mCharged[0], mCharged[1]);
	}

	public function getMarkPoint() as BatteryPoint? {
		if (mMark == null) {
			return null;
		}
		return new BatteryPoint(mMark[0], mMark[1]);
	}

	(:debug)
	public function getmActivityRunning() as Boolean {
		return self.mActivityRunning;
	}

	(:debug)
	public function setmActivityRunning(v as Boolean) {
		self.mActivityRunning = v;
	}

	(:debug)
	public function getmData() {
		return self.mData;
	}

	(:debug) 
	public function setmData(data) {
		self.mData = data;
	}

	(:debug)
	public function getmPoints() {
		return self.mPoints;
	}

	(:debug)
	public function setmPoints(points) {
		self.mPoints = points;
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
		//log.debug("save", getData());
		try {
			Application.getApp().setProperty(STATE_PROPERTY, getData());
		} catch (ex) {
			//log.error("save error", ex);
		}
	}
	
	/**
	Сохраняет отмеченное значение
	*/
	public function mark() {
		var ts = Time.now().value();
		var stats = System.getSystemStats();
		//log.debug("mark", stats.battery);
		mMark = [ts, stats.battery] as Array<Number or Float>?;
	}
	
	/**
	Добавляет точки для графика. 
	*/
	private function pushPoint(ts, value) {
		// Если массив пуст, добавляем точку без условий
		if (mPoints.size() == 0) {
			mPoints.add([ts, value] as Array<Number or Float>);
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
		
		mPoints.add([ts, value] as Array<Number or Float>);
		
		// Храним точки не дольше N часов
		var i;
		for (i=0; mPoints[i][0] < ts - mGraphDuration; i++) {}
		if (i != 0) {
			// Оставляем одну точку про запас для графика
			mPoints = mPoints.slice(i - 1, null);
		}
	}
	
	public function measure() {
		var ts = Time.now().value();
		var stats = System.getSystemStats();
		//log.debug("values", [ts, stats.battery, mData]);	
		handleMeasurements(ts, stats.battery, stats.charging);
		checkActivityState(Activity.getActivityInfo(), ts, stats.battery);
		//log.debug("handled", [ts, stats.battery, mData]);	
	}
	
	public function handleMeasurements(ts, battery, charging) {		
		// Точку на график добавляем всегда
		pushPoint(ts, battery);
		
		// Если данные отсутствуют, просто добавляем одну точку.
		if (mCharged == null) {
			//log.debug("data is empty, initializing", battery);
			return reset(ts, battery);
		}
		
		// На зарядке сбрасываем состояние
		if (charging) {
			//log.debug("charging, reset at", battery);
			return reset(ts, battery);
		}
			
		// Добавляем точку для отслеживания показаний за последние полчаса.
		return pushData(ts, battery);
	}
	
	/**
	Resets prediction data if activity state changed
	*/
	public function checkActivityState(info, ts, value) {
		
		// При изменении статуса активности сбрасываем состояние.
		var activityRunning = info != null && info.timerState != Activity.TIMER_STATE_OFF;
		if (activityRunning != mActivityRunning) {
			//log.debug("activity state changed, reset at", value);
			mActivityRunning = activityRunning;
			// Стираем только данные, отметка о последней зарядке остается на месте
			mData = [[ts, value] as Array<Number or Float>] as Array<Array<Number or Float> >;
			return;
		}
		
	}
	/**
	Добавляет новую точку для измерений
	*/
	private function pushData(ts, value) {
		// Первую точку добавляем всегда.
		//log.debug("pushData", mData);
		if (mData.size() == 0) {
			mData.add([ts, value] as Array<Number or Float>);
			return;		
		}

		var prev = mData[mData.size() - 1][1];
			
		// Одинаковые значения не добавляем
		if (prev == value) {
			//log.debug("same value, skip", [value, prev]);
			return;
		}	
		// Слишком быстрый рост заряда - это показатель пропущенных данных, сбрасываем.
		if (value > prev + 1.0) {
			//log.debug("value increase, reset at", [value, prev]);
			reset(ts, value);
			return;
		}

		// Добавляем точку и удаляем устаревшие
		mData.add([ts, value] as Array<Number or Float>);
		if (mData.size() > MAX_POINTS) {
			mData = mData.slice(1, null);
		}
		return;
	}
	
	
	/**
	Сбрасывает данные для измерений. 
	*/
	private function reset(ts, value) {
		mData = [[ts, value] as Array<Number or Float>] as Array<Array<Number or Float> >;
		mCharged = [ts, value] as Array<Number or Float>?;
		mMark = null;
	}
}

(:test)
function testCheckActivityState(logger) {
	var app = Application.getApp();
	var state = app.mState;
	var ts = Time.now().value();
	var value = 75.1;
	
	state.setmActivityRunning(true);
	
	// activity not registered
	state.checkActivityState(null, ts, value);
	
	Test.assertEqualMessage(state.getmActivityRunning(), false, "mActivityRunning not updated");
	Test.assertEqualMessage(state.getDataIterator().size(), 1, "mData not reset");

	var d = state.getmData();
	d.add([ts, value]);
	var info = new Activity.Info();
	info.timerState = Activity.TIMER_STATE_ON;
	
	// activity started
	state.checkActivityState(info, ts, value);
	
	Test.assertEqualMessage(state.getmActivityRunning(), true, "mActivityRunning not updated");
	Test.assertEqualMessage(state.getDataIterator().size(), 1, "mData not reset");
	
	d.add([ts, value]);
	info.timerState = Activity.TIMER_STATE_OFF;
	
	// activity stopped
	state.checkActivityState(info, ts, value);
	
	Test.assertEqualMessage(state.getmActivityRunning(), false, "mActivityRunning not updated");
	Test.assertEqualMessage(state.getDataIterator().size(), 1, "mData not reset");
	return true;
} 

(:test)
function testMeasureSmoke(logger) {
	var app = Application.getApp();
	var state = app.mState;
	state.setmPoints([]);
	state.setmData([]);
	
	state.measure();
	
	Test.assertEqualMessage(state.getmPoints().size(), 1, "mPoints not updated");
	Test.assertEqualMessage(state.getmData().size(), 1, "mData not updated");
	return true;
}