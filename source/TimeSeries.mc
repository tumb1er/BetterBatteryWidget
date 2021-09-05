import Toybox.Lang;
import Toybox.Test;
using Toybox.System;

typedef StatePoint as Array<Number or Float>; // [ts, percent]
typedef StatePoints as Array<StatePoint>;

const MAX_TS = 1 << 22;
const MAX_VALUE = 1 << 10;  // right 10 bits
const INT32_MASK = 1l << 32;
const LOW_MASK = INT32_MASK - 1;
const HIGH_MASK = LOW_MASK << 32;


(:background)
class TimeSeries {
    /*
    long packing format: <odd int32><even in32>

    * first two points are stored as (second << 32) | first

    int32 format:
    <ts 22 bit as offset in seconds><value 10 bit as battery ppm>

    * 48 days vector duration (2^22 seconds)
    * ts is stored as offset from start
    * value accuracy is 0.1%

    last array value contains: (start ts) << 32 | size

    */
    private var mPoints as Array<Long>;  // packed int32 values
    private var mSize as Number; // unpacked size
    private var mStart as Number;  // iterator start timestamp
    private var mPosition as Number = 0;
    private var log as Log;

    private static function validate(ts as Number, value as Number) as Long {
        if (ts > MAX_TS) {
            throw new Lang.InvalidValueException("too long points vector");
        }
        if (value > 1000 || value < 0) {
            throw new Lang.InvalidValueException("value out of range");
        }
        return (ts << 10 + value).toLong();
    }

    public static function Empty() as TimeSeries {
        return new TimeSeries([0l] as Array<Long>);
    }

    (:debug)
    public static function FromPoints(points as StatePoints) as TimeSeries {
        var size = points.size();
        if (size == 0) {
            return TimeSeries.Empty();
        }
        var start = points[0][0] as Number;
        var values = new [(size + 1) / 2 + 1] as Array<Long>;
        values[(size + 1) / 2] = start.toLong() << 32 + size;
        for (var i=0; i<size; i++) {
            var ts = (points[i][0] - start) as Number;
            var value = (points[i][1] * 10).toNumber();
            var point = TimeSeries.validate(ts, value);
            if (i % 2 == 0) {
                values[i / 2] = point;
            } else {
                values[i / 2] += point << 32;
            }
        }
        return new TimeSeries(values);
    }

    /*
    Accepts an array where last element is packed start timestamp + points count, and
    all previous are packed points.
    */
    public function initialize(points as Array<Long>) {
        log = new Log("PI");
        var size = points.size();
        if (size == 0) {
            points = new [0l] as Array<Long>;
        }
        var init = points[size - 1];
        mStart = (init / INT32_MASK).toNumber();
        mSize = (init % INT32_MASK).toNumber();
        mPoints = points;
    }

    public function at(i as Number) as TimeSeries {
        self.mPosition = i;
        return self;
    }

    public function serialize() as Array<Long> {
        // sync size and start values
        mPoints[mPoints.size() - 1] = mStart.toLong() << 32 + mSize;
        return mPoints;
    }

    public function size() as Number {
        return mSize;
    }

    private function get(idx as Number) as BatteryPoint {
        var point = mPoints[idx / 2];
        if (idx % 2 == 1) {
            // high bits needed for even indices
            point /= INT32_MASK;
        } else {
            // low bits only
            point %= INT32_MASK;
        }
        var value = (point % MAX_VALUE).toFloat() / 10.0f;
        var ts = (point >> 10 + mStart).toNumber();
        return new BatteryPoint(ts as Number, value as Float);
    }

    public function add(ts as Number, value as Float) as Void {
        if (mSize == 0) {
            mStart = ts;
        }
        var delta = ts - mStart;
        var v = (value * 10).toNumber();
        var point = TimeSeries.validate(delta, v);
        if (mSize % 2 == 0) {
            // moving start/size info to the right;
            mPoints.add(mPoints[mSize / 2]);
            // setting low bits with clear high bits to that place;
            mPoints[mSize / 2] = point;
        } else {
            mPoints[mSize / 2] += point << 32;
        }
        mSize += 1;
    }

    private function align(ts as Number) as Void {
        var delta = (ts - mStart).toLong();
        var lowShift = delta << 10;
        var highShift = lowShift << 32;
        for (var i = 0; i < mSize; i++) {
            if (i == 0) {
                // zero point has always offset 0, just skip it
                continue;
            }
            if (i % 2 == 0) {
                // low part align
                mPoints[i / 2] -= lowShift;
            } else {
                // high part align
                mPoints[i / 2] -= highShift;
            }
        }
        mStart = ts;
    }

