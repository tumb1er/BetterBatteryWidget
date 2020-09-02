using Toybox.Lang;
using Toybox.System;
using Toybox.Test;

(:test)
function testDeviceCapabilities(logger) {
	var s = System.getDeviceSettings();
	Test.assertEqualMessage(s.screenShape, System.SCREEN_SHAPE_ROUND, "screen shape mismatch");
	Test.assertMessage([240, 260, 280, 390].indexOf(s.screenWidth) >=0, Lang.format("screen size mismatch: $1$", [s.screenWidth]));
	return true;
}
