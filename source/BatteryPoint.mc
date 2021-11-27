import Toybox.Lang;
using Toybox.Test;


(:background)
class BatteryPoint {
    /* 
    Serialization format: UINT32 LE
    Bits format: <22bit timestamp offset> <10 bit value>
    */
    public static const SIZE = 4; // bytes used to store BatteryPoint
    private static const MAX_TS = 1 << 22;
    private static const MAX_VALUE = 100.0;
    private static const MASK_LEN = 11;
    private static const MASK = 1 << MASK_LEN - 1;
    private var ts as Number = 0;
    private var value as Float = 0.0;

    (:debug)
    public static function FromArray(d as StatePoint?) as BatteryPoint? {
        if (d == null) { 
            return null;
        }
        d = d as StatePoint;
        return new BatteryPoint(d[0] as Number, d[1] as Float);
    }

    (:debug)
    public static function FromBytes(b as ByteArray, offset as Number) as BatteryPoint {
        var p = new BatteryPoint(0, 0);
        p.load(b, offset);
        return p;
    }

    public function initialize(ts as Number, value as Float) {
        self.ts = ts;
        self.value = value;
    }

    public function validate()  as Void {
        if (ts > MAX_TS || ts < 0) {
            throw new Lang.InvalidValueException("timestamp out of range");
        }
        if (value > MAX_VALUE || value < 0) {
            throw new Lang.InvalidValueException("value out of range");
        }
        return;
    }

    public function save(b as ByteArray, offset as Number) as Void {
        var n = self.ts << BatteryPoint.MASK_LEN;
        n += (self.value * 10).toNumber() & BatteryPoint.MASK;
        encodeNumber(b, n, offset);
    }

    public function load(b as ByteArray, offset as Number) as Void {
        var n = decodeNumber(b, offset);
        var v = n & BatteryPoint.MASK;
        value = v.toFloat() / 10.0;
        ts = n >> BatteryPoint.MASK_LEN;
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
    var p = BatteryPoint.FromArray([123, 22.2]);
    assert_equal(p.getTS(), 123, "unexpected ts");
    assert_equal(p.getValue(), 22.2, "unexpected value");

    return true;
}

(:test)
function testBatteryPointFromBytes(logger as Logger) as Boolean {
    var n = 123 << 11 + 222;
    var b = new [8]b;
    b.encodeNumber(n, Lang.NUMBER_FORMAT_UINT32, {:offset => 4, :endianness => Lang.ENDIAN_BIG});
    var p = BatteryPoint.FromBytes(b, 4);
    assert_equal(p.getTS(), 123, "unexpected ts");
    assert_equal(p.getValue(), 22.2, "unexpected value");
    return true;
}

(:test)
function testBatteryPointLoad(logger as Logger) as Boolean {
    var n = 123 << 11 + 222;
    var b = new [8]b;
    b.encodeNumber(n, Lang.NUMBER_FORMAT_UINT32, {:offset => 4, :endianness => Lang.ENDIAN_BIG});
    var p = new BatteryPoint(1, 1.0);
    p.load(b, 4);
    assert_equal(p.getTS(), 123, "unexpected dst ts");
    assert_equal(p.getValue(), 22.2, "unexpected dst value");
    return true;
}

(:test)
function testBatteryPointSave(logger as Logger) as Boolean {
    var n = 123 << 11 + 222;
    var b = new [8]b;
    b.encodeNumber(n, Lang.NUMBER_FORMAT_UINT32, {:offset => 4, :endianness => Lang.ENDIAN_BIG});
    var d = new[8]b;
    var p = new BatteryPoint(123, 22.2);
    p.save(d, 4);
    assert_equal(b, d, "unexpected bytes");
    return true;
}