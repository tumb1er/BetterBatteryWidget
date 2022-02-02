import Toybox.Lang;
using Toybox.Graphics;
using Toybox.WatchUi;


typedef TriTextParams as {
    :color as Graphics.ColorValue,
    :title as String,
    :value as String,
    :desc as String,
    :suffix as Boolean,
    :text as String
};


class TriText extends WatchUi.Text {
    var color as Graphics.ColorValue = Graphics.COLOR_BLACK;
    var suffix as Boolean = true;
    var title as String = "", desc as String = "", value as String = "", text as String = "";
    // var log as Log;
    var numberOffset as Number = 0, centerOffset as Number = 0, descOffset as Number = 0; 
    
    public function initialize(params as TriTextParams) {
        Text.initialize(params);
        color = params.get(:color) as Graphics.ColorValue;
        title = params.get(:title) as String;
        value = params.get(:value) as String;
        desc = params.get(:desc) as String;
        text = params.get(:text) as String;
        suffix = params.get(:suffix) as Boolean;
        // log = new Log(Lang.format("TriText.$1$", [title]));
        numberOffset = Application.Properties.getValue("TTNO");
        centerOffset = Application.Properties.getValue("TTCO");
        descOffset = Application.Properties.getValue("TTDO");
    }
    
    public function draw(dc as Graphics.Dc) as Void {
        dc.setColor(color, -1);  // Graphics.COLOR_TRANSPARENT
        var gcx = locX + width/2;
        var top = locY;
        // log.debug("draw", [value]);
        if (value.length() == 0) {
            // log.msg("value is null");
            dc.drawText(
                gcx, top, 
                Graphics.FONT_LARGE,
                text, 
                Graphics.TEXT_JUSTIFY_CENTER
            );
            return;
        }
        //log.debug("draw", [gcx, top]);
        var pos = gcx - centerOffset;
        // log.debug("title", title);
        dc.drawText(
            pos - 10, top, 
            Graphics.FONT_XTINY,
            title, 
            Graphics.TEXT_JUSTIFY_RIGHT
        );
        // log.debug("desc", desc);
        dc.drawText(
            pos - 10, top + descOffset, 
            Graphics.FONT_XTINY,
            desc, 
            Graphics.TEXT_JUSTIFY_RIGHT
        );
        if (suffix) {
            var sd = loadResource(Rez.Strings.shortDay) as String;
            var sh = loadResource(Rez.Strings.shortHour) as String;
            
            var sfx_len = value.find(sd) != null ? sd.length() : ( value.find(sh) != null ? sh.length() : 0 );
            var val = value.substring(0, value.length() - sfx_len) as String;
            var sfx = value.substring(value.length() - sfx_len, value.length()) as String;

            // log.debug("val", val);
            dc.drawText(
                pos, top  - numberOffset, 
                Graphics.FONT_NUMBER_MEDIUM,
                val, 
                Graphics.TEXT_JUSTIFY_LEFT
            );
            pos += dc.getTextWidthInPixels(val, Graphics.FONT_NUMBER_MEDIUM) + 4;
            
            // log.debug("sfx", sfx);
            dc.drawText(
                pos, top + 8, 
                Graphics.FONT_LARGE,
                sfx, 
                Graphics.TEXT_JUSTIFY_LEFT
            );
        } else {
            // log.debug("value", value);
            dc.drawText(
                pos, top - numberOffset, 
                Graphics.FONT_NUMBER_MEDIUM,
                value, 
                Graphics.TEXT_JUSTIFY_LEFT
            );
        }    
    }
}
