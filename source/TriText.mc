using Toybox.Graphics;
using Toybox.Lang;
using Toybox.WatchUi;

class TriText extends WatchUi.Text {
	var color, title, desc, value, suffix, text, log; 
	
	function initialize(params) {
		Text.initialize(params);
		color = params.get(:color);
		title = params.get(:title);
		value = params.get(:value);
		desc = params.get(:desc);
		suffix = params.get(:suffix);
		text = params.get(:text);
		log = new Log(Lang.format("TriText.$1$", [title]));
	}
	
	function draw(dc) {
		dc.setColor(color, Graphics.COLOR_TRANSPARENT);
		var gcx = locX + width/2;
		var top = locY;
		if (value == null) {
			dc.drawText(gcx, top, Graphics.FONT_LARGE, text, Graphics.TEXT_JUSTIFY_CENTER);
			return;
		}
		log.debug("draw", [gcx, top]);
		dc.drawText(gcx-20, top, Graphics.FONT_XTINY, title, Graphics.TEXT_JUSTIFY_RIGHT);
		dc.drawText(gcx-20, top + 15, Graphics.FONT_XTINY, desc, Graphics.TEXT_JUSTIFY_RIGHT);
		var pos = gcx - 10;
		if (suffix) {
			var val = value.substring(0, value.length() - 1);
			var sfx = value.substring(value.length() - 1, value.length());
			dc.drawText(pos, top - 6, Graphics.FONT_NUMBER_MEDIUM, val, Graphics.TEXT_JUSTIFY_LEFT);
			pos += dc.getTextWidthInPixels(val, Graphics.FONT_NUMBER_MEDIUM);
			dc.drawText(pos, top + 5, Graphics.FONT_LARGE, sfx, Graphics.TEXT_JUSTIFY_LEFT);
		} else {
			dc.drawText(pos, top - 6, Graphics.FONT_NUMBER_MEDIUM, value, Graphics.TEXT_JUSTIFY_LEFT);
		}
		
	}
}