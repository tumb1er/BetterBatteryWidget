using Toybox.Application;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;

(:background)
class BetterBatteryWidgetApp extends Application.AppBase {
    var mWidgetView;
    var mBackgroundData;
    
    function initialize() {
    	AppBase.initialize();
    }

    function onBackgroundData(data) {
    	log("App.onBackgroundData", data);
        if( mWidgetView ) {
	    	log("App.onBackgroundData", "calling View.backgroundEvent");
            mWidgetView.backgroundEvent(data);
        } else {
	    	log("App.onBackgroundData", "now widget");
            mBackgroundData = data;
        }
    }

    // This method runs each time the main application starts.
    function getInitialView() {
        mWidgetView = new WidgetView(mBackgroundData);
        var inputDelegate = new WidgetViewInputDelegate();
        return [ mWidgetView, inputDelegate ];
    }

    // This method runs each time the background process starts.
    function getServiceDelegate(){
        return [new BackgroundServiceDelegate()];
    }
}

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
