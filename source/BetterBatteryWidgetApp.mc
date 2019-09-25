using Toybox.Application;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;

const FIVE_MINUTES = new Time.Duration(5 * 60);


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
    
    function onStart(state) {
    	setBackgroundEvent();
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
