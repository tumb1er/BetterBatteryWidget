using Toybox.Background;
using Toybox.System;
using Toybox.Time;

(:background)
class BackgroundServiceDelegate extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
    	var data = Background.getBackgroundData();
		log("Delegate.onTemporalEvent bgData", data); 
    	var state = new State(data);
    	state.measure();
		var ret = state.getData();
		log("Delegate.onTemporalEvent ret", ret); 
		Background.exit(ret);
    }
}