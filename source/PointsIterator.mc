import Toybox.Lang;

typedef StatePoint as Array<Number or Float>; // [ts, percent]
typedef StatePoints as Array<StatePoint>;


class PointsIterator {
    private var mPoints as StatePoints;
    private var mPosition as Number = 0;

    public function initialize(points as StatePoints) {
        mPoints = points;
    }

    public function size() as Number {
        return mPoints.size();
    }

    public function last() as BatteryPoint? {
        if (mPoints.size() == 0) {
            return null;
        }
        var point = mPoints[mPoints.size() - 1] as StatePoint;
        return new BatteryPoint(point[0] as Number, point[1] as Float);
    }

    public function first() as BatteryPoint? {
        if (mPoints.size() == 0) {
            return null;
        }
        var point = mPoints[0] as StatePoint;
        return new BatteryPoint(point[0] as Number, point[1] as Float);
    }

    public function reset() as Void {
        self.mPosition = 0;
    }

    public function next() as BatteryPoint? {
        if (mPosition >= mPoints.size()) {
            return null;
        }
        var res = mPoints[mPosition] as StatePoint;
        mPosition += 1;
        return new BatteryPoint(res[0] as Number, res[1] as Float);
    }
}