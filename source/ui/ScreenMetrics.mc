import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;

// Runtime screen shape/resolution snapshot, rebuilt once per onUpdate().
// Every layout number downstream is expressed as px(<value designed at
// 416 px>) rather than a hardcoded pixel, so one composition survives from a
// 176 px Instinct to a 454 px Venu without per-device layouts or art.
class ScreenMetrics {

    // 416x416 (Instinct 3 AMOLED 50mm, the test watch) is the baseline every
    // layout constant in this project is quoted against.
    const BASELINE_MIN_DIM = 416.0;

    var width as Number;
    var height as Number;
    var centerX as Number;
    var centerY as Number;
    var minDim as Number;
    var scale as Float;
    var isRound as Boolean;

    function initialize(dc as Graphics.Dc) {
        width = dc.getWidth();
        height = dc.getHeight();
        centerX = width / 2;
        centerY = height / 2;
        minDim = (width < height) ? width : height;
        scale = minDim / BASELINE_MIN_DIM;

        var shape = System.getDeviceSettings().screenShape;
        isRound = (shape == System.SCREEN_SHAPE_ROUND
            || shape == System.SCREEN_SHAPE_SEMI_ROUND
            || shape == System.SCREEN_SHAPE_SEMI_OCTAGON);
    }

    // tier: 0=xtiny .. 4=large.
    //
    // The FONT_SYSTEM_* variants rather than the plain FONT_*: the plain ones
    // follow the watch's global font-size setting, which would resize the
    // quote out of its circle on a watch set to "large". This app controls its
    // own type, and then fits every string at draw time anyway.
    function fontFor(tier as Number) as Graphics.FontType {
        var bumped = (scale >= 1.4) && (tier < 3);
        var t = bumped ? tier + 1 : tier;
        if (t <= 0) {
            return Graphics.FONT_SYSTEM_XTINY;
        } else if (t == 1) {
            return Graphics.FONT_SYSTEM_TINY;
        } else if (t == 2) {
            return Graphics.FONT_SYSTEM_SMALL;
        } else if (t == 3) {
            return Graphics.FONT_SYSTEM_MEDIUM;
        }
        return Graphics.FONT_SYSTEM_LARGE;
    }

    // Convert a length designed at the baseline to this screen's scale.
    function px(baselinePixels as Number or Float) as Number {
        return (baselinePixels * scale).toNumber();
    }
}
