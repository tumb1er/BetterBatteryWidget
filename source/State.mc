/** 
State describes current state of battery widget
*/
using Toybox.Activity;
using Toybox.Application;
import Toybox.Lang;
using Toybox.System;
import Toybox.Test;
using Toybox.Time;

typedef StateData as {
    "p1" as ByteArray,
    "c1" as StatePoint?,
    "a1" as Boolean,
    "t1" as Number?,
    "m1" as StatePoint?,
    "e1" as Float?,
};

(:typecheck([disableBackgroundCheck, disableGlanceCheck]) :background :glance)
class State {
	private static const STATE_PROPERTY = "s1";

	private static const KEY_POINTS = "p1";
	private static const KEY_CHARGED = "c1";
	private static const KEY_ACTIVITY = "a1";
	private static const KEY_ACTIVITY_TS = "t1";
	private static const KEY_MARK = "m1";
    private static const KEY_EMA = "e1";
	
	private static const MAX_POINTS = 5;
	private static const CAPACITY = 50;  // limited by background exit max size

    private var mPoints as TimeSeries;
    private var mCharged as StatePoint?;
    private var mMark as StatePoint?;
    private var mActivityRunning as Boolean;
    private var mActivityTS as Number?;
    private var mEMA as Float?;
    // private var log as Log;
    private var mGraphDuration as Number?;
    
    public function initialize(data as StateData?) {
        // log = new Log("State");
        var app = getApp();
        mGraphDuration = 3600 * app.getGraphDuration();
        // log.debug("initialize: passed", data);
        if (data == null) {
            data = Application.Storage.getValue(STATE_PROPERTY) as StateData?;        
        // log.debug("initialize: got", data);
        }
        if (data == null) {
            // log.debug("before empty", data);
            mPoints = TimeSeries.Empty(CAPACITY);
            mCharged = null;
            mMark = null;
            mActivityTS = null;
            mActivityRunning = false;
            mEMA = 0.0;
        } else {
            mPoints = new TimeSeries(data[KEY_POINTS] as ByteArray);
            mCharged = data[KEY_CHARGED] as StatePoint?;
            mMark = data[KEY_MARK] as StatePoint?;
            mActivityTS = data[KEY_ACTIVITY_TS] as Number?;
            mActivityRunning = data[KEY_ACTIVITY] as Boolean;
            mEMA = ((data[KEY_EMA] != null)?data[KEY_EMA]: 0.0) as Float?;
        }
        //log.debug("initialize: data", mData);
    }

    public function getPointsIterator() as PointsIterator {
        return new PointsIterator(mPoints, 0);
    }

    public function getEMARate(current as BatteryPoint) as Float? {
        var ema = mEMA;
        var prev = getPointsIterator().last();
        // log.debug("emaIter last", prev.toString());
        if (prev != null && (prev.getTS() < current.getTS())) {
            // log.debug("adding prev to", mEMA);
            // Добавляем актуальное значение к последнему сохраненному
            ema = computeEMA(new BatteryPoint(
                current.getTS() - prev.getTS(),
                current.getValue() - prev.getValue()));
        }
        // log.debug("actual ema is", ema * 3600);
        return (ema>0)?ema:-ema;
    }

    public function getChargedPoint() as BatteryPoint? {
        return BatteryPoint.FromArray(mCharged);
    }

