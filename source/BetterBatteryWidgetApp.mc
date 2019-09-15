using Toybox.Application;
using Toybox.System;

(:background)
class BetterBatteryWidgetApp extends Application.AppBase {
    var mWidgetView;
    var mBackgroundData;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
        if( mWidgetView ) {
            mWidgetView.setBackgroundEvent();
        }
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        Toybox.System.println(mProperties);
    }

    // This method is called when data is returned from our
    // Background process.
    function onBackgroundData(data) {
    	System.println([now(), "App.onBackgroundData", data]);
        if( mWidgetView ) {
            mWidgetView.backgroundEvent(data);
        } else {
        System.println([now(), "App: no mWidgetView"]);
            mBackgroundData = data;
        }
    }

    // This method runs each time the main application starts.
    function getInitialView() {
        mWidgetView = new BetterBatteryWidgetView(mBackgroundData);
//        mWidgetView.deleteBackgroundEvent();
        return [ mWidgetView ];
    }

    // This method runs each time the background process starts.
    function getServiceDelegate(){
        return [new BackgroundServiceDelegate()];
    }
}
