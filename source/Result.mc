
class Result {
    // var log;
	private var mStats as State;
	private var chargedPoint as BatteryPoint?;
    private var currentPoint as BatteryPoint?;
	private var chargedPredict as BatteryPoint?;
	private var windowPredict as BatteryPoint?;
	private var markPredict as BatteryPoint?;
	
	public function initialize(stats as State) {
		// log = new Log("Result");
        mStats = stats;
        self.chargedPoint = stats.getChargedPoint();
        self.currentPoint = stats.getDataIterator().last();
	}

    public function getChargedPredict() as BatteryPoint? {
        return self.chargedPredict;
    }

    public function getWindowPredict() as BatteryPoint? {
        return self.windowPredict;
    }

    public function getMarkPredict() as BatteryPoint? {
        return self.markPredict;
    }
	
    /**
    predict returns a BatteryPoint with values:
    * ts - estimated life time in seconds
    * value  discharge speed in percent per second
	**/
    private function predict(first as BatteryPoint, last as BatteryPoint) as BatteryPoint? {
		var duration = (last.getTS() - first.getTS()).toDouble();
		var delta = (last.getValue() - first.getValue()).abs();
		if (delta == 0 || duration == 0) {
			return null;
		}
		var speed = delta / duration;
		return new BatteryPoint((last.getValue() / speed).toNumber(), speed.toFloat());		
	}
	
	public function predictAvg(weight) as Float {
		if (windowPredict == null) {
			return chargedPredict.getTS();
		}
		if (chargedPredict == null) {
			return windowPredict.getTS();
		}
		return windowPredict.getTS() * weight + chargedPredict.getTS() * (1.0 - weight);
	}
	
	public function predictWindow() {
		self.windowPredict = null;
		var data = mStats.getDataIterator();
		if (data.size() < 2) {
			return;
		}
		var first = data.first();
		self.windowPredict = predict(first, self.currentPoint);
        // log.debug("windowPredict", self.windowPredict);
	}
	
	public function predictCharged() {
		self.chargedPredict = null;
        if (self.chargedPoint == null || self.currentPoint == null) {
            return;
        }
		self.chargedPredict = predict(chargedPoint, currentPoint);
        // log.debug("chargedPredict", self.chargedPredict);
	}
	
	public function chargedDuration() as Double {
		if (self.chargedPoint == null) {
			return 0;
		}
        if (self.currentPoint == null) {
            return 0;
        }
		var duration = (self.currentPoint.getTS() - self.chargedPoint.getTS()).toDouble();
		return duration;
	}
	
	public function predictMark() {
		markPredict = null;
		var first = mStats.getMarkPoint();
		if (first == null) {
			return;
		}
		var data = mStats.getDataIterator();
		if (data.size() == 0) {
			return;
		}
		var last = data.last();
		self.markPredict = predict(first, last);
	}
	
}

