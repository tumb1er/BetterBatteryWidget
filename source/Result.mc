using Toybox.Lang;

/**
predict returns a BatteryPoint with values:
* ts - estimated life time in seconds
* value  discharge speed in percent per second
**/
(:glance)
function predict(first as BatteryPoint?, last as BatteryPoint?) as BatteryPoint? {
	if (first == null || last == null) {
		return null;
	}
	first = first as BatteryPoint;
	last = last as BatteryPoint;
	var duration = (last.getTS() - first.getTS()).toDouble();
	var delta = (last.getValue() - first.getValue()).abs();
	if (delta == 0 || duration == 0) {
		return null;
	}
	var speed = delta / duration;
	return new BatteryPoint((last.getValue() / speed).toNumber(), speed.toFloat());		
}

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
        self.currentPoint = stats.getPointsIterator().last();
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
		
	public function predictAvg(weight as Lang.Float) as Lang.Float {
		if (windowPredict != null && chargedPredict != null) {
			return (windowPredict as BatteryPoint).getTS() * weight + (chargedPredict as BatteryPoint).getTS() * (1.0 - weight);
		} else if (chargedPredict != null) {
			return (chargedPredict as BatteryPoint).getTS().toFloat();
		} else if (windowPredict != null) {
			return (windowPredict as BatteryPoint).getTS().toFloat();
		}
		return 0.0;
	}
	
	public function predictWindow() as Void {
		self.windowPredict = null;
		var data = mStats.getWindowIterator();
		if (data.size() < 2) {
			return;
		}
		var first = data.first();
		self.windowPredict = predict(first, self.currentPoint);
        // log.debug("windowPredict", self.windowPredict);
	}
	
	public function predictCharged() as Void {
		self.chargedPredict = null;
        if (self.chargedPoint == null || self.currentPoint == null) {
            return;
        }
		self.chargedPredict = predict(chargedPoint, currentPoint);
        // log.debug("chargedPredict", self.chargedPredict);
	}
	
	public function chargedDuration() as Lang.Float {
		if (self.chargedPoint == null) {
			return 0.0;
		}
        if (self.currentPoint == null) {
            return 0.0;
        }
		return ((self.currentPoint as BatteryPoint).getTS() - (self.chargedPoint as BatteryPoint).getTS()).toFloat();
	}
	
	public function predictMark() as Void {
		markPredict = null;
		var first = mStats.getMarkPoint();
		if (first == null) {
			return;
		}
		var data = mStats.getPointsIterator();
		if (data.size() == 0) {
			return;
		}
		var last = data.last();
		self.markPredict = predict(first, last);
	}
	
}

