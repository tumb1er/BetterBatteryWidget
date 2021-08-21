import Toybox.Lang;
import Toybox.Test;
using Toybox.System;

typedef StatePoint as Array<Number or Float>; // [ts, percent]
typedef StatePoints as Array<StatePoint>;

const MAX_TS = 1 << 22;
const MAX_VALUE = 1 << 10;  // right 10 bits
const INT32_MASK = 1l << 32;


class PointsIterator {
    /*
    long packing format: <odd int32><even in32>

    * first two points are stored as (first << 32) | second

    int32 format:
    <ts 22 bit as offset in seconds><value 10 bit as battery ppm>

    * 48 days vector duration (2^22 seconds)
    * ts is stored as offset from start
    * value accuracy is 0.1%

    */
    private var mPoints as Array<Long>;  // packed int32 values
    private var mSize as Number; // unpacked size
    private var mStart as Number;  // iterator start timestamp
    private var mPosition as Number = 0;
    // private var log as Log;

    public static function FromPoints(points as StatePoints) as PointsIterator {
        var size = points.size();
        if (size == 0) {
            return new PointsIterator([0l] as Array<Long>);
        }
        var start = points[0][0] as Number;
        var values = new [(size + 1) / 2 + 1] as Array<Long>;
        values[(size + 1) / 2] = start.toLong() << 32 + size;
        var point = 0l;
        for (var i=0; i<size; i++) {
            
            var ts = (points[i][0] - start) as Number;
            if (ts > MAX_TS) {
                throw new Lang.InvalidValueException("too long points vector");
            }
            var value = (points[i][1] * 10).toNumber();
            if (value > 1000 || value < 0) {
                throw new Lang.InvalidValueException("value out of range");
            }
            if (i % 2 == 0) {
                point = (ts << 10 + value).toLong();
                values[i / 2] = point;
            } else {
                values[i / 2] = point + (ts << 10 + value).toLong() << 32;
                point = 0l;
            }
        }
        return new PointsIterator(values);
    }

    /*
    Accepts an array where last element is packed start timestamp + points count, and
    all previous are packed points.
    */
    public function initialize(points as Array<Long>) {
        // log = new Log("PI");
        var size = points.size();
        if (size == 0) {
            points = new [0l] as Array<Long>;
        }
        var init = points[size - 1];
        mStart = (init / INT32_MASK).toNumber();
        mSize = (init % INT32_MASK).toNumber();
        mPoints = points;
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

    public function reset() as Void {
        self.mPosition = 0;
    }

    public function next() as BatteryPoint? {
        if (mPosition >= mPoints.size()) {
            return null;
        }
        var res = get(mPosition);
        mPosition += 1;
        return res;
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
function testPointsIteratorInitializeZero(logger as Logger) as Boolean {
    var pi = PointsIterator.FromPoints([] as StatePoints);
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
function testPointsIteratorInitializeSingle(logger as Logger) as Boolean {
    var pi = PointsIterator.FromPoints([[123, 55.5] as StatePoint] as StatePoints);

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
function testPointsIteratorInitializeDouble(logger as Logger) as Boolean {
    var pi = PointsIterator.FromPoints([
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
function testPointsIteratorInitializeTriple(logger as Logger) as Boolean {
    var pi = PointsIterator.FromPoints([
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
