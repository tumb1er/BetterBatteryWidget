using Toybox.Lang;
using Toybox.System;
using Toybox.Test;

(:test)
function testDeviceCapabilities(logger) {
	var s = System.getDeviceSettings();
	Test.assertEqualMessage(s.screenShape, System.SCREEN_SHAPE_ROUND, "screen shape mismatch");
	Test.assertEqualMessage(s.screenWidth, 240, Lang.format("screen width mismatch: $1$", [s.screenWidth]));
	Test.assertEqualMessage(s.screenHeight, 240, Lang.format("screen height mismatch: $1$", [s.screenHeight]));
	Test.assertMessage(s.isTouchScreen, "non-touch screen");
	return true;
}