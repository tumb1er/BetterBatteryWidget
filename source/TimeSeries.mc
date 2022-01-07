import Toybox.Lang;
import Toybox.Test;
using Toybox.System;

typedef StatePoint as Array<Number or Float>; // [ts, percent]
typedef StatePoints as Array<StatePoint>;


(:background)
class TimeSeriesOpts {
    private static const SIZE = 2; // uint32 used to store TimeSeriesOpts
    private const OFFSET_BITS = 16; // bytes for storing offset
    private const OFFSET_MASK = 1 << OFFSET_BITS - 1; // mask for offset

    public var start as Number?;  // iterator start timestamp
    public var size as Number?; // unpacked size
    public var offset as Number?; // zero element offset
    public var capacity as Number?; // derived from array

    (:debug)
    public static function FromBytes(b as PointsContainer) as TimeSeriesOpts {
        var opts = new TimeSeriesOpts(0, 0, 0, 0);
        opts.load(b);
        return opts;
    }

    public function initialize(start as Number, size as Number, offset as Number, capacity as Number) {
        self.start = start;
        self.size = size;
        self.offset = offset;
        self.capacity = capacity;
    }

    public function save(b as PointsContainer) as Void {
        b.encode(start, capacity);
        var n = size << OFFSET_BITS + offset;
        b.encode(n, capacity + 1);
    }  
    
    public function load(b as PointsContainer) as Void {
        self.capacity = b.size() - SIZE;
        self.start = b.decode(self.capacity);
        var n = b.decode(self.capacity + 1);
        self.size = n >> OFFSET_BITS;
        self.offset = n & OFFSET_MASK;
    }

    public function empty() as PointsContainer {
        return PointsContainer.New(capacity + SIZE);
    }

    public function toString() as String {
        return Lang.format("{$1$: +$2$, $3$/$4$}", [start, size, offset, capacity]);
    }

    public function index(idx as Number) as Number {
        return (idx + offset) % capacity;
    }

    public function full() as Boolean {
        return size == capacity;
    }
}

(:background)
class TimeSeries {
    /*
    int32 format:
    <ts 22 bit as offset in seconds><value 10 bit as battery ppm>

    * 48 days vector duration (2^22 seconds)
    * ts is stored as offset from start
    * value accuracy is 0.1%

    last array value contains: (start ts) << 32 | size << 16 | offset
    */

    private var points as PointsContainer?;  // packed uint32 points + int64 opts
    private var opts as TimeSeriesOpts?;
    // private var log as Log;

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
    public function initialize(points as ByteArray or PointsContainer) {
        // log = new Log("TS");
        if (!(points instanceof PointsContainer)) {
            points = new PointsContainer(points);
        }
        var size = points.size();
        if (size == 0) {
            points = new TimeSeriesOpts(0, 0, 0, 0).empty();
        }
        self.opts = new TimeSeriesOpts(0, 0, 0, size);
        self.opts.load(points); 
        self.points = points;
    }

    public function serialize() as ByteArray {
        // sync size, offset and start values
        opts.save(points);
        // log.debug("serialized", mPoints);
        return points.serialize();
    }

    public function size() as Number {
        return opts.size;
    }

    public function print() as Void {
        System.print(opts.toString());
        var point = new BatteryPoint(0, 0);
        System.print("[");
        for (var i = 0; i< opts.size; i ++) {
            point.load(points, i);
            if (i > 0) {
                System.print(", ");
            }
            System.print(point.toString());
        }
        System.println("]");
    }

    public function get(idx as Number) as BatteryPoint {
        var point = BatteryPoint.FromBytes(points, opts.index(idx));
        point.shiftTS(opts.start);
        return point;
    }

    public function add(p as BatteryPoint) as Void {
        // log.debug("adding", [ts, value, opts.toString()]);
        var ts = p.getTS();
        var value = p.getValue();
        if (opts.size == 0) {
            opts.start = p.getTS();
        }
        var point = new BatteryPoint(0, 0);
        var delta = ts - opts.start;
        var needAlign = false;
        if (opts.full()) {
            // points array is full, removing oldest element
            // log.debug("rotating", [opts.toString()]);
            // move offset to next element
            var newOffset = opts.index(1);
            if (newOffset == 0) {
                needAlign = true;
            }
            opts.offset = newOffset;
            // lower size value
            opts.size -= 1;
        }
        point.initialize(delta, value);
        point.validate();
        var idx = opts.index(opts.size);
        point.save(points, idx);
        opts.size += 1;
        if (needAlign) {
            var first = get(0);
            align(first.getTS());
        }
        serialize();
    }