    public function set(i as Number, ts as Number, value as Float) as Void {
        var delta = ts - mStart;
        // log.debug("delta", delta);
        if (i == 0 && mStart != ts) {
            self.align(ts);
            delta = 0;
        }
        var v = (value * 10).toNumber();
        var point = TimeSeries.validate(delta, v);
        if (i % 2 == 0) {
            // clear low bits
            mPoints[i / 2] &= HIGH_MASK;
            mPoints[i / 2] |= point;
        } else {
            // clear high bits
            mPoints[i / 2] &= LOW_MASK;
            mPoints[i / 2] |= point << 32;
        }
        log.debug("set", [i, point, mPoints[i / 2]]);
    }

    public function last() as BatteryPoint? {
        if (mSize == 0) {
            return null;
        }
        return get(mSize - 1);
    }

    public function first() as BatteryPoint? {
        if (mPoints.size() == 0) {
            return null;
        }
        return get(0);
    }

    public function start() as Void {
        mPosition = 0;
    }

    public function next() as BatteryPoint? {
        if (mPosition >= mPoints.size()) {
            return null;
        }
        var res = get(mPosition);
        mPosition += 1;
        return res;
    }

    public function current() as BatteryPoint {
        return get(mPosition);
    }

    (:debug)
    public function getPoints() as Array<Long> {
        return mPoints;
    }

    (:debug)
    public function getStart() as Number {
        return mStart;
    }
}

(:test)
function testTimeSeriesInitializeZero(logger as Logger) as Boolean {
    var pi = TimeSeries.FromPoints([] as StatePoints);
	Test.assertEqualMessage(pi.size(), 0, "unexpected size");
    Test.assertEqualMessage(pi.getStart(), 0, "unexpected start");
    var points = pi.getPoints();
    Test.assertEqualMessage(points.size(), 1, "unexpected packed length");
    var data = pi.serialize();
    Test.assertEqualMessage(data.size(), 1, "unexpected serialized length");
    var expected = 0l << 32 + 0;  // unknown start + zero size
    Test.assertEqualMessage(data[data.size() - 1], expected, "unexpected serialized value");
	return true;
}

(:test)
function testTimeSeriesInitializeSingle(logger as Logger) as Boolean {
    var pi = TimeSeries.FromPoints([[123, 55.5] as StatePoint] as StatePoints);

	Test.assertEqualMessage(pi.size(), 1, "unexpected size");
    Test.assertEqualMessage(pi.getStart(), 123, "unexpected start");
    var points = pi.getPoints();
    Test.assertEqualMessage(points.size(), 2, "unexpected packed length");
    var expected = (0 << 10 + 555).toLong();
    Test.assertEqualMessage(points[0], expected, "unexpected packed long");
    var p = pi.last() as BatteryPoint;
    Test.assertEqualMessage(p.getTS(), 123, "invalid ts");
    Test.assertEqualMessage(p.getValue(), 55.5, "invalid value");
    var data = pi.serialize();
    Test.assertEqualMessage(data.size(), 2, "unexpected serialized length");
    expected = 123l << 32 + 1;  // start + size
    Test.assertEqualMessage(data[data.size() - 1], expected, "unexpected serialized value");

    return true;
}

(:test)
function testTimeSeriesInitializeDouble(logger as Logger) as Boolean {
    var pi = TimeSeries.FromPoints([
        [123, 55.5] as StatePoint, 
        [125, 77.7] as StatePoint,
    ] as StatePoints);

	Test.assertEqualMessage(pi.size(), 2, Lang.format("unexpected size $1$", [pi.size()]));
    Test.assertEqualMessage(pi.getStart(), 123, "unexpected start");
    var points = pi.getPoints();
    Test.assertEqualMessage(points.size(), 2, "unexpected length");
    var expected = (0l << 10 + 555l + ((125 - 123) << 10 + 777l) << 32).toLong();
    Test.assertEqualMessage(points[0], expected, "unexpected packed long");
    var p = pi.last() as BatteryPoint;
    Test.assertEqualMessage(p.getTS(), 125, "invalid ts");
    Test.assertEqualMessage(p.getValue(), 77.7, "invalid value");
    var data = pi.serialize();
    Test.assertEqualMessage(data.size(), 2, "unexpected serialized length");
    expected = 123l << 32 + 2;  // start + size
    Test.assertEqualMessage(data[data.size() - 1], expected, "unexpected serialized value");

    return true;
}

