using Toybox.Application;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

const FIVE_MINUTES = new Time.Duration(5 * 60);


(:background)
class BetterBatteryWidgetApp extends Application.AppBase {
    var mWidgetPage;
    var mState;
 	var log;
    
    function initialize() {
    	AppBase.initialize();
    	log = new Log(self);
    	var data = Background.getBackgroundData();
    	mState = new State(data);
    }

    function onBackgroundData(data) {
    	log.debug("onBackgroundData", data);
    	mState = new State(data);
    	mState.save();
        if( mWidgetPage ) {
	    	log.msg("onBackgroundData: calling WidgetPage.updateState");
            mWidgetPage.updateState(mState);
        }
        WatchUi.requestUpdate();
    }
    
    function onStart(state) {
    	setBackgroundEvent();
    }

    // This method runs each time the main application starts.
    function getInitialView() {
        mWidgetPage = new WidgetPage(mState);
        var inputDelegate = new WidgetPageInputDelegate();
        return [ mWidgetPage, inputDelegate ];
//		return [new DebugPage()];
    }

    // This method runs each time the background process starts.
    function getServiceDelegate(){
        return [new BackgroundServiceDelegate()];
    }
    
        
    function setBackgroundEvent() {    	
    	var time = Background.getLastTemporalEventTime();
    	log.debug("setBackgroundEvent lastTime", time);
		time = Background.getTemporalEventRegisteredTime();
		if (time != null) {
			log.debug("setBackgroundEvent regDuration", time);
			return;
		}
       	log.debug("setBackgroundEvent scheduling", FIVE_MINUTES);
		try {
	 	    Background.registerForTemporalEvent(FIVE_MINUTES);
	    } catch (e instanceof Background.InvalidBackgroundTimeException) {
	        log.error("setBackgroundEvent error", e);
        }
    }
   
    function deleteBackgroundEvent() {
    	log.msg("deleteBackgroundEvent");
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
		log.debug("onTemporalEvent bgData", data); 
    	var state = new State(data);
    	state.measure();
		var ret = state.getData();
		log.debug("onTemporalEvent ret", ret); 
		Background.exit(ret);
    }
}
