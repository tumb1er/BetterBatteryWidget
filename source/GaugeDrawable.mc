import Toybox.Lang;
using Toybox.Graphics;
using Toybox.WatchUi;


class GaugeDrawable extends WatchUi.Drawable {
    var mArcs as Array<GaugeArc>;
    var mText as Graphics.Text;
    var mIcon as Graphics.Bitmap;
    var value as Float = 0.0;
    var color as Graphics.ColorType = 0xFFFFFF;
    
    function initialize(params as {
        :radius as Number,
        :color as Graphics.ColorType,
        :pen as Number,
    }) {
        Drawable.initialize(params);
        var r = params.get(:radius) as Number;
        var r1 = r - 1;
        color = params.get(:color) as Graphics.ColorType;
        var pen = params.get(:pen) as Number;
        var arc = {
            :pen => pen,
            :radius => r - pen / 2,
            :color => color
        };
        mArcs = [
            initArc(arc, r1, r,  600, 540),
            initArc(arc, r1, r1, 540, 450),
            initArc(arc, r,  r1, 450, 360),
            initArc(arc, r,  r,  360, 300)
        ] as Array<GaugeArc>;        
    }
    
    private function initArc(arc as ArcParams, cx as Number, cy as Number, start as Number, end as Number) as GaugeArc {
        arc.put(:cx, cx);
        arc.put(:cy, cy);
        arc.put(:startAngle, start);
        arc.put(:endAngle, end);
        return new GaugeArc(arc);
    }
    
    function draw(dc) {
        var v = 600 - 3 * value;
        for (var i = 0; i < mArcs.size(); i++) {
            var arc = mArcs[i] as GaugeArc;
            arc.value = v;
            arc.color = color;
            arc.draw(dc);
        }
    }
}