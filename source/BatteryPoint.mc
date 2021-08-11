using Toybox.Lang;


class BatteryPoint {
    private var ts;
    private var value;

    public function initialize(ts as Lang.Number, value as Lang.Float) {
        self.ts = ts;
        self.value = value;
    }

    public function getTS() as Lang.Number {
        return self.ts;
    }

    public function getValue() as Lang.Float {
        return self.value;
    }

    (:debug)
    public function toString() as Lang.String {
        return Lang.format("<$1$ $2$>", [self.ts, self.value]);
    }
}