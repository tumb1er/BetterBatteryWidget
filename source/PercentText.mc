using Toybox.Lang;
using Toybox.WatchUi;

class PercentText extends WatchUi.Text {
	var percent = 0.0f;
	
	function initialize(params) {
		Text.initialize(params);
		percent = params.get(:percent);
	}
	
	function draw(dc) {
		var text = formatPercent(percent);
		setText(text);
		Text.draw(dc);
	}
}