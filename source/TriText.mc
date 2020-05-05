using Toybox.Lang;
using Toybox.WatchUi;

class TriText extends WatchUi.Text {
	var color, title, desc, value, suffix, text, log, numberOffset; 
	
	function initialize(params) {
		Text.initialize(params);
		color = params.get(:color);
		title = params.get(:title);
		value = params.get(:value);
		desc = params.get(:desc);
		suffix = params.get(:suffix);
		text = params.get(:text);
		log = new Log(Lang.format("TriText.$1$", [title]));
		numberOffset = loadResource(Rez.Strings.TriTextNumOffset).toNumber();
	}
	
	function draw(dc) {
		dc.setColor(color, -1);  // Graphics.COLOR_TRANSPARENT
		var gcx = locX + width/2;
		var top = locY;
		if (value == null) {
			dc.drawText(
				gcx, top, 
				4, // Graphics.FONT_LARGE
				text, 
				1 // Graphics.TEXT_JUSTIFY_CENTER
			);
			return;
		}
		//log.debug("draw", [gcx, top]);
		dc.drawText(
			gcx-20, top, 
			0, // Graphics.FONT_XTINY
			title, 
			0 // Graphics.TEXT_JUSTIFY_RIGHT
		);
		dc.drawText(
			gcx-20, top + 15, 
			0, // Graphics.FONT_XTINY
			desc, 
			0 // Graphics.TEXT_JUSTIFY_RIGHT
		);
		var pos = gcx - 10;
		if (suffix) {
			var val = value.substring(0, value.length() - 1);
			var sfx = value.substring(value.length() - 1, value.length());
			dc.drawText(
				pos, top  + numberOffset, 
				6, // Graphics.FONT_NUMBER_MEDIUM
				val, 
				2 // Graphics.TEXT_JUSTIFY_LEFT
			);
			pos += dc.getTextWidthInPixels(val, 6); // Graphics.FONT_NUMBER_MEDIUM
			dc.drawText(
				pos, top + 5, 
				4, // Graphics.FONT_LARGE 
				sfx, 
				2 // Graphics.TEXT_JUSTIFY_LEFT
			);
		} else {
			dc.drawText(
				pos, top + numberOffset, 
				6, // Graphics.FONT_NUMBER_MEDIUM
				value, 
				2 // Graphics.TEXT_JUSTIFY_LEFT
			);
		}
		
	}
}