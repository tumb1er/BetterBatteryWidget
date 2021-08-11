import Toybox.Lang;
using Toybox.Graphics;
using Toybox.WatchUi;

class PercentText extends WatchUi.Text {
	var percent as Float = 0.0f;
	
	function initialize(params as { 
			:text as String or Symbol, 
			:color as Graphics.ColorType, 
			:backgroundColor as Graphics.ColorType, 
			:font as Graphics.FontType, 
			:justification as Graphics.TextJustification or Number,
			:percent as Float}) {
		Text.initialize(params);
		percent = params.get(:percent) as Float;
	}
	
	function draw(dc) {
		var text = formatPercent(percent);
		setText(text);
		Text.draw(dc);
	}
}