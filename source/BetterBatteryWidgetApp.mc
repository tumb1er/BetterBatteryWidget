using Toybox.Application;
using Toybox.Background;
import Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;


(:background :glance)
class BetterBatteryWidgetApp extends Application.AppBase {
 	// var log as Log;
    var mState as State;

    var mWidgetPage as WidgetPage?;

 	var mMeasureInterval as Number?;
 	var mGraphDuration as Number?;
 	var mGraphMode as Number?;
    
    public function initialize() {
    	// log = new Log("App");
		AppBase.initialize();
    	loadSettings();
    	var data = Background.getBackgroundData() as Dictionary<String, Array<Array<Number or Float> > or Array<Number or Float> or Boolean>;
    	mState = new State(data);
    }

    public function onBackgroundData(data as StateData?) as Void {
    	mState = new State(data);
    	// log.debug("onBackgroundData: saving", data as Dictionary);
    	mState.save();
        if( mWidgetPage != null ) {
	    	//log.msg("onBackgroundData: calling WidgetPage.updateState");
            (mWidgetPage as WidgetPage).updateState(mState);
        }
        WatchUi.requestUpdate();
    }
    
    public function onStart(state) as Void {
    	setBackgroundEvent();
    	// log.msg("app started");
    }

    // This method runs each time the main application starts.
    public function getInitialView() {
        mWidgetPage = new WidgetPage(mState);
        var inputDelegate = new WidgetPageBehaviorDelegate();
		return [ mWidgetPage, inputDelegate ] as Array<WidgetPage or WidgetPageBehaviorDelegate>;
    }

    // This method runs each time the background process starts.
    public function getServiceDelegate() {
        return [new BackgroundServiceDelegate()] as Array<BackgroundServiceDelegate>;
    }
    
    private function setBackgroundEvent() as Void {    	
    	var time = Background.getLastTemporalEventTime();
    	//log.debug("setBackgroundEvent lastTime", time);
		time = Background.getTemporalEventRegisteredTime();
		if (time != null) {
			//log.debug("setBackgroundEvent regDuration", time);
			return;
		}
		var interval = new Time.Duration((mMeasureInterval as Number) * 60);
       	//log.debug("setBackgroundEvent scheduling", interval);
		try {
	 	    Background.registerForTemporalEvent(interval);
	    } catch (e instanceof Background.InvalidBackgroundTimeException) {
	        //log.error("setBackgroundEvent error", e);
        }
    }
    
    public function onSettingsChanged() as Void {
    	//log.msg("onSettingsChanged");
    	loadSettings();
        WatchUi.requestUpdate();
    }
   
    private function deleteBackgroundEvent() as Void {
    	//log.msg("deleteBackgroundEvent");
        Background.deleteTemporalEvent();
    }  
    
    private function loadSettings() as Void {
    	mMeasureInterval = getProperty("MeasurePeriod");
    	mGraphDuration = getProperty("GraphDuration");
    	mGraphMode = getProperty("GraphMode");
    	//log.debug("settings loaded", [mMeasureInterval, mGraphDuration]);
    }
    
}

(:background)
class BackgroundServiceDelegate extends System.ServiceDelegate {
	//var log;
    public function initialize() {
        ServiceDelegate.initialize();
        //log = new Log("BackgroundServiceDelegate");
    }

    public function onTemporalEvent() as Void {
    	var data = Background.getBackgroundData() as StateData?;
		//log.debug("onTemporalEvent bgData", data); 
    	var state = new State(data);
    	//log.debug("onTemporalEvent measure", state.mData);
		state.measure();
		var ret = state.getData();
		//log.debug("onTemporalEvent ret", ret); 
		try {
			Background.exit(ret as Dictionary<String, Application.PropertyValueType>);
		} catch (e instanceof Background.ExitDataSizeLimitException) {
			throw new LogException("ExitDataSizeLimitException");
		} catch (e) {
			throw new LogException(format("Unknown error $1$", [e]));
		}
    }
}
