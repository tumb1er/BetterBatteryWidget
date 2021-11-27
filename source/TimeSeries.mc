import Toybox.Lang;
import Toybox.Test;
using Toybox.System;

typedef StatePoint as Array<Number or Float>; // [ts, percent]
typedef StatePoints as Array<StatePoint>;


(:background)
class TimeSeriesOpts {
    public static const SIZE = 8; // bytes used to store TimeSeriesOpts
    private const START_SIZE = 4; // bytes for storing start timestamp
    private const OFFSET_BITS = 16; // bytes for storing offset
    private const OFFSET_MASK = 1 << OFFSET_BITS - 1; // mask for offset
    private var mStart as Number;  // iterator start timestamp
    private var mSize as Number; // unpacked size
    private var mOffset as Number; // zero element offset

    public function initialize(start as Number, size as Number, offset as Number) as Void {
        mStart = start;
        mSize = size;
        mOffset = offset;
    }

    public function save(b as ByteArray, offset as Number) as Void {
        b = encodeNumber(b, mStart, offset);
        offset += START_SIZE;
        var n = mSize << OFFSET_BITS + mOffset;
        b = encodeNumber(b, n, offset);
    }  
    
    public function load(b as ByteArray, offset as Number) as Void {
        mStart = decodeNumber(b, offset);
        offset += START_SIZE;
        var n = decodeNumber(b, offset);
        mSize = n >> OFFSET_BITS;
        mOffset = n & OFFSET_MASK;
    }

    function getStart() as Number {
        return mStart;
    }

    function getSize() as Number {
        return mSize;
    }

    function getOffset() as Number {
        return mOffset;
    }
}

(:background)
class TimeSeries {

    // static const MAX_TS = 1 << 22;
    // const MAX_VALUE = 1 << 10;  // right 10 bits
    // const INT32_MASK = 1l << 32;
    // const INT16_MASK = 1l << 16;
    // const LOW_MASK = INT32_MASK - 1;
    // const HIGH_MASK = LOW_MASK << 32;

    /*
    int32 format:
    <ts 22 bit as offset in seconds><value 10 bit as battery ppm>

    * 48 days vector duration (2^22 seconds)
    * ts is stored as offset from start
    * value accuracy is 0.1%

    last array value contains: (start ts) << 32 | size << 16 | offset

    */
    private var mPoints as ByteArray;  // packed uint32 points + int64 opts
    private var mSize as Number; // unpacked size
    private var mStart as Number;  // iterator start timestamp
    private var mOffset as Number; // zero element offset
    private var mCapacity as Number; // max memory for points array in int32 values
    private var log as Log;

    public static function Empty(capacity as Number) as TimeSeries {
        var points = new [capacity * BatteryPoint.SIZE + TimeSeriesOpts.SIZE]b;
        return new TimeSeries(points);
    }

    (:debug)
    public static function FromPoints(points as StatePoints) as TimeSeries {
        var size = points.size();
        if (size == 0) {
            return TimeSeries.Empty(0);
        }
        var start = points[0][0] as Number;
        var values = new [size * BatteryPoint.SIZE + TimeSeriesOpts.SIZE]b;
        var opts = new TimeSeriesOpts(start, size, 0);
        opts.save(values, size * BatteryPoint.SIZE);
        var point = new BatteryPoint(0, 0);
        for (var i=0; i<size; i++) {
            var ts = (points[i][0] - start) as Number;
            var value = points[i][1];
            point.initialize(ts, value);
            point.validate();
            point.save(values, i * BatteryPoint.SIZE);
        }
        return new TimeSeries(values);
    }

    /*
    Accepts an array where last element is packed start timestamp + points count, and
    all previous are packed points.
    */
    public function initialize(points as ByteArray) as Void {
        log = new Log("TS");
        var size = points.size();
        if (size == 0) {
            size = TimeSeriesOpts.SIZE;
            points = new [TimeSeriesOpts.SIZE]b;
        }
        var opts = new TimeSeriesOpts(0, 0, 0);
        opts.load(points, size - TimeSeriesOpts.SIZE); 
        mStart = opts.getStart();
        mSize = opts.getSize();
        mOffset = opts.getOffset();
        mCapacity = (size - TimeSeriesOpts.SIZE) / BatteryPoint.SIZE;
        mPoints = points;
    }

    public function serialize() as ByteArray {
        // sync size, offset and start values
        var opts = new TimeSeriesOpts(mStart, mSize, mOffset);
        opts.save(mPoints, mCapacity * BatteryPoint.SIZE);
        // log.debug("serialized", mPoints);
        return mPoints;
    }

    public function size() as Number {
        return mSize;
    }

    public function get(idx as Number) as BatteryPoint {
        idx = (idx + mOffset) % mCapacity;
        return BatteryPoint.FromBytes(idx * BatteryPoint.SIZE);
    }

