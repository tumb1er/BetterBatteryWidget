using Toybox.Background;
using Toybox.System;
using Toybox.Time;

(:background)
class BackgroundServiceDelegate extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
		var prevPercent = objectStoreGet("percent", null);
		var prevTimestamp = objectStoreGet("timestamp", null);
		if (prevPercent != null) {
			var current = getPercentTs();
			var ret = [current[0], current[1], prevPercent, prevTimestamp, Time.now().value()];
			System.println([now(), "background.exit", ret]);
        	Background.exit(ret);
    	}
    }
}