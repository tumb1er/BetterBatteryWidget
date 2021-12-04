import Toybox.Lang;
using Toybox.Graphics;

typedef ArcParams as {
    :cx as Number,
    :cy as Number,
    :r as Number,
    :p as Number,
    :startAngle as Number,
    :endAngle as Number,
    :color as Graphics.ColorType,
    :value as Float
};


class GaugeArc {
    var cx as Number, cy as Number, r as Number, p as Number, start as Number, end as Number;
    var color as Graphics.ColorType;
    var value as Float;
    var bx as Number = 0, by as Number = 0, bs as Number = 0, be as Number = 0, br as Number = 0, ballStart as Boolean? = null;
    
    public function initialize(params as ArcParams) {
        cx = params.get(:cx) as Number;
        cy = params.get(:cy) as Number;
        r = params.get(:radius) as Number;
        p = params.get(:pen) as Number;
        start = params.get(:startAngle) as Number;
        end = params.get(:endAngle) as Number;
        color = params.get(:color) as Graphics.ColorType;
        value = params.get(:value) as Float;
        
        if (start % 90 != 0) {
            initBall(start, true);
        }
        if (end % 90 != 0) {
            initBall(end, false);
        }
        br = p / 2 - 1;
    }
    
    private function initBall(a as Number, isStart as Boolean) as Void {
        ballStart = isStart;
        if (isStart) {
            bs = a - 180;
            be = a; 
        } else {
            bs = a;
            be = a + 180;
        }
        
        a = Math.toRadians(a);
        bx = Math.round(cx + r * Math.cos(a)) as Number;
        by = Math.round(cy - r * Math.sin(a)) as Number;
    }
    
    function draw(dc as Graphics.Dc) as Void {
        dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT); 
        dc.setPenWidth(1);
        dc.drawArc(cx, cy, r + (p / 2 - 1), Graphics.ARC_CLOCKWISE, start, end);
        dc.drawArc(cx, cy, r - (p / 2 - 1), Graphics.ARC_CLOCKWISE, start, end);
        if (ballStart != null) {
            dc.drawArc(bx, by, br, Graphics.ARC_CLOCKWISE, bs, be);
        }
        if (value < start) {
            dc.setPenWidth(p);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            if (ballStart) {
                dc.fillCircle(bx, by, br);
            }
            dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, start, (value > end)? value: end);
            if (value >= end) {
                var a = Math.toRadians(value);
                var vx = Math.round(cx + r * Math.cos(a));
                var vy = Math.round(cy - r * Math.sin(a));
                dc.fillCircle(vx, vy, br);
            }
        }
    }
}