using Toybox.Application;
using Toybox.Background;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;


(:background)
class BetterBatteryWidgetApp extends Application.AppBase {
 	var log;

    var mWidgetPage;
    var mState;
 	var mMeasureInterval;
 	var mGraphDuration;
    
    function initialize() {
    	AppBase.initialize();
    	log = new Log("App");
    	loadSettings();
    	var data = Background.getBackgroundData();
    	mState = new State(data);
    	log.debug("initialize", mState.mPoints);
    }

    function onBackgroundData(data) {
    	log.debug("onBackgroundData", data);
    	mState = new State(data);
    	mState.save();
        if( mWidgetPage ) {
	    	//log.msg("onBackgroundData: calling WidgetPage.updateState");
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
        var inputDelegate = new WidgetPageBehaviorDelegate();
        return [ mWidgetPage, inputDelegate ];
    }

    // This method runs each time the background process starts.
    function getServiceDelegate(){
        return [new BackgroundServiceDelegate()];
    }
    
        
    private function setBackgroundEvent() {    	
    	var time = Background.getLastTemporalEventTime();
    	//log.debug("setBackgroundEvent lastTime", time);
		time = Background.getTemporalEventRegisteredTime();
		if (time != null) {
			//log.debug("setBackgroundEvent regDuration", time);
			return;
		}
		var interval = new Time.Duration(mMeasureInterval * 60);
       	//log.debug("setBackgroundEvent scheduling", interval);
		try {
	 	    Background.registerForTemporalEvent(interval);
	    } catch (e instanceof Background.InvalidBackgroundTimeException) {
	        //log.error("setBackgroundEvent error", e);
        }
    }
   
    function deleteBackgroundEvent() {
    	//log.msg("deleteBackgroundEvent");
        Background.deleteTemporalEvent();
    }  
    
    function onSettingsChanged() {
    	//log.msg("onSettingsChanged");
    	loadSettings();
        WatchUi.requestUpdate();
    }
    
    private function loadSettings() {
    	mMeasureInterval = getProperty("MeasurePeriod");
    	mGraphDuration = getProperty("GraphDuration");
    	//log.debug("settings loaded", [mMeasureInterval, mGraphDuration]);
    }
    
}

(:background)
class BackgroundServiceDelegate extends System.ServiceDelegate {
	var log;
    function initialize() {
        ServiceDelegate.initialize();
        log = new Log("BackgroundServiceDelegate");
    }

    function onTemporalEvent() {
    	var data = Background.getBackgroundData();
		//log.debug("onTemporalEvent bgData", data); 
    	var state = new State(data);
		state.measure();
		var ret = state.getData();
		//log.debug("onTemporalEvent ret", ret); 
		Background.exit(ret);
    }
}
