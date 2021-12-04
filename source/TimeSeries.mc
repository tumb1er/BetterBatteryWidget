import Toybox.Lang;
import Toybox.Test;
using Toybox.System;

typedef StatePoint as Array<Number or Float>; // [ts, percent]
typedef StatePoints as Array<StatePoint>;


(:background)
class TimeSeriesOpts {
    private static const SIZE = 2; // uint32 used to store TimeSeriesOpts
    private const START_SIZE = 4; // bytes for storing start timestamp
    private const OFFSET_BITS = 16; // bytes for storing offset
    private const OFFSET_MASK = 1 << OFFSET_BITS - 1; // mask for offset
    private var mStart as Number;  // iterator start timestamp
    private var mSize as Number; // unpacked size
    private var mOffset as Number; // zero element offset
    private var mCapacity as Number; // derived from array

    (:debug)
    public static function FromBytes(b as PointsContainer) as TimeSeriesOpts {
        var opts = new TimeSeriesOpts(0, 0, 0, 0);
        opts.load(b);
        return opts;
    }

    public function initialize(start as Number, size as Number, offset as Number, capacity as Number) as Void {
        mStart = start;
        mSize = size;
        mOffset = offset;
        mCapacity = capacity;
    }

    public function save(b as PointsContainer) as Void {
        b.encode(mStart, mCapacity);
        var n = mSize << OFFSET_BITS + mOffset;
        b.encode(n, mCapacity + 1);
    }  
    
    public function load(b as PointsContainer) as Void {
        mCapacity = b.size() - SIZE;
        mStart = b.decode(mCapacity);
        var n = b.decode(mCapacity + 1);
        mSize = n >> OFFSET_BITS;
        mOffset = n & OFFSET_MASK;
    }

