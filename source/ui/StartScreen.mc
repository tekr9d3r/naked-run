import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// The footprints, the wordmark, the promise, and how to begin. No numbers -
// not even a clock, because a screen that shows you the time is already the
// thing this app is trying not to be.
//
// LAYOUT
//
// This screen stacks itself from measured heights instead of fixed anchors,
// for the same reason the summary does: Garmin's fonts do not scale with the
// screen. Measured on the extremes of the target list -
//
//                  XTINY  LARGE   "NAKED"   the tagline
//      fr55 208px     22     34      80px        178px
//     fenix 416px     28     59     158px        247px
//
// - the tagline is 178 px wide on a 208 px watch whose widest usable chord is
// 188 px and whose chord at the bottom of the screen is barely half that. So
// it can never sit under the wordmark there, while on a 416 px screen it fits
// comfortably. One set of px() constants cannot say both things, and trying
// made the search dots print through the status text above them.
//
// So: the status line and its dots are pinned to the top and their positions
// derived from the measured text, and everything below them - mark, wordmark
// and tagline - is measured, stacked, and then centred in what is left. Where
// the tagline does not fit it is dropped and the remaining two re-centre,
// which is why the mark sits lower on a small screen than a large one.
module StartScreen {

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, controller as RunController) as Void {
        var ready = controller.isGpsReady();
        var gap = metrics.px(12);
        var dotRadius = metrics.px(5);
        if (dotRadius < 2) {
            dotRadius = 2;
        }

        // The dots hang below the status text by its own measured height.
        // Pinning them to a px() offset is what let them overlap the letters.
        var dotsY = layout.gpsStatusY + dc.getFontHeight(metrics.fontFor(0)) + gap + dotRadius;

        if (!ready) {
            dc.setColor(Palette.AMBER_DIM, Graphics.COLOR_TRANSPARENT);
            Hud.drawFitCenteredText(dc, metrics, layout.gpsStatusY, 0,
                WatchUi.loadResource(Rez.Strings.GpsTitle) as String,
                layout.safeWidthForLine(metrics, layout.gpsStatusY,
                    dc.getFontHeight(metrics.fontFor(0))));
            Hud.drawSearchDots(dc, metrics, dotsY, controller.searchTicks(),
                dotRadius, metrics.px(16));
        }

        // The top of the stack is reserved whether or not the status is
        // showing, so nothing jumps when the fix finally lands.
        var contentTop = dotsY + dotRadius + metrics.px(14);
        drawStack(dc, metrics, layout, contentTop, gap);

        drawStartMark(dc, metrics, layout, ready);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // Mark, wordmark and - if there is room for it - tagline, measured and
    // centred in the band beneath the status line.
    function drawStack(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, contentTop as Number, gap as Number) as Void {
        // FootprintMark's box is declared in Floats, so this is explicitly
        // brought back to whole pixels before anything is positioned off it.
        var markHeight = (layout.markWidth * FootprintMark.PAIR_HEIGHT
            / FootprintMark.PAIR_WIDTH).toNumber();
        var wordTier = fitWordmarkTier(dc, metrics, layout);
        var wordHeight = 2 * dc.getFontHeight(metrics.fontFor(wordTier));

        var band = layout.contentBottom - contentTop;
        var coreHeight = markHeight + gap + wordHeight;
        var taglineBand = band - coreHeight - gap;

        var text = WatchUi.loadResource(Rez.Strings.Tagline) as String;
        var showTagline = taglineBand > 0
            && Hud.wrappedFits(dc, metrics, layout, text,
                layout.contentBottom - taglineBand, layout.contentBottom, 1);

        // With a tagline the stack fills the band from the top; without one
        // the remaining two centre themselves, which is what drops the mark
        // and wordmark lower on the screens that cannot take the tagline.
        var top = showTagline ? contentTop : contentTop + (band - coreHeight) / 2;
        if (top < contentTop) {
            top = contentTop;
        }

        FootprintMark.drawPair(dc, metrics.centerX, top + markHeight / 2,
            layout.markWidth, Palette.AMBER);
        drawWordmark(dc, metrics, top + markHeight + gap, wordTier);

        if (showTagline) {
            dc.setColor(Palette.AMBER_DIM, Graphics.COLOR_TRANSPARENT);
            Hud.drawWrappedBlock(dc, metrics, layout, text,
                layout.contentBottom - taglineBand, layout.contentBottom, 1);
        }
    }

    // The wider of the two words decides the tier, so they set at the same
    // size rather than "RUN" ending up a step larger than "NAKED". Measured
    // against the widest chord the block could occupy, which is generous -
    // the wordmark sits near the middle of the glass, where the circle is at
    // its widest anyway.
    function fitWordmarkTier(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout) as Number {
        var top = WatchUi.loadResource(Rez.Strings.WordmarkTop) as String;
        var bottom = WatchUi.loadResource(Rez.Strings.WordmarkBottom) as String;
        var available = 2 * layout.safeHalfWidth(metrics, metrics.centerY, metrics.centerY);

        var tier = 4;
        while (tier > 0
                && (dc.getTextWidthInPixels(top, metrics.fontFor(tier)) > available
                    || dc.getTextWidthInPixels(bottom, metrics.fontFor(tier)) > available)) {
            tier -= 1;
        }
        return tier;
    }

    // Two lines. "NAKED RUN" on one would have to shrink to about half this
    // size to fit a 208 px screen, and the wordmark is the loudest thing in
    // the app.
    function drawWordmark(dc as Graphics.Dc, metrics as ScreenMetrics, blockTop as Number, tier as Number) as Void {
        var font = metrics.fontFor(tier);
        var lineHeight = dc.getFontHeight(font);

        dc.setColor(Palette.BONE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(metrics.centerX, blockTop, font,
            WatchUi.loadResource(Rez.Strings.WordmarkTop) as String,
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Palette.AMBER, Graphics.COLOR_TRANSPARENT);
        dc.drawText(metrics.centerX, blockTop + lineHeight, font,
            WatchUi.loadResource(Rez.Strings.WordmarkBottom) as String,
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    // The button hint: a curved stroke hugging the bezel alongside the
    // physical START button, in place of a line of text naming it. It is the
    // same shape Garmin's own activity apps use, which is the point - a runner
    // has already learned to read an arc at the rim as "this button, here",
    // and borrowing that costs nothing and teaches nothing new.
    //
    // An arc rather than a straight tick because it follows the glass. A
    // horizontal line at the rim of a circle meets the curve at an angle and
    // reads as a stray mark; a concentric arc reads as part of the bezel.
    //
    // Angles are Dc's: 0 at three o'clock, counter-clockwise positive. 18-42
    // degrees is a short sweep centred on 30 degrees - two o'clock exactly -
    // which is where the upper right-hand button sits on both the 5-button
    // watches (fenix, Instinct) and the 2-button ones (Venu).
    //
    // Amber when a fix is in and the press will start a run; grey while one is
    // still coming, so the mark shows where the button is without pretending
    // it is ready. Grey rather than the charcoal of the unlit search dots -
    // charcoal on true black is near enough invisible, and a button marker you
    // cannot find is worse than none. The dots get away with it only because
    // they sit in a lit row that gives them context.
    const START_ARC_FROM_DEG = 42;
    const START_ARC_TO_DEG = 18;

    function drawStartMark(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, ready as Boolean) as Void {
        var pen = metrics.px(9);
        if (pen < 3) {
            pen = 3;
        }

        dc.setColor(ready ? Palette.AMBER : Palette.GREY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(pen);

        if (metrics.isRound) {
            dc.drawArc(metrics.centerX, metrics.centerY,
                metrics.minDim / 2 - pen / 2 - metrics.px(2),
                Graphics.ARC_CLOCKWISE, START_ARC_FROM_DEG, START_ARC_TO_DEG);
        } else {
            // No curve to follow on a rectangle, so the same idea as a
            // straight run down the right edge beside the button.
            var x = metrics.width - pen / 2 - metrics.px(2);
            var midY = metrics.centerY - metrics.px(56);
            var half = metrics.px(34);
            dc.drawLine(x, midY - half, x, midY + half);
        }

        dc.setPenWidth(1);
    }
}
