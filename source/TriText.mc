using Toybox.Lang;
using Toybox.WatchUi;

class TriText extends WatchUi.Text {
	var color, title, desc, value, suffix, text, log, numberOffset, centerOffset, descOffset; 
	
	function initialize(params) {
		Text.initialize(params);
		color = params.get(:color);
		title = params.get(:title);
		value = params.get(:value);
		desc = params.get(:desc);
		suffix = params.get(:suffix);
		text = params.get(:text);
		//log = new Log(Lang.format("TriText.$1$", [title]));
		numberOffset = loadResource(Rez.Strings.TriTextNumOffset).toNumber();
		centerOffset = loadResource(Rez.Strings.TriTextCenterOffset).toNumber();
		descOffset = loadResource(Rez.Strings.TriTextDescOffset).toNumber();
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
		var pos = gcx - centerOffset;
		dc.drawText(
			pos - 10, top, 
			0, // Graphics.FONT_XTINY
			title, 
			0 // Graphics.TEXT_JUSTIFY_RIGHT
		);
		dc.drawText(
			pos - 10, top + descOffset, 
			0, // Graphics.FONT_XTINY
			desc, 
			0 // Graphics.TEXT_JUSTIFY_RIGHT
		);
		if (suffix) {
			var sd = loadResource(Rez.Strings.shortDay);
			var sh = loadResource(Rez.Strings.shortHour);
			var sfx_len = value.find(sd) != null ? sd.length() : ( value.find(sh) != null ? sh.length() : 0 );
			var val = value.substring(0, value.length() - sfx_len);
			var sfx = value.substring(value.length() - sfx_len, value.length());
			dc.drawText(
				pos, top  - numberOffset, 
				6, // Graphics.FONT_NUMBER_MEDIUM
				val, 
				2 // Graphics.TEXT_JUSTIFY_LEFT
			);
			pos += dc.getTextWidthInPixels(val, 6) + 4; // Graphics.FONT_NUMBER_MEDIUM
			dc.drawText(
				pos, top + 8, 
				3, // Graphics.FONT_LARGE 
				sfx, 
				2 // Graphics.TEXT_JUSTIFY_LEFT
			);
		} else {
			dc.drawText(
				pos, top - numberOffset, 
				6, // Graphics.FONT_NUMBER_MEDIUM
				value, 
				2 // Graphics.TEXT_JUSTIFY_LEFT
			);
		}
		
	}
}