import Toybox.Lang;
import Toybox.Test;
import Toybox.Math;


(:background :glance)
class BatteryPoint {
    /* 
    Serialization format: UINT32 LE
    Bits format: <18bit timestamp offset> <14 bit value>
    Encoded timestamp max: 2^18 * 15 seconds, or 45 days
    Encoded value range: 0-10000 (0.01 percent accuracy)
    */
    private static const RATIO = 100.0; // Value multiplier to make natural number.
    private static const STEP = 15;  // Time resolution.
    private static const MASK_LEN = 14;
    private static const MAX_TS = STEP << (32 - MASK_LEN); // max TS in 15-seconds intervals
    private static const MAX_VALUE = 100.0;
    private static const MASK = 1 << MASK_LEN - 1;
    private var ts as Number = 0;
    private var value as Float = 0.0;

    public static function FromArray(d as StatePoint?) as BatteryPoint? {
        if (d == null) { 
            return null;
        }
        d = d as StatePoint;
        return new BatteryPoint(d[0] as Number, d[1] as Float);
    }

    public static function FromBytes(b as PointsContainer, idx as Number) as BatteryPoint {
        var p = new BatteryPoint(0, 0);
        p.load(b, idx);
        return p;
    }

    public function initialize(ts as Number, value as Float or Number) {
        self.ts = ts;
        self.value = value.toFloat();
    }

    public function align() as BatteryPoint {
        self.ts = Math.floor(ts / BatteryPoint.STEP) * BatteryPoint.STEP;
        self.value = Math.round(self.value * BatteryPoint.RATIO) / BatteryPoint.RATIO;
        return self;
    }

    public function validate()  as Void {
        if (ts > MAX_TS || ts < 0) {
            throw new Lang.InvalidValueException(Lang.format("timestamp out of range: $1$", [ts]));
        }
        if (value > MAX_VALUE || value < 0) {
            throw new Lang.InvalidValueException(Lang.format("value out of range: $1$", [value]));
        }
        return;
    }

    public function save(b as PointsContainer, idx as Number) as Void {
        // Math.floor тут для того, чтобы при сравнении с текущим временем никогда не получать значения из будущего
        var n = Math.floor(self.ts / BatteryPoint.STEP).toNumber() << BatteryPoint.MASK_LEN;
        n += Math.round(self.value * BatteryPoint.RATIO).toNumber() & BatteryPoint.MASK;
        b.encode(n.toNumber(), idx);
    }

    public function load(b as PointsContainer, idx as Number) as Void {
        var n = b.decode(idx);
        var v = n & BatteryPoint.MASK;
        value = v.toFloat() / BatteryPoint.RATIO;
        ts = (n >> BatteryPoint.MASK_LEN) * BatteryPoint.STEP;
    }

    public function getTS() as Number {
        return self.ts;
    }

    public function shiftTS(delta as Number) as Void {
        self.ts += delta;
    }

    public function getValue() as Float {
        return self.value;
    }

    (:debug)
    public function toString() as String {
        return Lang.format("<$1$ $2$>", [self.ts, self.value]);
    }
}

(:test)
function testBatteryPointFromArray(logger as Logger) as Boolean {
    var p = BatteryPoint.FromArray([123, 22.2] as StatePoint);
    assert_equal(p.getTS(), 123, "unexpected ts");
    assert_equal(p.getValue(), 22.2, "unexpected value");

    return true;
}

(:test)
function testBatteryPointFromBytes(logger as Logger) as Boolean {
    var expected = new BatteryPoint(120, 22.22);
    var b = new [8]b;
    var pc = new PointsContainer(b);
    expected.save(pc, 1);
    var p = BatteryPoint.FromBytes(pc, 1);
    assert_equal(p.getTS(), expected.getTS(), "unexpected ts");
    assert_equal(p.getValue(), expected.getValue(), "unexpected value");
    return true;
}

(:test)
function testBatteryPointAlign(logger as Logger) as Boolean {
    var ts = 129;
    var value = 12.349; 
    var step = 15;
    var ratio = 100.0;
    var p = BatteryPoint.FromArray([ts, value] as StatePoint);
    var result = p.align();
    assert_point_equal(p, [Math.floor(ts / step.toFloat()).toNumber() * step, Math.round(value * ratio) / ratio], "unaligned");
    assert_point_equal(result, p, "return value mismatch");
    return true;
}

(:test)
function testBatteryPointSaveLoad(logger as Logger) as Boolean {
    var expected = new BatteryPoint(120, 22.34);
    var b = new [8]b;
    var pc = new PointsContainer(b);
    expected.save(pc, 1);
    var p = BatteryPoint.FromBytes(pc, 1);
    assert_point_equal(p, [expected.getTS(), expected.getValue()], "invariant changed");
    return true;
}
