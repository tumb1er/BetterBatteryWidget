using Toybox.Graphics;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;

const cxl=119, cxr=120, cyt=119, cyb=120, ro=119, ri=104;
const angle=60;
const window = 12.0;
const beta=2/(1+window);
const rm=(ro+ri)/2, rw=(ro-ri+1)/2;
const FIVE_MINUTES = new Time.Duration(5 * 60);
	

class BetterBatteryWidgetView extends WatchUi.View {

	var mPercent;
	var mTimestamp;
	var mSpeed;
	var mBitmap;

    function initialize(backgroundRan) {
        View.initialize();
        if (backgroundRan != null) {
	        System.println([now(), "background ran", backgroundRan]);
        	backgroundEvent(backgroundRan);
        } else {
	        mPercent = objectStoreGet("percent", null);
	        mTimestamp = objectStoreGet("timestamp", null);
	        mSpeed = objectStoreGet("speed", null);
	        if (mPercent == null) {
	        	var v = getPercentTs();
	        	mPercent = v[0];
	        	mTimestamp = v[1];
		    	objectStorePut("percent", mPercent);
		    	objectStorePut("timestamp", mTimestamp);
	        }
	        System.println([now(), "loaded at start", mPercent, mTimestamp, mSpeed]);
        }
    }

    // Load your resources here
    function onLayout(dc) {
    	mBitmap = loadResource(Rez.Drawables.BatteryIcon);
    }

    function onShow() {
    	setBackgroundEvent();
    }

