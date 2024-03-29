import Toybox.Lang;
import Toybox.Test;


(:background :glance)
class PointsContainer {
    private static const POINT_SIZE = 4; // size of single point in bytes
    private var data as ByteArray?;

    public static function New(capacity as Number) as PointsContainer {
        return new PointsContainer(new [capacity * POINT_SIZE]b);
    }

    public function initialize(data as ByteArray) {
        self.data = data;
    }

    public function encode(n as Number, idx as Number) as ByteArray {
        var offset = idx * POINT_SIZE;
        var b = self.data;
        for (var i = offset + POINT_SIZE - 1; i >= offset; i--) {
            var mod = n % 256;
            b[i] = mod;
            n = (n - mod) / 256;
        }
        return b;
    }

    public function decode(idx as Number) as Number {
        var offset = idx * POINT_SIZE;
        var b = self.data;
        var n = b[offset].toNumber();
        for (var i = offset + 1; i < offset + POINT_SIZE; i++) {
            n *= 256;
            n += b[i];
        }
        return n;
    }

    public function size() as Number {
        return self.data.size() / POINT_SIZE;
    }

    public function serialize() as ByteArray {
        return self.data;
    }
}

(:test)
function testPointsContainer(logger as Logger) as Boolean {
    var pc = new PointsContainer([1, 2, 3, 4, 5, 6, 7, 8]b);
    var v = pc.decode(1);
    assert_equal(v, (((5 * 256 + 6) * 256) + 7) * 256 + 8, "unexpected decoded value");
    var pc2 = pc.encode((((8 * 256 + 7) * 256) + 6) * 256 + 5, 1);
    assert_equal(pc2, [1, 2, 3, 4, 8, 7, 6, 5]b, "unexpected encoded value");
    assert_equal(pc.size(), 2, "unexpected size");
    return true;
}
