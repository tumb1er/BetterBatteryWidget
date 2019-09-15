using Toybox.WatchUi;


class DebugViewInputDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    function onBack() {
		log("DebugViewInputDelegate.onBack", null);
        popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}