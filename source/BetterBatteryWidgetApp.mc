using Toybox.Application;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

const FIVE_MINUTES = new Time.Duration(5 * 60);


(:background)
class BetterBatteryWidgetApp extends Application.AppBase {
    var mWidgetView;
    var mState;
    
    function initialize() {
    	AppBase.initialize();
    	var data = Background.getBackgroundData();
    	mState = new State(data);
    }

    function onBackgroundData(data) {
    	log("App.onBackgroundData", data);
    	mState = new State(data);
    	mState.save();
        if( mWidgetView ) {
	    	log("App.onBackgroundData", "calling WidgetView.updateState");
            mWidgetView.updateState(mState);
        }
        WatchUi.requestUpdate();
    }
    
    function onStart(state) {
    	setBackgroundEvent();
    }

    // This method runs each time the main application starts.
    function getInitialView() {
        mWidgetView = new WidgetView(mState);
        var inputDelegate = new WidgetViewInputDelegate();
        return [ mWidgetView, inputDelegate ];
//		mWidgetView = new GraphView(mState);
//		return [mWidgetView];
    }

    // This method runs each time the background process starts.
    function getServiceDelegate(){
        return [new BackgroundServiceDelegate()];
    }
    
        
    function setBackgroundEvent() {    	
    	var time = Background.getLastTemporalEventTime();
    	log("App.setBackgroundEvent lastTime", formatTime(time));
		time = Background.getTemporalEventRegisteredTime();
		if (time != null) {
			log("App.setBackgroundEvent regTime", formatTime(new Time.Moment(time.value())));
			return;
		}
       	log("App.setBackgroundEvent scheduling", FIVE_MINUTES);
		try {
	 	    Background.registerForTemporalEvent(FIVE_MINUTES);
	    } catch (e instanceof Background.InvalidBackgroundTimeException) {
	        log("App.setBackgroundEvent error", e);
        }
    }
   
    function deleteBackgroundEvent() {
    	log("App.deleteBackgroundEvent", "deleting");
        Background.deleteTemporalEvent();
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