    private function align(ts as Number) as Void {
        var delta = ts - opts.start;
        // log.debug("align to ", [ts, delta]);
        // log.msg("before");
        // print();
        var point = new BatteryPoint(0, 0);
        for (var i = 0; i < opts.size; i++) {
            point.load(points, i);
            point.shiftTS(-delta);
            point.save(points, i);
        }
        // log.msg("after");
        // print();
        opts.start = ts;
    }

    public function set(i as Number, point as BatteryPoint) as Void {
        // log.debug("setting", [i, ts, value]);
        var ts = point.getTS();
        var value = point.getValue();
        var delta = ts - opts.start;
        point = new BatteryPoint(delta, value);
        point.validate();
        var idx = opts.index(i);
        point.save(points, idx);
        if (idx == 0 && opts.start != ts) {
            self.align(ts);
        }
    }

    public function last() as BatteryPoint? {
        if (opts.size == 0) {
            return null;
        }
        return get(opts.size - 1);
    }

    public function first() as BatteryPoint? {
        if (opts.size == 0) {
            return null;
        }
        return get(0);
    }

    (:debug)
    public function getPoints() as PointsContainer {
        return points;
    }

    (:debug)
    public function getStart() as Number {
        return opts.start;
    }

    (:debug)
    public function getOffset() as Number {
        return opts.offset;
    }
}

(:test)
function testTimeSeriesOptsNew(logger as Logger) as Boolean {
    var opts = new TimeSeriesOpts(1, 2, 3, 4);
    assert_equal(opts.start, 1, "unexpected start");
    assert_equal(opts.size, 2, "unexpected size");
    assert_equal(opts.offset, 3, "unexpected offset");    
    assert_equal(opts.capacity, 4, "unexpected capacity");
    return true;
}

