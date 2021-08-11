import Toybox.Lang;


class BatteryPoint {
    private var ts as Number = 0;
    private var value as Float = 0.0;

    public static function fromArray(d as StatePoint?) as BatteryPoint? {
        if (d == null) { 
            return null;
        }
        d = d as StatePoint;
        return new BatteryPoint(d[0] as Number, d[1] as Float);
    }

    public function initialize(ts as Number, value as Float) {
        self.ts = ts;
        self.value = value;
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