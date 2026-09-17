import Toybox.Graphics;
import Toybox.Lang;

// The logo: bare footprints.
//
// Geometry is authored for one right foot in a normalised 44 x 100 box - toes
// at the top, heel at the bottom - built from three rounded slabs (forefoot
// pad, arch, heel) and five toe dots. A left foot is the same numbers
// mirrored about the box's vertical centre line, which is why FootprintPen
// carries a mirror flag rather than there being a second set of coordinates
// to keep in sync.
//
// Two ways to place them:
//
//   drawPair    a left and a right, staggered into a stride. The hero mark on
//               the start screen, and the app icon.
//   drawSingle  one right foot. The small mark at the top of the summary
//               screen, where a pair at that size would shrink each toe to a
//               single pixel and turn the whole thing to mush.
//
// The toe dots are what make this read as a *bare* foot rather than a shoe
// sole, so they get a minimum radius of one pixel and survive at any size the
// app actually draws.
module FootprintMark {

    // Normalised box of one print, and of the staggered pair.
    const PRINT_WIDTH = 44.0;
    const PRINT_HEIGHT = 100.0;
    const PAIR_WIDTH = 96.0;
    const PAIR_HEIGHT = 116.0;

    // Where each foot sits inside the pair box. The right foot leads, so it
    // sits forward (higher) and to the right; the left trails behind it.
    const LEFT_OFFSET_X = 0.0;
    const LEFT_OFFSET_Y = 16.0;
    const RIGHT_OFFSET_X = 52.0;
    const RIGHT_OFFSET_Y = 0.0;

    function drawPair(dc as Graphics.Dc, centerXPos as Number, centerYPos as Number, width as Number, color as Graphics.ColorType) as Void {
        var s = width / PAIR_WIDTH;
        var originX = centerXPos - width / 2;
        var originY = centerYPos - (PAIR_HEIGHT * s).toNumber() / 2;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        drawPrint(dc, new FootprintPen(
            originX + (LEFT_OFFSET_X * s).toNumber(),
            originY + (LEFT_OFFSET_Y * s).toNumber(), s, true));
        drawPrint(dc, new FootprintPen(
            originX + (RIGHT_OFFSET_X * s).toNumber(),
            originY + (RIGHT_OFFSET_Y * s).toNumber(), s, false));
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    function drawSingle(dc as Graphics.Dc, centerXPos as Number, centerYPos as Number, width as Number, color as Graphics.ColorType) as Void {
        var s = width / PRINT_WIDTH;
        var originX = centerXPos - width / 2;
        var originY = centerYPos - (PRINT_HEIGHT * s).toNumber() / 2;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        drawPrint(dc, new FootprintPen(originX, originY, s, false));
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // The print itself, in normalised units. Both call sites above have
    // already decided where it goes and how big it is.
    // Three slabs and five dots.
    //
    // The proportions are what make it read as a footprint rather than a
    // blob: the heel is narrower than the forefoot, and the arch slab is
    // flush with the *outer* edge of the foot while cutting well in on the
    // inner, big-toe side - which is where a real print's arch is missing.
    // An arch centred between the two instead leaves a notch on both sides
    // and the whole thing reads as a keyhole.
    function drawPrint(dc as Graphics.Dc, pen as FootprintPen) as Void {
        pen.roundRect(dc, 2.0, 21.0, 40.0, 28.0, 13.0);   // forefoot pad
        pen.roundRect(dc, 16.0, 44.0, 25.0, 34.0, 12.0);  // arch
        pen.roundRect(dc, 8.0, 70.0, 28.0, 28.0, 13.0);   // heel

        pen.toe(dc, 9.0, 11.0, 7.5);
        pen.toe(dc, 21.0, 7.5, 5.2);
        pen.toe(dc, 30.0, 10.0, 4.5);
        pen.toe(dc, 36.5, 14.5, 3.9);
        pen.toe(dc, 40.5, 20.0, 3.2);
    }
}

// Scales normalised footprint coordinates onto the screen, mirroring them
// about the print's centre line for a left foot.
//
// It exists as an object rather than a set of module functions taking an
// origin because the low-end devices in the target list cap methods at nine
// arguments, and "dc, originX, originY, scale, mirror, x, y, w, h, radius" is
// ten. Holding the first five as state gets every call comfortably under.
class FootprintPen {

    private var _originX as Number;
    private var _originY as Number;
    private var _scale as Float;
    private var _mirror as Boolean;

    function initialize(originX as Number, originY as Number, scale as Float, mirror as Boolean) {
        _originX = originX;
        _originY = originY;
        _scale = scale;
        _mirror = mirror;
    }

    function roundRect(dc as Graphics.Dc, x as Float, y as Float, w as Float, h as Float, r as Float) as Void {
        var left = _mirror ? (FootprintMark.PRINT_WIDTH - x - w) : x;
        dc.fillRoundedRectangle(
            _originX + scaled(left), _originY + scaled(y),
            scaled(w), scaled(h), atLeastOne(r));
    }

    function toe(dc as Graphics.Dc, cx as Float, cy as Float, r as Float) as Void {
        var centerX = _mirror ? (FootprintMark.PRINT_WIDTH - cx) : cx;
        dc.fillCircle(_originX + scaled(centerX), _originY + scaled(cy), atLeastOne(r));
    }

    private function scaled(value as Float) as Number {
        return (value * _scale).toNumber();
    }

    // A toe that rounds to nothing stops the mark reading as a bare foot, so
    // sub-pixel radii are floored rather than dropped.
    private function atLeastOne(value as Float) as Number {
        var scaledValue = (value * _scale).toNumber();
        return (scaledValue < 1) ? 1 : scaledValue;
    }
}
