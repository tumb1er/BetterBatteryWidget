import Toybox.Lang;
using Toybox.System;
import Toybox.Test;

(:test)
function testDeviceCapabilities(logger as Logger) as Boolean {
    var s = System.getDeviceSettings();
    Test.assertEqualMessage(s.screenShape as Object, System.SCREEN_SHAPE_ROUND, "screen shape mismatch");
    Test.assertMessage([240, 260, 280, 390].indexOf(s.screenWidth) >=0, Lang.format("screen size mismatch: $1$", [s.screenWidth]));
    return true;
}
