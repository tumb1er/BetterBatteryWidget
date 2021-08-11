import Toybox.Lang;

class PointsIterator {
    private var mPoints as Array<Array<Number or Float> >;
    private var mPosition;

    public function initialize(points as Array<Array<Number or Float> >) {
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
        var point = mPoints[mPoints.size() - 1] as Array<Number or Float>;
        return new BatteryPoint(point[0], point[1]);
    }

    public function first() as BatteryPoint? {
        if (mPoints.size() == 0) {
            return null;
        }
        var point = mPoints[0] as Array<Number or Float>;
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