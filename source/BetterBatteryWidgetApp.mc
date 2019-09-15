using Toybox.Application;
using Toybox.System;

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
        mWidgetView = new BetterBatteryWidgetView(mBackgroundData);
        var inputDelegate = new WidgetViewInputDelegate();
        return [ mWidgetView, inputDelegate ];
    }

    // This method runs each time the background process starts.
    function getServiceDelegate(){
        return [new BackgroundServiceDelegate()];
    }
}
