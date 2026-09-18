import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// The footprints, the wordmark, the promise, and how to begin. No numbers - not
// even a clock, because a screen that shows you the time is already the thing
// this app is trying not to be.
module StartScreen {

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, controller as RunController) as Void {
        var ready = controller.isGpsReady();

        if (!ready) {
            drawGpsStatus(dc, metrics, layout, controller.searchTicks());
        }

        FootprintMark.drawPair(dc, metrics.centerX, layout.markCenterY, layout.markWidth,
            Palette.AMBER);

        drawWordmark(dc, metrics, layout);

        dc.setColor(Palette.AMBER_DIM, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, layout.taglineY, 1,
            WatchUi.loadResource(Rez.Strings.Tagline) as String,
            layout.safeWidthForLine(metrics, layout.taglineY, metrics.px(30)));

        drawStartMark(dc, metrics, layout, ready);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // The fix status, at the top and out of the way. It is a status, not an
    // instruction, so it sits where a watch puts status rather than where it
    // puts a prompt - and when there is a fix it is absent entirely, because
    // "GPS is fine" is not news worth a line of type.
    //
    // The moving dots are the difference between "this watch is searching" and
    // "this watch is stuck". Static text alone cannot tell those apart, and
    // the wait is exactly when someone starts wondering whether it has hung.
    function drawGpsStatus(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, ticks as Number) as Void {
        dc.setColor(Palette.AMBER_DIM, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, layout.gpsStatusY, 0,
            WatchUi.loadResource(Rez.Strings.GpsTitle) as String,
            layout.safeWidthForLine(metrics, layout.gpsStatusY, metrics.px(24)));

        Hud.drawSearchDots(dc, metrics, layout.gpsDotsY, ticks, metrics.px(5), metrics.px(16));
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

    // Two lines, set as large as the circle allows and centred as a block.
    // "NAKED RUN" on one line would have to shrink to about half this size to
    // fit a 176 px screen, and the wordmark is the loudest thing in the app.
    function drawWordmark(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout) as Void {
        var top = WatchUi.loadResource(Rez.Strings.WordmarkTop) as String;
        var bottom = WatchUi.loadResource(Rez.Strings.WordmarkBottom) as String;

        var font = metrics.fontFor(4);
        var lineH = dc.getFontHeight(font);
        var blockTop = layout.wordmarkCenterY - lineH;

        // The wider of the two words decides the tier, so they set at the
        // same size rather than "RUN" ending up a step larger than "NAKED".
        var available = 2 * layout.safeHalfWidth(metrics, blockTop, blockTop + 2 * lineH);
        var tier = 4;
        while (tier > 0
                && (dc.getTextWidthInPixels(top, metrics.fontFor(tier)) > available
                    || dc.getTextWidthInPixels(bottom, metrics.fontFor(tier)) > available)) {
            tier -= 1;
        }

        font = metrics.fontFor(tier);
        lineH = dc.getFontHeight(font);
        blockTop = layout.wordmarkCenterY - lineH;

        dc.setColor(Palette.BONE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(metrics.centerX, blockTop, font, top, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Palette.AMBER, Graphics.COLOR_TRANSPARENT);
        dc.drawText(metrics.centerX, blockTop + lineH, font, bottom, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