    public function add(ts as Number, value as Float) as Void {
        log.debug("adding", [ts, value, mSize, mOffset]);
        if (mSize == 0) {
            mStart = ts;
        }
        var point = new BatteryPoint(0, 0);
        var delta = ts - mStart;
        if (mSize == mCapacity) {
            // points array is full, removing oldest element
            log.debug("rotating", [mPoints, mOffset, mCapacity]);
            // cleanup
            mPoints[mOffset] = 0l;
            // move offset to next element
            mOffset = (mOffset + 1) % mCapacity;
            if (mOffset == 0) {
                // align values to first TS
                var start = point.load(mPoints, 0);
                log.debug("align", start.getTS());
                align(mStart + start.getTS());
                delta = ts - mStart;
            }
            // lower size value
            mSize -= 1;
        }
        point.initialize(delta, value);
        point.validate();
        var idx = (mSize + mOffset) % mCapacity;
        point.save(idx * BatteryPoint.SIZE);
        mSize += 1;
        serialize();
        // log.debug("add", mPoints);
    }

    private function align(ts as Number) as Void {
        var delta = (ts - mStart).toLong();
        log.debug("align to ", [ts, delta]);
        log.debug("before", mPoints);
        var point = new BatteryPoint(0, 0);
        for (var i = 0; i < mSize; i++) {
            point.load(mPoints, i * BatteryPoint.SIZE);
            point.shiftTS(-delta);
            point.save(mPoints, i * BatteryPoint.SIZE);
        }
        log.debug("after", mPoints);
        mStart = ts;
    }

