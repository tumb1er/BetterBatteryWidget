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
	var mBitmap;
	var mState;

    function initialize(backgroundData) {
        View.initialize();
    	log("View.initialize", backgroundData);
        backgroundEvent(backgroundData);
        mState.measure();
        mState.save();
    }

    function onLayout(dc) {
    	mBitmap = loadResource(Rez.Drawables.BatteryIcon);
    }

    function onShow() {
    	setBackgroundEvent();
    }

    function onUpdate(dc) {
	    var t;
    	dc.setColor(0, 0);
    	dc.clear();
    	dc.setColor(0xffffff, Graphics.COLOR_TRANSPARENT);
		var stats = System.getSystemStats();
		var percent = stats.battery;
		
		dc.drawBitmap(90, 60, mBitmap);
    	
    	dc.drawText(120, 120, Graphics.FONT_NUMBER_HOT, 
					percent.format("%.0f") + "%", 
					Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
		var predicted = mState.predict();
		if (predicted == null ) {
			if (stats.charging) {
				predicted = "charging...";
			} else {
				predicted = "measuring...";
			}
		} else {
			predicted = predicted / 3600.0;
			if (predicted >= 24) { 
				predicted = (predicted / 24).format("%.1f") + "d";
			} else {
				predicted = predicted.format("%.1f") + "h";
			}
		}
		dc.drawText(120, 160, Graphics.FONT_SMALL, 
					predicted, 
					Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
		if (percent > 90) {
			// blue
			dc.setColor(0x00aaff, 0);
		} else if (percent > 75) {
			// cyan
			dc.setColor(0x55ffff, 0);
		} else if (percent > 50) {
			// green
			dc.setColor(0x55ff00, 0);
		} else if (percent > 25) {
			// yellow
			dc.setColor(0xffff00, 0);
		} else if (percent > 10) {
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
		
		var a = percent.toFloat() / 100.0 * (180 + 2 * angle);
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
    	var time = Background.getLastTemporalEventTime();
    	log("View.setBackgroundEvent lastTime", time);
		if (time != null) {
		    time = time.add(FIVE_MINUTES);
		} else {
			time = Background.getTemporalEventRegisteredTime();
			log("View.setBackgroundEvent regTime", time);
			if (time != null) {
				return;
			}
			time = Time.now().add(FIVE_MINUTES);			
		}
       	log("View.setBackgroundEvent scheduling", formatTime(time));
		try {
	 	    Background.registerForTemporalEvent(time);
	    } catch (e instanceof Background.InvalidBackgroundTimeException) {
	        log("View.setBackgroundEvent error", e);
        }
    }

    function deleteBackgroundEvent() {
    	log("View.deleteBackgroundEvent", "deleting");
        Background.deleteTemporalEvent();
    }
    
    function backgroundEvent(data) {
    	log("View.backgroundEvent", data);
    	mState = new State(data);
    	mState.save();
        WatchUi.requestUpdate();
        setBackgroundEvent();
    }

}
