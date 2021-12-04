import Toybox.Lang;

(:glance)
class PointsIterator {
    private var mData as TimeSeries;
    private var mPosition as Number;
    private var mStartPosition as Number;
    private var mSize as Number;

    public function initialize(data as TimeSeries, position as Number) {
        mData = data;
        mSize = data.size();
        mPosition = position;
        mStartPosition = position;
    }

    public function first() as BatteryPoint? {
        if (mStartPosition >= mSize) {
            return null;
        }
        return mData.get(mStartPosition);
    }

    public function last() as BatteryPoint? {
        if (mStartPosition >= mSize) {
            return null;
        }
        return mData.get(mSize - 1);
    }

    public function size() as Number { 
        return mSize;
    }

    public function start() as Void {
        mPosition = mStartPosition;
    }

    public function current() as BatteryPoint? {
        if (mPosition >= mSize) {
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