    public function set(i as Number, ts as Number, value as Float) as Void {
        log.debug("setting", [i, ts, value]);
        var delta = ts - mStart;
        var point = new BatteryPoint(ts, value);
        point.validate();
        var idx = (i + mOffset) % mCapacity;
        point.save(mPoints, idx * BatteryPoint.SIZE);
        if (i == 0 && mStart != ts) {
            self.align(ts);
        }
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

    (:debug)
    public function getPoints() as ByteArray {
        return mPoints;
    }

    (:debug)
    public function getStart() as Number {
        return mStart;
    }

    (:debug)
    public function getOffset() as Number {
        return mOffset;
    }
}

(:test)
function testTimeSeriesOptsNew(logger as Logger) as Boolean {
    var opts = new TimeSeriesOpts(1, 2, 3);
    assert_equal(opts.getStart(), 1, "unexpected start");
    assert_equal(opts.getSize(), 2, "unexpected size");
    assert_equal(opts.getOffset(), 3, "unexpected offset");    
    return true;
}

(:test)
function testTimeSeriesOptsLoad(logger as Logger) as Boolean {
    var low = 2l << 16 + 3l;
    var high = 1l;
    var value = high << 32 + low;
    var b = new [10]b;
    b.encodeNumber(high, Lang.NUMBER_FORMAT_UINT32, {:offset => 2, :endianness => Lang.ENDIAN_BIG});
    b.encodeNumber(low, Lang.NUMBER_FORMAT_UINT32, {:offset => 6, :endianness => Lang.ENDIAN_BIG});

    var opts = new TimeSeriesOpts(0, 0, 0);
    opts.load(b, 2);
    assert_equal(opts.getStart(), 1, "unexpected start");
    assert_equal(opts.getSize(), 2, "unexpected size");
    assert_equal(opts.getOffset(), 3, "unexpected offset");
    return true;
}

(:test)
function testTimeSeriesOptsSave(logger as Logger) as Boolean {
    var low = 2l << 16 + 3l;
    var high = 1l;
    var value = high << 32 + low;
    var b = new [10]b;
    b.encodeNumber(high, Lang.NUMBER_FORMAT_UINT32, {:offset => 2, :endianness => Lang.ENDIAN_BIG});
    b.encodeNumber(low, Lang.NUMBER_FORMAT_UINT32, {:offset => 6, :endianness => Lang.ENDIAN_BIG});
    var d = new [10]b;

    var opts = new TimeSeriesOpts(1, 2, 3);
    opts.save(d, 2);
    assert_equal(b, d, "unexpected bytes");
    return true;
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
    expected = 123l << 32 + 1 << 16;  // start + size
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
    expected = 123l << 32 + 2 << 16;  // start + size
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
    expected = 123l << 32 + 3 << 16;  // start + size
    Test.assertEqualMessage(data[data.size() - 1], expected, "unexpected serialized value");

    return true;
}

(:test)
function testTimeSeriesAdd(logger as Logger) as Boolean {
    var pi = new TimeSeries([0l, 0l, 0l, 0l] as Array<Long>);

    pi.add(123, 11.1);

    Test.assertEqualMessage(pi.size(), 1, "unexpected size");
    Test.assertEqualMessage(pi.getStart(), 123, "unexpected start $1$");
    var points = pi.getPoints();
    Test.assertEqualMessage(points.size(), 4, "unexpected packed length");
    var expected = (0 << 10 + 111).toLong();
    Test.assertEqualMessage(points[0], expected, Lang.format("unexpected packed long $1$ != $2$", [points[0], expected]));

    pi.add(125, 22.2);

    Test.assertEqualMessage(pi.size(), 2, Lang.format("unexpected size $1$", [pi.size()]));
    points = pi.getPoints();
    Test.assertEqualMessage(points.size(), 4, "unexpected length");
    expected = (0l << 10 + 111l + ((125 - 123) << 10 + 222l) << 32).toLong();
    Test.assertEqualMessage(points[0], expected, "unexpected packed long");

    pi.add(126, 33.3);

	Test.assertEqualMessage(pi.size(), 3, "unexpected size");
    points = pi.getPoints();
    Test.assertEqualMessage(points.size(), 4, "unexpected length");
    expected = (126 - 123).toLong() << 10 + 333l;
    Test.assertEqualMessage(points[1], expected, "unexpected packed long");

    pi.add(127, 44.4);
    pi.add(128, 55.5);
    pi.add(129, 66.6);  // here array is full;
    Test.assertEqualMessage(pi.getOffset(), 0, "unexpected offset");

    pi.add(130, 77.7);
    
    Test.assertEqualMessage(pi.size(), 6 - 2 + 1, "unexpected size");
    Test.assertEqualMessage(pi.getStart(), 123, Lang.format("unexpected start $1$", [pi.getStart()]));
    Test.assertEqualMessage(pi.getOffset(), 1, "unexpected offset");
    points = pi.getPoints();
    Test.assertEqualMessage(points.size(), 4, "unexpected packed length");
    expected = ((130 - 123) << 10 + 777).toLong();
    Test.assertEqualMessage(points[0], expected, Lang.format("unexpected packed long $1$ != $2$", [points[0], expected]));

    pi.add(131, 88.8);

    points = pi.getPoints();
    expected = ((130 - 123) << 10 + 777 + ((131 - 123) << 10 + 888l) << 32).toLong();
    Test.assertEqualMessage(points[0], expected, Lang.format("unexpected packed long $1$ != $2$", [points[0], expected]));
    Test.assertEqualMessage(pi.getOffset(), 1, "unexpected offset");

    pi.add(132, 99.9);

    Test.assertEqualMessage(pi.getOffset(), 2, "unexpected offset");
    points = pi.getPoints();
    Test.assertEqualMessage(points.size(), 4, "unexpected packed length");
    expected = ((132 - 123) << 10 + 999).toLong();
    Test.assertEqualMessage(points[1], expected, Lang.format("unexpected packed long $1$ != $2$", [points[0], expected]));
    pi.serialize();
    expected = 123l << 32 + 5 << 16 + 2;  // start + size + offset
    Test.assertEqualMessage(points[points.size() - 1], expected,
                            Lang.format("unexpected serialized value $1$ != $2$", [points[points.size() - 1], expected]));
    Test.assertEqualMessage(pi.getOffset(), 2, "unexpected offset");
    Test.assertEqualMessage(pi.getStart(), 123, Lang.format("unexpected start $1$", [pi.getStart()]));
    var p = pi.get(0);
    Test.assertEqualMessage(p.getTS(), 128, Lang.format("unexpected first ts $1$ $2$", [p.getTS(), pi.getPoints()]));
    Test.assertEqualMessage(p.getValue(), 55.5, "unexpected first value");

    // overwriting previous items while rotated again to zero offset
    pi.add(133, 11.2);

    pi.add(134, 22.3);

    Test.assertEqualMessage(pi.getOffset(), 0, "unexpected offset");
    points = pi.getPoints();
    pi.serialize();
    expected = 130l << 32 + 5 << 16 + 0;  // start + size + offset
    Test.assertEqualMessage(points[points.size() - 1], expected, 
        Lang.format("unexpected serialized value $1$ != $2$", [points[points.size() - 1], expected]));
    expected = ((130 - 130) << 10 + 777 + ((131-130) << 10 + 888l) << 32).toLong();
    Test.assertEqualMessage(points[0], expected, Lang.format("unexpected packed long $1$ != $2$", [points[0], expected]));
    expected = ((134 - 130) << 10 + 223).toLong();
    Test.assertEqualMessage(points[2], expected, Lang.format("unexpected packed long $1$ != $2$", [points[0], expected]));


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
    var pi = TimeSeries.Empty(6);
    Test.assertEqualMessage(pi.size(), 0, "unexpected length");

    return true;
}
