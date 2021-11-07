/** 
State describes current state of battery widget
*/
using Toybox.Activity;
using Toybox.Application;
import Toybox.Lang;
using Toybox.System;
import Toybox.Test;
using Toybox.Time;

const STATE_PROPERTY = "s";
const KEY_POINTS = "p";
const KEY_CHARGED = "c";
const KEY_ACTIVITY = "a";
const KEY_ACTIVITY_TS = "t";
const KEY_MARK = "m";
const MAX_POINTS = 5;
const CAPACITY = 100;  // TODO: from resources depending on screen size

typedef StateValues as StatePoint or StatePoints or Boolean or Array<Long> or Number or Null;
typedef StateData as Dictionary<String, StateValues>;

(:background)
class State {
	private var mPoints as TimeSeries;
	private var mCharged as StatePoint?;
	private var mMark as StatePoint?;
	private var mActivityRunning as Boolean;
	private var mActivityTS as Number?;
	var log as Log;
	var mGraphDuration as Number?;
	
	public function initialize(data as StateData?) {
		log = new Log("State");
		var app = Application.getApp() as BetterBatteryWidgetApp;
		mGraphDuration = 3600 * (app.mGraphDuration as Number);
		log.debug("initialize: passed", data);
		if (data == null) {
			data = app.getProperty(STATE_PROPERTY) as Dictionary<String, Array<Number or Float> or Boolean>?;		
		log.debug("initialize: got", data);
		}
		if (data == null) {
			log.debug("before empty", data);
			mPoints = TimeSeries.Empty(CAPACITY);
			mCharged = null;
			mMark = null;
			mActivityTS = null;
			mActivityRunning = false;
		} else {
			mPoints = new TimeSeries(data[KEY_POINTS] as Array<Long>);
			mCharged = ((data[KEY_CHARGED])? data[KEY_CHARGED]: null) as Array<Number or Float>?;
			mMark = ((data[KEY_MARK])? data[KEY_MARK]: null) as Array<Number or Float>?;
			mActivityTS = data[KEY_ACTIVITY_TS] as Number?;
			mActivityRunning = data[KEY_ACTIVITY] as Boolean;
		}
		//log.debug("initialize: data", mData);
	}

	public function getPointsIterator() as PointsIterator {
		return new PointsIterator(mPoints, 0);
	}

	public function getWindowIterator() as PointsIterator {
		var position = 0;
		if (mPoints.size() > MAX_POINTS) {
			position = mPoints.size() - MAX_POINTS;
		}
		var iterator = new PointsIterator(mPoints, position);
		if (mActivityTS != null) {
			var c = iterator.current();
			while (c != null) {
				if ((c as BatteryPoint).getTS() < mActivityTS as Number) {
					iterator.next();
					c = iterator.current();
				} else {
					break;
				}
			}
		}
		return iterator;
	}

	public function getChargedPoint() as BatteryPoint? {
		return BatteryPoint.fromArray(mCharged);
	}

	public function getMarkPoint() as BatteryPoint? {
		return BatteryPoint.fromArray(mMark);
	}

	(:debug)
	public function getmActivityRunning() as Boolean {
		return self.mActivityRunning;
	}

	(:debug)
	public function setmActivityRunning(v as Boolean) as Void {
		self.mActivityRunning = v;
	}

	(:debug)
	public function getmPoints() as TimeSeries {
		return mPoints;
	}

	(:debug)
	public function setmPoints(points as TimeSeries) as Void {
		self.mPoints = points;
	}

	(:debug)
	public function getmActivityTS() as Number? {
		return self.mActivityTS;
	}
	
	public function getData() as StateData {
		return {
			KEY_POINTS => mPoints.serialize(),
			KEY_CHARGED => mCharged,
			KEY_ACTIVITY => mActivityRunning,
			KEY_ACTIVITY_TS => mActivityTS,
			KEY_MARK => (mMark != null)?mMark:false
		} as StateData;
		
	}
	
