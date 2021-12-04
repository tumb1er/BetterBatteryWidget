import Toybox.Lang;

(:glance)
class PointsIterator {
    private var mData as TimeSeries;
    private var mPosition as Number;
    private var mStartPosition as Number;

    public function initialize(data as TimeSeries, position as Number) {
        mData = data;
        mPosition = position;
        mStartPosition = position;
    }

    public function first() as BatteryPoint? {
        if (mStartPosition >= mData.size()) {
            return null;
        }
        return mData.get(mStartPosition);
    }

    public function last() as BatteryPoint? {
        if (mStartPosition >= mData.size()) {
            return null;
        }
        return mData.get(mData.size() -1);
    }

    public function size() as Number { 
        return mData.size();
    }

    public function start() as Void {
        mPosition = mStartPosition;
    }

    public function current() as BatteryPoint? {
        if (mPosition >= mData.size()) {
            return null;
        }
        return mData.get(mPosition);
    }

    public function next() as BatteryPoint? {
        var res = current();
        mPosition += 1;
        return res;
    }
}
