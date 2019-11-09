using Toybox.WatchUi;

class DebugPage extends WatchUi.View {
	var mView;
	var mAnimated = false;
	
    function onLayout( dc ) {
    	mView = new GraphDrawable({
	    	:width => 200,
	    	:height => 80,
	    	:x => 20,
	    	:y => 100,
	    	:border => Graphics.COLOR_WHITE,
	    	:background => Graphics.COLOR_TRANSPARENT,
	    	:foreground => Graphics.COLOR_RED,
	    	:interval => 3600
    	});
    	setLayout([mView]);
    }
    
    function onShow() {
		var app = Application.getApp();
		mView.setData(app.mState.mPoints);		
	}

    function onUpdate( dc ) {
        // Call parent’s onUpdate(dc) to redraw the layout
        View.onUpdate( dc );
    }
}