(:test)
function testTimeSeriesOptsTosString(logger as Logger) as Boolean {
    var opts = new TimeSeriesOpts(1, 2, 3, 4);
    assert_equal(opts.toString() instanceof Lang.String, true, "unexpected return type");
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
    assert_equal(opts.start, 1, "unexpected start");
    assert_equal(opts.size, 2, "unexpected size");
    assert_equal(opts.offset, 3, "unexpected offset");    
    assert_equal(opts.capacity, 4, "unexpected capacity");
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
function assert_slice_equal(b as ByteArray, offset as Number, expected as Array, msg as String) as Void {
    var p = BatteryPoint.FromBytes(new PointsContainer(b), offset / 4);
    assert_point_equal(p, expected, msg);
}

(:debug)
function assert_point_equal(point as BatteryPoint or Array, expected as BatteryPoint or Array, msg as String) as Void {
    if (point instanceof BatteryPoint) {
        point = [point.getTS(), point.getValue()];
    }
    if (expected instanceof BatteryPoint) {
        expected = [expected.getTS(), expected.getValue()];
    }
    assert_array_equal(point, expected, msg);
}

(:debug)
function assert_opts_equal(b as ByteArray, expected as Array) as Void {
    var opts = TimeSeriesOpts.FromBytes(new PointsContainer(b));
    assert_array_equal([opts.start, opts.size, opts.offset], expected, "unexpected serialized opts");
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
    var bp = BatteryPoint.FromArray([1000, 55.55] as StatePoint);
    bp.align();
    var pi = TimeSeries.FromPoints([[bp.getTS(), bp.getValue()] as StatePoint] as StatePoints);

    var points = pi.serialize();
    var ts = new TimeSeries(points);

    assert_equal(ts.size(), 1, "unexpected size");
    assert_point_equal(ts.get(0), bp, "point1 mismatch");
    return true;
}

(:test)
function testTimeSeriesInitializeDouble(logger as Logger) as Boolean {
    var bp1 = BatteryPoint.FromArray([1000, 55.55] as StatePoint).align();
    var bp2 = BatteryPoint.FromArray([1030, 77.77] as StatePoint).align();
    
    var pi = TimeSeries.FromPoints([
        [bp1.getTS(), bp1.getValue()] as StatePoint,
        [bp2.getTS(), bp2.getValue()] as StatePoint,
    ] as StatePoints);

    assert_equal(pi.size(), 2, "unexpected size");
    assert_equal(pi.getStart(), bp1.getTS(), "unexpected start");
    var points = pi.serialize();
    var ts = new TimeSeries(points);

    assert_equal(ts.size(), 2, "unexpected size");
    assert_point_equal(ts.get(0), bp1, "point1 mismatch");
    assert_point_equal(ts.get(1), bp2, "point2 mismatch");
    return true;
}

(:test)
function testTimeSeriesAdd(logger as Logger) as Boolean {
    var pi = TimeSeries.Empty(2);
    var bp1 = BatteryPoint.FromArray([1000, 11.11] as StatePoint).align();

    // 0 - [x, x]
    pi.add(bp1);
    // 1000 - [1000, x]

    var points = pi.serialize();
    var ts = new TimeSeries(points);

    assert_equal(ts.size(), 1, "unexpected size");
    assert_point_equal(ts.get(0), bp1, "point1 mismatch");

    var bp2 = BatteryPoint.FromArray([1030, 22.22] as StatePoint).align();

    pi.add(bp2);
    // 1000 - [1000, 1030]

    assert_equal(pi.size(), 2, "unexpected size");
    points = pi.serialize();
    ts = new TimeSeries(points);
    assert_equal(ts.size(), 2, "unexpected size");
    assert_point_equal(ts.get(0), bp1, "point1 mismatch");
    assert_point_equal(ts.get(1), bp2, "point2 mismatch");
    
    // array is full here - point rotation expected. Offset is not zero - skip align
    var bp3 = BatteryPoint.FromArray([1075, 33.33] as StatePoint).align();

    pi.add(bp3);
    // 1000 - [1000, 1030]
    // 1000 - [1075, 1030]

    points = pi.serialize();
    ts = new TimeSeries(points);
    assert_equal(ts.size(), 2, "unexpected size");
    assert_point_equal(ts.get(0), bp2, "point2 mismatch");
    assert_point_equal(ts.get(1), bp3, "point3 mismatch");
    assert_equal(pi.getOffset(), 1, "unexpected offset");

    // offset rotation - align expected
    var bp4 = BatteryPoint.FromArray([1135, 44.44] as StatePoint).align();

    pi.add(bp4);
    // 1075 - [1075, 1135]
    
    points = pi.serialize();
    ts = new TimeSeries(points);
    assert_equal(ts.size(), 2, "unexpected size");
    assert_point_equal(ts.get(0), bp3, "point3 mismatch");
    assert_point_equal(ts.get(1), bp4, "point4 mismatch");
    assert_equal(pi.getOffset(), 0, "unexpected offset");
    return true;
}

(:test)
function testTimeSeriesSet(logger as Logger) as Boolean {
    var bp1 = BatteryPoint.FromArray([1000, 55.55] as StatePoint).align();
    var bp2 = BatteryPoint.FromArray([1030, 77.77] as StatePoint).align();
    
    var pi = TimeSeries.FromPoints([
        [bp1.getTS(), bp1.getValue()] as StatePoint, 
        [bp2.getTS(), bp2.getValue()] as StatePoint,
    ] as StatePoints);

    var bp3 = BatteryPoint.FromArray([1015, 33.33] as StatePoint).align();
    
    pi.set(0, bp3);
    
    var points = pi.serialize();
    var ts = new TimeSeries(points);
    assert_equal(ts.size(), 2, "unexpected size");
    assert_point_equal(ts.get(0), bp3, "point1 mismatch");
    assert_point_equal(ts.get(1), bp2, "point2 mismatch");

    var bp4 = BatteryPoint.FromArray([1060, 99.99] as StatePoint).align();
    // points rotation, offset = 1
    pi.add(bp4);
    
    var bp5 = BatteryPoint.FromArray([1115, 88.88] as StatePoint).align();
    pi.set(0, bp5);

    points = pi.serialize();
    ts = new TimeSeries(points);

    assert_equal(ts.size(), 2, "unexpected size");
    assert_point_equal(ts.get(0), bp5, "point1 mismatch");
    assert_point_equal(ts.get(1), bp4, "point2 mismatch");
    return true;    
}

(:test) 
function testTimeSeriesEmpty(logger as Logger) as Boolean {
    var pi = TimeSeries.Empty(6);
    assert_equal(pi.size(), 0, "unexpected length");

    return true;
}