    // Update the view
    function onUpdate(dc) {
	    var t;
    	dc.setColor(0, 0);
    	dc.clear();
    	dc.setColor(0xffffff, Graphics.COLOR_TRANSPARENT);
		var stats = System.getSystemStats();
		mPercent = stats.battery;
		
		dc.drawBitmap(90, 60, mBitmap);
    	
    	dc.drawText(120, 120, Graphics.FONT_NUMBER_HOT, 
					mPercent.format("%.0f") + "%", 
					Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		if (mSpeed == null) {
			t = "measuring...";
		} else {
			t = mSpeed.format("%.1f") + "% / h";
			
		}
		dc.drawText(120, 160, Graphics.FONT_SMALL, 
					t, 
					Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
	
		if (mSpeed != null && mSpeed != 0) {
			t = mPercent / mSpeed;
			if (t >= 24) { 
				t = (t / 24).format("%.1f") + "d";
			} else {
				t = t.format("%.1f") + "h";
			}
			dc.drawText(120, 180, Graphics.FONT_XTINY, 
						t, 
	   					Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

		}	
		dc.setPenWidth(1);
		dc.setColor(0x555555, 0);
		// outer
		dc.drawArc(cxl, cyt, ro, Graphics.ARC_CLOCKWISE, 180, 90);
		dc.drawArc(cxl, cyb, ro, Graphics.ARC_CLOCKWISE, 180+angle, 180);
		dc.drawArc(cxr, cyt, ro, Graphics.ARC_CLOCKWISE, 90, 0);
		dc.drawArc(cxr, cyb, ro, Graphics.ARC_CLOCKWISE, 0, -angle);
		// inner
		dc.drawArc(cxl, cyt, ri, Graphics.ARC_CLOCKWISE, 180, 90);
		dc.drawArc(cxl, cyb, ri, Graphics.ARC_CLOCKWISE, 180+angle, 180);
		dc.drawArc(cxr, cyt, ri, Graphics.ARC_CLOCKWISE, 90, 0);
		dc.drawArc(cxr, cyb, ri, Graphics.ARC_CLOCKWISE, 0, -angle);
		// right
		dc.drawArc(cxr + rm * Math.cos(Math.toRadians(-angle)), 
				   cyb - rm * Math.sin(Math.toRadians(-angle)),
				   rw, Graphics.ARC_CLOCKWISE, -angle, -angle-180);
		if (mPercent > 90) {
			// blue
			dc.setColor(0x00aaff, 0);
		} else if (mPercent > 75) {
			// cyan
			dc.setColor(0x55ffff, 0);
		} else if (mPercent > 50) {
			// green
			dc.setColor(0x55ff00, 0);
		} else if (mPercent > 25) {
			// yellow
			dc.setColor(0xffff00, 0);
		} else if (mPercent > 10) {
			// orange
			dc.setColor(0xffaa00, 0);			
		} else {
			// red
			dc.setColor(0xff0000, 0);
		
		}
		// left 
		dc.fillCircle(cxl + rm * Math.cos(Math.toRadians(180+angle)), 
				      cyb - rm * Math.sin(Math.toRadians(180+angle)),
				      rw);

		dc.setPenWidth(16);
		
		var a = mPercent.toFloat() / 100.0 * (180 + 2 * angle);
		var rad = Math.toRadians(180+angle-a);
		var sinA = Math.sin(rad);
		var cosA = Math.cos(rad);


		if (a <= angle) {
			// ball in left-bottom
			dc.drawArc(cxl, cyb, rm, Graphics.ARC_CLOCKWISE, 180+angle, 180+angle-a);
			dc.fillCircle(cxl + rm * cosA, 
					      cyb - rm * sinA,
					      rw);
		} 
		if (a > angle && a <= angle + 90) {
			// ball in left-top
			dc.drawArc(cxl, cyt, rm, Graphics.ARC_CLOCKWISE, 180, 180+angle-a);
			dc.drawArc(cxl, cyb, rm, Graphics.ARC_CLOCKWISE, 180+angle, 180);
			dc.fillCircle(cxl + rm * cosA, 
					      cyt - rm * sinA,
					      rw);
		}
		if (a > angle+90 && a <= angle + 180) {
			// ball in right-top
			dc.fillCircle(cxr + rm * cosA, 
					      cyt - rm * sinA,
					      rw);
			dc.drawArc(cxr, cyt, rm, Graphics.ARC_CLOCKWISE, 90, 180+angle-a);
			dc.drawArc(cxl, cyt, rm, Graphics.ARC_CLOCKWISE, 180, 90);
			dc.drawArc(cxl, cyb, rm, Graphics.ARC_CLOCKWISE, 180+angle, 180);
		}
		if (a > angle + 180) {
			// ball in right-bottom
			dc.fillCircle(cxr + rm * cosA, 
					      cyb - rm * sinA,
					      rw);
			dc.drawArc(cxr, cyb, rm, Graphics.ARC_CLOCKWISE, 0, 180+angle-a);
			dc.drawArc(cxr, cyt, rm, Graphics.ARC_CLOCKWISE, 90, 0);
			dc.drawArc(cxl, cyt, rm, Graphics.ARC_CLOCKWISE, 180, 90);
			dc.drawArc(cxl, cyb, rm, Graphics.ARC_CLOCKWISE, 180+angle, 180);
		}
    }

    function onHide() {
    }
    
    function setBackgroundEvent() {
    	System.println([now(), "setBackgroundEvent"]);
    	
    	var lastTime = Background.getLastTemporalEventTime();
        try {
			if (lastTime != null) {
			    // Events scheduled for a time in the past trigger immediately
			    var nextTime = lastTime.add(FIVE_MINUTES);
			    Background.registerForTemporalEvent(nextTime);
			} else {
			    Background.registerForTemporalEvent(Time.now().add(FIVE_MINUTES));
			}
        } catch (e instanceof Background.InvalidBackgroundTimeException) {
			System.println(["XXX:", e]);
        }
    }

    function deleteBackgroundEvent() {
    	System.println([now(), "deleteBackgroundEvent"]);
        Background.deleteTemporalEvent();
    }
    
    function backgroundEvent(data) {
    	System.println([now(), "view.backgroundEvent", data]);

		var delta = (data[0] - data[2]).abs().toFloat();
		var interval = (data[1] - data[3]).toFloat();
		if (interval == 0) {
			return;
		}
		var speed = delta / interval * 3600.0;
		if (mSpeed != null) {
			speed = mSpeed  * (1.0-beta) + speed * beta;
		}
		System.println([now(), "saving", data[0], data[1], speed]);
		objectStorePut("percent", data[0]); 
		objectStorePut("timestamp", data[1]); 
		objectStorePut("speed", speed);
    
    	mPercent = data[0];
    	mTimestamp = data[1];
		mSpeed = speed;
        WatchUi.requestUpdate();
        setBackgroundEvent();
    }

}