(:test)
function testTimeSeriesInitializeTriple(logger as Logger) as Boolean {
    var pi = TimeSeries.FromPoints([
        [123, 55.5] as StatePoint,
        [125, 77.7] as StatePoint,
        [126, 88.8] as StatePoint,
    ] as StatePoints);

	Test.assertEqualMessage(pi.size(), 3, "unexpected size");
    Test.assertEqualMessage(pi.getStart(), 123, "unexpected start");
    var points = pi.getPoints();
    Test.assertEqualMessage(points.size(), 3, "unexpected length");
    var expected = (0l << 10 + 555l + ((125 - 123) << 10 + 777l) << 32).toLong();
    Test.assertEqualMessage(points[0], expected, "unexpected packed long 1");
    expected = ((126 - 123) << 10 + 888).toLong();
    Test.assertEqualMessage(points[1], expected, "unexpected packed long 2");
    var p = pi.last() as BatteryPoint;
    Test.assertEqualMessage(p.getTS(), 126, "invalid ts");
    Test.assertEqualMessage(p.getValue(), 88.8, "invalid value");
    var data = pi.serialize();
    Test.assertEqualMessage(data.size(), 3, "unexpected serialized length");
    expected = 123l << 32 + 3;  // start + size
    Test.assertEqualMessage(data[data.size() - 1], expected, "unexpected serialized value");

    return true;
}

(:test)
function testTimeSeriesAdd(logger as Logger) as Boolean {
    var pi = TimeSeries.FromPoints([] as StatePoints);

    pi.add(123, 55.5);

    Test.assertEqualMessage(pi.size(), 1, "unexpected size");
    Test.assertEqualMessage(pi.getStart(), 123, "unexpected start $1$");
    var points = pi.getPoints();
    Test.assertEqualMessage(points.size(), 2, "unexpected packed length");
    var expected = (0 << 10 + 555).toLong();
    Test.assertEqualMessage(points[0], expected, Lang.format("unexpected packed long $1$ != $2$", [points[0], expected]));

    pi.add(125, 77.7);

    Test.assertEqualMessage(pi.size(), 2, Lang.format("unexpected size $1$", [pi.size()]));
    points = pi.getPoints();
    Test.assertEqualMessage(points.size(), 2, "unexpected length");
    expected = (0l << 10 + 555l + ((125 - 123) << 10 + 777l) << 32).toLong();
    Test.assertEqualMessage(points[0], expected, "unexpected packed long");

    pi.add(126, 88.8);

	Test.assertEqualMessage(pi.size(), 3, "unexpected size");
    points = pi.getPoints();
    Test.assertEqualMessage(points.size(), 3, "unexpected length");
    expected = (126 - 123).toLong() << 10 + 888;
    Test.assertEqualMessage(points[1], expected, "unexpected packed long");

    return true;
}

(:test)
function testTimeSeriesSet(logger as Logger) as Boolean {
    var pi = TimeSeries.FromPoints([
        [123, 55.5] as StatePoint, 
        [125, 77.7] as StatePoint,
    ] as StatePoints);
    
    pi.set(0, 124, 33.3);
    
    var points = pi.getPoints();
    Test.assertEqualMessage(points.size(), 2, "unexpected length");
    var expected = ((124 - 124).toLong() << 10 + 333l + ((125 - 124) << 10 + 777l) << 32).toLong();
    Test.assertEqualMessage(points[0], expected, Lang.format("unexpected packed long $1$ $2$", [points[0], expected]));

    pi.set(1, 127, 99.9);

    points = pi.getPoints();
    Test.assertEqualMessage(points.size(), 2, "unexpected length");
    expected = ((124 - 124).toLong() << 10 + 333l + ((127 - 124) << 10 + 999l) << 32).toLong();
    Test.assertEqualMessage(points[0], expected, "unexpected packed long");

    return true;    
}

(:test) 
function testTimeSeriesEmpty(logger as Logger) as Boolean {
    var pi = TimeSeries.Empty();
    Test.assertEqualMessage(pi.size(), 0, "unexpected length");

    return true;
}
