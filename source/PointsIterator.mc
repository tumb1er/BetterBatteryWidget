class PointsIterator {
    private var mPoints;
    private var mPosition;

    public function initialize(points) {
        mPoints = points;
        mPosition = 0;
    }

    public function size() as Number {
        return mPoints.size();
    }

    public function last() as BatteryPoint? {
        if (mPoints.size() == 0) {
            return null;
        }
        var point = mPoints[mPoints.size() - 1];
        return new BatteryPoint(point[0], point[1]);
    }

    public function first() as BatteryPoint? {
        if (mPoints.size() == 0) {
            return null;
        }
        var point = mPoints[0];
        return new BatteryPoint(point[0], point[1]);
    }

    public function reset() {
        self.mPosition = 0;
    }
    public function next() as BatteryPoint? {
        if (mPosition >= mPoints.size()) {
            return null;
        }
        var res = mPoints[mPosition];
        mPosition += 1;
        return new BatteryPoint(res[0], res[1]);
    }
}