using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;

(:glance)
class GlancePage extends WatchUi.GlanceView {
	var mState as State;
    // var log as Log;
    var mBattery as Lang.String?;

    public function initialize(state as State) {
        // log = new Log("GlancePage");
        // log.debug("init", [state]);
    	GlanceView.initialize();
		mState = state;
	}

    public function onLayout(dc) {
        var RS = Rez.Strings;
        mBattery = (loadResource(RS.AppName) as Lang.String).toUpper();
    }
	
    public function onUpdate( dc ) {
        // log.msg("onUpdate");
        var w = dc.getWidth();
        var h = dc.getHeight();
        var state = System.getSystemStats();
        var bx = interpolate(0, 100, state.battery, 0, w);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, 0, Graphics.FONT_GLANCE, mBattery as Lang.String, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(0, h / 2, Graphics.FONT_GLANCE_NUMBER, formatPercent(state.battery), Graphics.TEXT_JUSTIFY_LEFT);
        var color = colorize(state.battery);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(5);
        dc.drawLine(0, h / 2, bx, h / 2);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(bx + 7, h / 2, w, h / 2);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var charged = mState.getChargedPoint();
        if (charged != null) {
            dc.drawText(w, 0, Graphics.FONT_GLANCE, formatTimestamp(charged.getTS()), Graphics.TEXT_JUSTIFY_RIGHT);
            mState.measure();
            var result = new Result(mState);
            result.predictWindow();
            result.predictCharged();
            var predicted = result.predictAvg(0.5);
            if (predicted != null ) {
                dc.drawText(w, h * 3 / 4, Graphics.FONT_SMALL, formatInterval(predicted), 
                            Graphics.TEXT_JUSTIFY_VCENTER|Graphics.TEXT_JUSTIFY_RIGHT);
            }
        }

    }

}
