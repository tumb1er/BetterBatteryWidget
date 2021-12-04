import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

using Toybox.Application;
using Toybox.WatchUi;


(:background :glance)
class BetterBatteryWidgetApp extends Application.AppBase {
     private var log as Log;
    private var mState as State;
     private var mMeasureInterval as Duration?;
     private var mGraphDuration as Number?;
     private var mGraphMode as Number?;
    
    public function initialize() {
        log = new Log("App");
        AppBase.initialize();
        loadSettings();
        var data = Background.getBackgroundData() as StateData?;
        mState = new State(data);
        log.msg("Points from init");
        mState.printPoints();
    }

    (:typecheck([disableBackgroundCheck]))
    public function onBackgroundData(data as StateData?) as Void {
        mState = new State(data);
        log.msg("Points from background data (saving)");
        mState.printPoints();
        // log.debug("onBackgroundData: saving", data as Dictionary);
        mState.save();        
        WatchUi.requestUpdate();
    }
    
    public function onStart(state) as Void {
        setBackgroundEvent();
        // log.msg("app started");
    }

    // This method runs each time the main application starts.
    (:typecheck([disableBackgroundCheck, disableGlanceCheck]))
    public function getInitialView() {
        return [new WidgetPage(mState), new WidgetPageBehaviorDelegate()] as Array<WidgetPage or WidgetPageBehaviorDelegate>;
    }

    // This method runs each time the background process starts.
    (:typecheck([disableGlanceCheck]))
    public function getServiceDelegate() {
        return [new BackgroundServiceDelegate()] as Array<BackgroundServiceDelegate>;
    }

    (:typecheck([disableBackgroundCheck]))
    public function getGlanceView() {
        return [new GlancePage(mState)] as Array<WatchUi.GlanceView>;
    }
    
    private function setBackgroundEvent() as Void {        
        var time = Background.getLastTemporalEventTime();
        //log.debug("setBackgroundEvent lastTime", time);
        time = Background.getTemporalEventRegisteredTime();
        if (time != null) {
            //log.debug("setBackgroundEvent regDuration", time);
            return;
        }
           //log.debug("setBackgroundEvent scheduling", interval);
        try {
             Background.registerForTemporalEvent(mMeasureInterval);
        } catch (e instanceof Background.InvalidBackgroundTimeException) {
            //log.error("setBackgroundEvent error", e);
        }
    }
    
    (:typecheck([disableBackgroundCheck]))
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
        var period = getProperty("MeasurePeriod") as Number;
        mMeasureInterval = new Time.Duration(period * 60);
        mGraphDuration = getProperty("GraphDuration");
        mGraphMode = getProperty("GraphMode");
        //log.debug("settings loaded", [mMeasureInterval, mGraphDuration]);
    }

    public function getGraphDuration() as Number {
        return 3600 * mGraphDuration;
    }

    public function getGraphMode() as Number {
        return mGraphMode as Number;
    }

    public function getState() as State {
        return mState;
    }
}

(:background)
class BackgroundServiceDelegate extends System.ServiceDelegate {
    var log;
    public function initialize() {
        ServiceDelegate.initialize();
        log = new Log("BackgroundServiceDelegate");
    }

    public function onTemporalEvent() as Void {
        var data = Background.getBackgroundData() as StateData?;
        //log.debug("onTemporalEvent bgData", data); 
        var state = new State(data);
        log.debug("onTemporalEvent measure", state);
        state.measure();
        var ret = state.getData();
        // log.debug("onTemporalEvent ret", ret); 
        try {
            Background.exit(ret as Dictionary<String, Application.PropertyValueType>);
        } catch (e instanceof Background.ExitDataSizeLimitException) {
            log.msg("onTermporalError ExitSize error");
            log.error("Size error", e);
            throw new LogException("ExitDataSizeLimitException");
        } catch (e) {
            log.msg("onTermporalError unhandled error");
            log.error("Unknown error", e);
            throw new LogException(format("Unknown error $1$", [e]));
        }
    }
}

(:background :glance)
public function getApp() as BetterBatteryWidgetApp {
    return Application.getApp() as BetterBatteryWidgetApp;
}
