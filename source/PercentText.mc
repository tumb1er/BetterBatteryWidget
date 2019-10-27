using Toybox.Lang;
using Toybox.WatchUi;

class PercentText extends WatchUi.Text {
	var percent = 0.0f;
	
	function initialize(params) {
		Text.initialize(params);
		percent = params.get(:percent);
	}
	
	function draw(dc) {
		setText(Lang.format("$1$%", [percent.format("%.1f")]));
		Text.draw(dc);
	}
}