    public function empty() as PointsContainer {
        return PointsContainer.New(mCapacity + SIZE);
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

    function getCapacity() as Number {
        return mCapacity;
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
        var pc = new TimeSeriesOpts(0, 0, 0, capacity).empty();
        return new TimeSeries(pc);
    }

    (:debug)
    public static function FromPoints(points as StatePoints) as TimeSeries {
        var size = points.size();
        if (size == 0) {
            return TimeSeries.Empty(0);
        }
        var start = points[0][0] as Number;
        var opts = new TimeSeriesOpts(start, size, 0, size);
        var values = opts.empty();
        opts.save(values);
        var point = new BatteryPoint(0, 0);
        for (var i = 0; i < size; i++) {
            var ts = (points[i][0] - start) as Number;
            var value = points[i][1];
            point.initialize(ts, value);
            point.validate();
            point.save(values, i);
        }
        return new TimeSeries(values);
    }

    /*
    Accepts an array where last element is packed start timestamp + points count, and
    all previous are packed points.
    */
    public function initialize(points as ByteArray or PointsContainer) as Void {
        log = new Log("TS");
        if (!(points instanceof PointsContainer)) {
            points = new PointsContainer(points);
        }
        var size = points.size();
        if (size == 0) {
            points = new TimeSeriesOpts(0, 0, 0, 0).empty();
        }
        var opts = new TimeSeriesOpts(0, 0, 0, size);
        opts.load(points); 
        mStart = opts.getStart();
        mSize = opts.getSize();
        mOffset = opts.getOffset();
        mCapacity = opts.getCapacity();
        mPoints = points;
    }

    public function serialize() as ByteArray {
        // sync size, offset and start values
        var opts = new TimeSeriesOpts(mStart, mSize, mOffset, mCapacity);
        opts.save(mPoints);
        // log.debug("serialized", mPoints);
        return mPoints.serialize();
    }

    public function size() as Number {
        return mSize;
    }

    public function print() as Void {
        System.print(Lang.format("[$1$, $2$, $3$]: ", [mStart, mSize, mOffset]));
        var point = new BatteryPoint(0, 0);
        System.print("[");
        for (var i = 0; i< mSize; i ++) {
            point.load(mPoints, i);
            if (i > 0) {
                System.print(", ");
            }
            System.print(point.toString());
        }
        System.println("]");
    }

    public function get(idx as Number) as BatteryPoint {
        var index = ((idx + mOffset) % mCapacity).toNumber();
        var point = BatteryPoint.FromBytes(mPoints, index);
        point.shiftTS(mStart);
        return point;
    }

    public function add(ts as Number, value as Float) as Void {
        log.debug("adding", [ts, value, mSize, mOffset]);
        if (mSize == 0) {
            mStart = ts;
        }
        var point = new BatteryPoint(0, 0);
        var delta = ts - mStart;
        var needAlign = false;
        if (mSize == mCapacity) {
            // points array is full, removing oldest element
            log.debug("rotating", [mPoints, mOffset, mCapacity]);
            // move offset to next element
            var newOffset = (mOffset + 1) % mCapacity;
            if (newOffset == 0) {
                needAlign = true;
            }
            mOffset = newOffset;
            // lower size value
            mSize -= 1;
        }
        point.initialize(delta, value);
        point.validate();
        var idx = (mSize + mOffset) % mCapacity;
        point.save(mPoints, idx);
        mSize += 1;
        if (needAlign) {
            var first = get(0);
            align(first.getTS());
        }
        serialize();
        log.debug("add", mPoints);
    }

    private function align(ts as Number) as Void {
        var delta = (ts - mStart).toLong();
        log.debug("align to ", [ts, delta, mOffset]);
        log.msg("before");
        print();
        var point = new BatteryPoint(0, 0);
        for (var i = 0; i < mSize; i++) {
            point.load(mPoints, i);
            System.println(["<", i, point]);
            point.shiftTS(-delta);
            System.println([">", i, point]);
            point.save(mPoints, i);
        }
        log.debug("after", mPoints);
        mStart = ts;
    }

    public function set(i as Number, ts as Number, value as Float) as Void {
        log.debug("setting", [i, ts, value]);
        var delta = ts - mStart;
        var point = new BatteryPoint(delta, value);
        point.validate();
        var idx = (i + mOffset) % mCapacity;
        point.save(mPoints, idx);
        if (idx == 0 && mStart != ts) {
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
    var opts = new TimeSeriesOpts(1, 2, 3, 4);
    assert_equal(opts.getStart(), 1, "unexpected start");
    assert_equal(opts.getSize(), 2, "unexpected size");
    assert_equal(opts.getOffset(), 3, "unexpected offset");    
    assert_equal(opts.getCapacity(), 4, "unexpected capacity");
    return true;
}

(:test)
function testTimeSeriesOptsLoad(logger as Logger) as Boolean {
    var low = 2l << 16 + 3l;
    var high = 1l;
    var value = high << 32 + low;
    var b = new [4 * 4 + 2 * 4]b;
    b.encodeNumber(high, Lang.NUMBER_FORMAT_UINT32, {:offset => 16, :endianness => Lang.ENDIAN_BIG});
    b.encodeNumber(low, Lang.NUMBER_FORMAT_UINT32, {:offset => 20, :endianness => Lang.ENDIAN_BIG});
    var pc = new PointsContainer(b);
    var opts = new TimeSeriesOpts(0, 0, 0, 0);
    opts.load(pc);
    assert_equal(opts.getStart(), 1, "unexpected start");
    assert_equal(opts.getSize(), 2, "unexpected size");
    assert_equal(opts.getOffset(), 3, "unexpected offset");
    assert_equal(opts.getCapacity(), 4, "unexpected capacity");
    return true;
}

(:test)
function testTimeSeriesOptsSave(logger as Logger) as Boolean {
    var low = 2l << 16 + 3l;
    var high = 1l;
    var value = high << 32 + low;
    var b = new [4 * 4 + 2 * 4]b;
    b.encodeNumber(high, Lang.NUMBER_FORMAT_UINT32, {:offset => 16, :endianness => Lang.ENDIAN_BIG});
    b.encodeNumber(low, Lang.NUMBER_FORMAT_UINT32, {:offset => 20, :endianness => Lang.ENDIAN_BIG});
    var d = new [4 * 4 + 2 * 4]b;
    var pc = new PointsContainer(d);

    var opts = new TimeSeriesOpts(1, 2, 3, 4);
    opts.save(pc);
    assert_equal(b, pc.serialize(), "unexpected bytes");
    return true;
}

(:debug)
function assert_slice_equal(b as ByteArray, offset as Number, expected as StatePoint, msg as String) as Void {
    var p = BatteryPoint.FromBytes(new PointsContainer(b), offset / 4);
    assert_point_equal(p, expected, msg);
}

(:debug)
function assert_point_equal(p1 as BatteryPoint, expected as StatePoint, msg as String) as Void {
    assert_array_equal([p1.getTS(), p1.getValue()], expected, msg);
}

(:debug)
function assert_opts_equal(b as ByteArray, expected as Array<Number>) as Void {
    var opts = TimeSeriesOpts.FromBytes(new PointsContainer(b));
    assert_array_equal([opts.getStart(), opts.getSize(), opts.getOffset()], expected, "unexpected serialized opts");
}

(:test)
function testTimeSeriesInitializeZero(logger as Logger) as Boolean {
    var pi = TimeSeries.FromPoints([] as StatePoints);
    assert_equal(pi.size(), 0, "unexpected size");
    assert_equal(pi.getStart(), 0, "unexpected start");
    var points = pi.getPoints().serialize();
    assert_equal(points.size(), 8, "unexpected packed length");
    var data = pi.serialize();
    assert_equal(data.size(), 8, "unexpected serialized length");
    assert_opts_equal(data, [0, 0, 0]);
	return true;
}

(:test)
function testTimeSeriesInitializeSingle(logger as Logger) as Boolean {
    var pi = TimeSeries.FromPoints([[123, 55.5] as StatePoint] as StatePoints);

	assert_equal(pi.size(), 1, "unexpected size");
    assert_equal(pi.getStart(), 123, "unexpected start");
    var points = pi.getPoints().serialize();
    assert_equal(points.size(), 4 + 8, "unexpected packed length");
    assert_slice_equal(points, 0, [0, 55.5], "unexpected packet point");
    var p = pi.last() as BatteryPoint;
    assert_point_equal(p, [123, 55.5], "unexpected last point");
    var data = pi.serialize();
    assert_equal(data.size(), 4 + 8, "unexpected serialized length");
    assert_opts_equal(data, [123, 1, 0]);
    return true;
}

(:test)
function testTimeSeriesInitializeDouble(logger as Logger) as Boolean {
    var pi = TimeSeries.FromPoints([
        [123, 55.5] as StatePoint, 
        [125, 77.7] as StatePoint,
    ] as StatePoints);

	assert_equal(pi.size(), 2, "unexpected size");
    assert_equal(pi.getStart(), 123, "unexpected start");
    var points = pi.getPoints().serialize();
    assert_equal(points.size(), 4 * 2 + 8, "unexpected length");
    assert_slice_equal(points, 0, [0, 55.5], "unexpected packed point 0");
    assert_slice_equal(points, 4, [2, 77.7], "unexpected packed point 1");
    var p = pi.first() as BatteryPoint;
    assert_point_equal(p, [123, 55.5], "unexpected last point");
    p = pi.last() as BatteryPoint;
    assert_point_equal(p, [125, 77.7], "unexpected last point");
    var data = pi.serialize();
    assert_equal(data.size(), 2 * 4 + 8, "unexpected serialized length");
    assert_opts_equal(data, [123, 2, 0]);
    return true;
}

(:test)
function testTimeSeriesAdd(logger as Logger) as Boolean {
    var pi = TimeSeries.Empty(2);

    // 0 - [x, x]
    pi.add(123, 11.1);
    // 123 - [123, x]

    assert_equal(pi.size(), 1, "unexpected size");
    assert_equal(pi.getStart(), 123, "unexpected start $1$");
    var points = pi.getPoints().serialize();
    assert_equal(points.size(), 2 * 4 + 8, "unexpected packed length");
    assert_slice_equal(points, 0, [0, 11.1], "unexpected packed point 0");

    pi.add(125, 22.2);
    // 123 - [123, 125]

    assert_equal(pi.size(), 2, "unexpected size");
    points = pi.getPoints().serialize();
    assert_equal(points.size(), 2 * 4 + 8, "unexpected length");
    assert_slice_equal(points, 0, [0, 11.1], "unexpected packed point 0");
    assert_slice_equal(points, 4, [2, 22.2], "unexpected packed point 1");
    assert_opts_equal(points, [123, 2, 0]);
    
    // array is full here - point rotation expected. Offset is not zero - skip align
    pi.add(126, 33.3);
    // 123 - [126, 125]

    assert_slice_equal(points, 0, [126 - 123, 33.3], "unexpected packed point 0");
    assert_slice_equal(points, 4, [2, 22.2], "unexpected packed point 1");
    assert_equal(pi.getOffset(), 1, "unexpected offset");

    // offset rotation - align expected
    pi.add(130, 77.7);
    // 126 - [126, 130]
    
    points = pi.getPoints().serialize();
    assert_slice_equal(points, 0, [0, 33.3], "unexpected packed point 0");
    assert_slice_equal(points, 4, [130 - 126, 77.7], "unexpected packed point 1");
    assert_equal(pi.getOffset(), 0, "unexpected offset");
    return true;
}

(:test)
function testTimeSeriesSet(logger as Logger) as Boolean {
    var pi = TimeSeries.FromPoints([
        [123, 55.5] as StatePoint, 
        [125, 77.7] as StatePoint,
    ] as StatePoints);
    
    pi.set(0, 124, 33.3);
    
    var points = pi.getPoints().serialize();
    assert_equal(points.size(), 2 * 4 + 8, "unexpected length");
    assert_slice_equal(points, 0, [0, 33.3], "unexpected packed point 0");
    assert_slice_equal(points, 4, [125 - 124, 77.7], "unexpected packed point 1");
    // points rotation, offset = 1
    pi.add(127, 99.9);
    
    pi.set(0, 130, 88.8);

    assert_slice_equal(points, 0, [127 - 124, 99.9], "unexpected packed point 0");
    assert_slice_equal(points, 4, [130 - 124, 88.8], "unexpected packed point 1");

    return true;    
}

(:test) 
function testTimeSeriesEmpty(logger as Logger) as Boolean {
    var pi = TimeSeries.Empty(6);
    assert_equal(pi.size(), 0, "unexpected length");

    return true;
}