    public function getMarkPoint() as BatteryPoint? {
        return BatteryPoint.FromArray(mMark);
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
    
    (:debug)
    public function printPoints() as Void {
        mPoints.print();
        System.println("");
    }

    public function getData() as StateData {
        // log.msg("getData()");
        var stats = System.getSystemStats();
        // log.debug("getting data", stats.freeMemory);
        var points = mPoints.serialize();
        stats = System.getSystemStats();
        // log.debug("serialized points", stats.freeMemory);
        var data = {
            KEY_POINTS => points,
            KEY_CHARGED => mCharged,
            KEY_ACTIVITY => mActivityRunning,
            KEY_ACTIVITY_TS => mActivityTS,
            KEY_MARK => mMark,
            KEY_EMA => mEMA
        };
        stats = System.getSystemStats();
        // log.debug("constructed a dict", stats.freeMemory);
        // log.debug("getData", data);
        return data;
    }
    
    public function save() as Void {
        // var stats = System.getSystemStats();
        // log.debug("saving", stats.freeMemory);
        var data = getData() as Dictionary<String, Application.PropertyValueType>;
        // stats = System.getSystemStats();
        // log.debug("got data", stats.freeMemory);
        // log.debug("save", data);
        try {
            Application.Storage.setValue(STATE_PROPERTY, data);
        } catch (ex) {
            // log.error("save error", ex);
        }
        // stats = System.getSystemStats();
        // log.debug("saved", stats.freeMemory);
    }
    
    /**
    Сохраняет отмеченное значение
    */
    public function mark() as Void {
        var ts = Time.now().value();
        var stats = System.getSystemStats();
        //log.debug("mark", stats.battery);
        mMark = [ts, stats.battery] as StatePoint?;
    }
    
    /**
    Добавляет точки для графика. Возвращает точку, содержащую разницу во времени
    и в значении относительно предыдущей точки (если была добавлена новая).
    */
    private function pushPoint(point as BatteryPoint) as BatteryPoint? {
        // self.log.debug("pushPoint", point.toString());
        point.align();
        // self.log.debug("point aligned", point.toString());
        // Если массив пуст, добавляем точку без условий
        if (mPoints.size() == 0) {
            // self.log.msg("zero size, add");
            // Всего одна точка, разницу не рассчитаешь.
            mPoints.add(point);
            return null;
        }
        var ts = point.getTS();
        var value = point.getValue();
        // Не добавляем точку, если интервал времени между ними слишком мал
        var prev = mPoints.last() as BatteryPoint;
        // self.log.debug("prev point", prev.toString());
        if (ts - prev.getTS() < 1) {
            // self.log.debug("ts delta too low", ts - prev.getTS());
            // Не добавляли новую точку
            return null;
        }
        // Если значения одинаковые, сдвигаем имеющуюся точку вправо (кроме первой точки)
        if (value == prev.getValue()) {
            // Заряд не изменился, точку не добавляем
            return null;
        } else {
            // self.log.debug("value delta", (value - prev.getValue()));
        }
        
        mPoints.add(point);
        return new BatteryPoint(ts - prev.getTS(), value - prev.getValue());
    }

    // Обновляет значения V-EMA для скорости разряда
    private function computeEMA(delta as BatteryPoint) as Float {
        var dt = delta.getTS().toFloat();
        var dv = delta.getValue();
        var speed = dv / dt;
        // self.log.debug("speed", [dv, dt, speed * 3600]);
        var weight = dt / (30 * 60.0);
        if (weight > 1) {
            weight = 1;
        }
        // self.log.debug("weight", weight);

        return (1 - weight) * mEMA + weight * speed;
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
        var point = new BatteryPoint(ts, battery).align();
        var delta = pushPoint(point);
        if (delta != null) {
            // Рассчитываем V-EMA
            mEMA = computeEMA(delta);
            // self.log.debug("new ema is", mEMA * 3600);
        }
        
        // Если данные отсутствуют, просто добавляем одну точку.
        if (mCharged == null) {
            //log.debug("data is empty, initializing", battery);
            reset(point);
            return;
        }
        
        // На зарядке сбрасываем состояние
        if (charging) {
            //log.debug("charging, reset at", battery);
            reset(point);
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
    private function reset(point as BatteryPoint) as Void {
        mActivityTS = point.getTS();
        mCharged = [point.getTS(), point.getValue()] as Array<Number or Float>?;
        mMark = null;
        mEMA = 0.0;
    }
}

(:test)
function testCheckActivityState(logger as Logger) as Boolean {
    var app = getApp();
    var state = app.getState();
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
    var app = getApp();
    var state = app.getState();
    state.setmPoints(TimeSeries.Empty(50));
    
    state.measure();
    
    Test.assertEqualMessage(state.getmPoints().size(), 1, "mPoints not updated");
    return true;
}
