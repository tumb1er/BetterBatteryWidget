using Toybox.WatchUi;

class DebugPage extends WatchUi.View {
	var mView;
	var mAnimated = false;
    function onLayout( dc ) {
    	mView = new GaugeDrawable({
	    	:width => dc.getWidth(),
	    	:height => dc.getHeight()
    	});
    	setLayout([mView]);
    }
    
    function onShow() {
			WatchUi.animate(mView, :value, WatchUi.ANIM_TYPE_EASE_OUT, 0, 100, 0.5, null);    	
    }

    function onUpdate( dc ) {
        // Call parent’s onUpdate(dc) to redraw the layout
        View.onUpdate( dc );
        if (!mAnimated) {
        	mAnimated = true;
        }
    }
}