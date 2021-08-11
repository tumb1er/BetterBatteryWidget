class BatteryPoint {
    private var ts as Number;
    private var value as Float;

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