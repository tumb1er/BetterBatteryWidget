using Toybox.WatchUi;


class WidgetViewInputDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }
    
    function onTap(event) {
		log("WidgetViewInputDelegate.onTap", event);
		pushView(new DebugView(), new DebugViewInputDelegate(), WatchUi.SLIDE_IMMEDIATE);    
    	return true;
    }
}