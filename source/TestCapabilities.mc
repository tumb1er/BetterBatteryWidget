using Toybox.Lang;
using Toybox.System;
using Toybox.Test;

(:test)
function testDeviceCapabilities(logger) {
	var s = System.getDeviceSettings();
	Test.assertEqualMessage(s.screenShape, System.SCREEN_SHAPE_ROUND, "screen shape mismatch");
	Test.assertMessage([240, 260, 280].indexOf(s.screenWidth) >=0, Lang.format("screen width mismatch: $1$", [s.screenWidth]));
	Test.assertMessage([240, 260, 280].indexOf(s.screenHeight) >=0, Lang.format("screen height mismatch: $1$", [s.screenHeight]));
	return true;
}