	public function save() as Void {
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
	public function mark() as Void {
		var ts = Time.now().value();
		var stats = System.getSystemStats();
		//log.debug("mark", stats.battery);
		mMark = [ts, stats.battery] as Array<Number or Float>?;
	}
	
	/**
	Добавляет точки для графика. 
	*/
	private function pushPoint(ts as Number, value as Float) as Void {
		// Если массив пуст, добавляем точку без условий
		if (mPoints.size() == 0) {
			mPoints.add(ts, value);
			return;
		}
		// Не добавляем точку, если интервал времени между ними слишком мал
		var prev = mPoints.last() as BatteryPoint;
		if (ts - prev.getTS() < 1) {
			return;
		}
		// Если значения одинаковые, сдвигаем имеющуюся точку вправо (кроме первой точки)
		if (value == prev.getValue()) {
			if (mPoints.size() > 1) {
				mPoints.set(mPoints.size() - 1, ts, value);
			}
			return;
		}
		
		mPoints.add(ts, value);
		
		// TODO: rotate
		// // Храним точки не дольше N часов
		// var i;
		// for (i=0; mPoints[i][0] < ts - (mGraphDuration as Number); i++) {}
		// if (i != 0) {
		// 	// Оставляем одну точку про запас для графика
		// 	mPoints = mPoints.slice(i - 1, null);
		// }
	}
	
	public function measure() as Void {
		var ts = Time.now().value();
		var stats = System.getSystemStats();
		//log.debug("values", [ts, stats.battery, mData]);	
		handleMeasurements(ts, stats.battery, stats.charging);
		checkActivityState(Activity.getActivityInfo(), ts, stats.battery);
		//log.debug("handled", [ts, stats.battery, mData]);	
	}
	
	public function handleMeasurements(ts as Number, battery as Float, charging as Boolean) as Void {		
		// Точку на график добавляем всегда
		pushPoint(ts, battery);
		
		// Если данные отсутствуют, просто добавляем одну точку.
		if (mCharged == null) {
			//log.debug("data is empty, initializing", battery);
			reset(ts, battery);
			return;
		}
		
		// На зарядке сбрасываем состояние
		if (charging) {
			//log.debug("charging, reset at", battery);
			reset(ts, battery);
			return;
		}

		return;
	}
	
	/**
	Resets prediction data if activity state changed
	*/
	public function checkActivityState(info as Activity.Info?, ts as Number, value as Float) as Void {
		
		// При изменении статуса активности сбрасываем состояние.
		var activityRunning = info != null && (info as Activity.Info).timerState != Activity.TIMER_STATE_OFF;
		if (activityRunning != mActivityRunning) {
			//log.debug("activity state changed, reset at", value);
			mActivityRunning = activityRunning;
			// Сбрасываем точку изменения активности
			mActivityTS = ts;
		}
		
	}

	
	/**
	Сбрасывает данные для измерений. 
	*/
	private function reset(ts as Number, value as Float) as Void {
		mActivityTS = ts;
		mCharged = [ts, value] as Array<Number or Float>?;
		mMark = null;
	}
}

(:test)
function testCheckActivityState(logger as Logger) as Boolean {
	var app = Application.getApp() as BetterBatteryWidgetApp;
	var state = app.mState;
	var ts = Time.now().value() as Number;
	var value = 75.1;
	
	state.setmActivityRunning(true);
	
	// activity not registered
	state.checkActivityState(null, ts, value);
	
	Test.assertEqualMessage(state.getmActivityRunning(), false, "mActivityRunning not updated");
	Test.assertEqualMessage(state.getmActivityTS() as Object, ts, "mActivityTS not reset");

	var info = new Activity.Info();
	info.timerState = Activity.TIMER_STATE_ON;
	ts += 1;
	
	// activity started
	state.checkActivityState(info, ts, value);
	
	Test.assertEqualMessage(state.getmActivityRunning(), true, "mActivityRunning not updated");
	Test.assertEqualMessage(state.getmActivityTS() as Object, ts, "mActivityTS not reset");

	info.timerState = Activity.TIMER_STATE_OFF;
	ts += 1;
	
	// activity stopped
	state.checkActivityState(info, ts, value);
	
	Test.assertEqualMessage(state.getmActivityRunning(), false, "mActivityRunning not updated");
	Test.assertEqualMessage(state.getmActivityTS() as Object, ts, "mActivityTS not reset");
	return true;
} 

(:test)
function testMeasureSmoke(logger as Logger) as Boolean {
	var app = Application.getApp() as BetterBatteryWidgetApp;
	var state = app.mState;
	state.setmPoints(TimeSeries.Empty(CAPACITY));
	
	state.measure();
	
	Test.assertEqualMessage(state.getmPoints().size(), 1, "mPoints not updated");
	return true;
}
