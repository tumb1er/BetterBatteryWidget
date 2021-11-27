import Toybox.Lang;
using Toybox.System;
using Toybox.Test;


(:background)
class BatteryPoint {
    /* 
    Serialization format: UINT32 LE
    Bits format: <22bit timestamp offset> <10 bit value>
    */
    static const MASK_LEN = 11;
    static const MASK = 1 << MASK_LEN - 1;
    private var ts as Number = 0;
    private var value as Float = 0.0;

    (:debug)
    public static function fromArray(d as StatePoint?) as BatteryPoint? {
        if (d == null) { 
            return null;
        }
        d = d as StatePoint;
        return new BatteryPoint(d[0] as Number, d[1] as Float);
    }

    (:debug)
    public static function fromBytes(b as ByteArray, offset as Number) as BatteryPoint {
        var p = new BatteryPoint(0, 0);
        p.load(b, offset);
        return p;
    }

    public function initialize(ts as Number, value as Float) {
        self.ts = ts;
        self.value = value;
    }

    public function save(b as ByteArray, offset as Number) as Void {
        var n = self.ts << BatteryPoint.MASK_LEN;
        n += (self.value * 10).toNumber() & BatteryPoint.MASK;
        for (var i = offset + 3; i >= offset; i--) {
            b[i] = n % 256;
            n /= 256;
        }
    }

    public function load(b as ByteArray, offset as Number) as Void {
        var n = b[offset].toNumber();
        System.println(n);
        for (var i = offset + 1; i < offset + 4; i++) {
            n *= 256;
            n += b[i];
            System.println(b[i]);
        }
        System.println(n);
        var v = n & BatteryPoint.MASK;
        value = v.toFloat() / 10.0;
        ts = n >> BatteryPoint.MASK_LEN;
    }

    public function getTS() as Number {
        return self.ts;
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
    var p = BatteryPoint.fromArray([123, 22.2]);
    assert_equal(p.getTS(), 123, "unexpected ts");
    assert_equal(p.getValue(), 22.2, "unexpected value");

    return true;
}

(:test)
function testBatteryPointFromBytes(logger as Logger) as Boolean {
    var n = 123 << 11 + 222;
    var b = new [8]b;
    System.println(n);
    b.encodeNumber(n, Lang.NUMBER_FORMAT_UINT32, {:offset => 4, :endianness => Lang.ENDIAN_BIG});
    System.println(b);
    var p = BatteryPoint.fromBytes(b, 4);
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