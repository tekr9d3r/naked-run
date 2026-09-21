import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Everything the run screen refused to show, all at once.
//
// The hierarchy is deliberate: time is the hero because it is the number a
// runner actually chose - they decided to go out for forty minutes - while
// distance, pace and the two heart rates are the consequences, and sit in a
// quiet 2x2 grid underneath at a fraction of the size.
//
// Values come from the RunSummary snapshot taken before the session was
// saved, never from a live Activity.Info, which by this point has nothing
// left to report.
//
// LAYOUT
//
// Every vertical position here is derived from measured font heights rather
// than from px() constants, because Garmin's fonts emphatically do not scale
// with the screen. Measured on the two extremes of the target list:
//
//               XTINY  TINY  SMALL  NUMBER_MILD
//   fr55  208px    22    25     27           37
//   fenix 416px    28    36     42           84
//
// The screen doubles; XTINY grows by a quarter and MILD by two and a third.
// So a layout in px() that looks generous at 416 starves at 208 and vice
// versa, which is how the grid's second row once printed through its first.
//
// Instead: the title takes what it measures, the grid measures itself and
// claims its space from the bottom up, and the hero takes the band left in
// between. If that band comes out smaller than the smallest number font can
// draw, the footprint mark is dropped and the title slides up to buy it back.
module SummaryScreen {

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, controller as RunController) as Void {
        var summary = controller.summary();
        var titleHeight = dc.getFontHeight(metrics.fontFor(1));
        var minHero = dc.getFontHeight(Graphics.FONT_SYSTEM_NUMBER_MILD);
        var gap = metrics.px(10);

        // First attempt keeps the mark. If the hero ends up with less room
        // than the smallest number font needs, the mark is the thing that
        // goes: it is decoration, and the time is the point of the screen.
        var showMark = true;
        var titleY = layout.titleY;
        var heroTop = titleY + titleHeight + gap;
        var valueTier = fitValueTier(dc, metrics, layout, heroTop, minHero);
        var gridTop = layout.gridBottom - gridHeight(dc, metrics, valueTier);

        if (gridTop - heroTop < minHero) {
            showMark = false;
            titleY = layout.titleYNoMark;
            heroTop = titleY + titleHeight + gap;
            valueTier = fitValueTier(dc, metrics, layout, heroTop, minHero);
            gridTop = layout.gridBottom - gridHeight(dc, metrics, valueTier);
        }

        if (showMark) {
            // A single print rather than the start screen's pair: at this
            // size a pair would give each toe less than a pixel.
            FootprintMark.drawSingle(dc, metrics.centerX, layout.summaryMarkCenterY,
                layout.summaryMarkWidth, Palette.AMBER);
        }

        var discarded = (controller.endReason() == RunConstants.END_DISCARDED);
        dc.setColor(discarded ? Palette.GREY : Palette.AMBER, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, titleY, 1,
            WatchUi.loadResource(discarded
                ? Rez.Strings.SummaryDiscarded
                : Rez.Strings.SummaryTitle) as String,
            layout.safeWidthForLine(metrics, titleY, titleHeight));

        if (summary == null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            return;
        }

        drawHero(dc, metrics, layout, summary, heroTop, gridTop);
        drawGrid(dc, metrics, layout, summary, gridTop, valueTier);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // Height of one cell's worth of type, doubled, plus the gap between the
    // two rows. Everything measured, nothing assumed.
    function gridHeight(dc as Graphics.Dc, metrics as ScreenMetrics, valueTier as Number) as Number {
        return 2 * (dc.getFontHeight(metrics.fontFor(0))
            + dc.getFontHeight(metrics.fontFor(valueTier))) + rowGap(metrics);
    }

    function rowGap(metrics as ScreenMetrics) as Number {
        var gap = metrics.px(12);
        return (gap < 3) ? 3 : gap;
    }

    // The largest value font that still leaves the hero room to draw.
    //
    // The floor is the measured height of the smallest number font, not a
    // px() guess, and that distinction is the whole point: fitNumberFont()
    // steps down to FONT_SYSTEM_NUMBER_MILD and then returns it whether it
    // fits or not, exactly as the text fitters bottom out at tier 0. A
    // guessed floor that came in under MILD's real height let the hero
    // overrun its band and print into the grid's first row.
    function fitValueTier(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, heroTop as Number, minHero as Number) as Number {
        var available = layout.gridBottom - heroTop - minHero;
        var tier = 2;
        while (tier > 0 && gridHeight(dc, metrics, tier) > available) {
            tier -= 1;
        }
        return tier;
    }

    // Total time, in the largest number font that fits the band between the
    // title and whatever the grid left behind.
    function drawHero(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, summary as RunSummary, heroTop as Number, gridTop as Number) as Void {
        var text = Utils.formatClock(summary.seconds);
        var band = gridTop - heroTop;
        var font = Hud.fitNumberFont(dc, metrics, text,
            2 * layout.safeHalfWidth(metrics, heroTop, gridTop), band);

        var y = heroTop + (band - dc.getFontHeight(font)) / 2;
        if (y < heroTop) {
            y = heroTop;
        }

        dc.setColor(Palette.BONE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(metrics.centerX, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Distance / avg pace over avg HR / max HR.
    //
    // Column positions are recomputed per row from the circular safe width at
    // that row's own height, so the bottom row - which on a round screen has
    // noticeably less width to work with than the one above it - pulls its
    // two cells inward instead of pushing them off the glass.
    function drawGrid(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, summary as RunSummary, gridTop as Number, valueTier as Number) as Void {
        var cellHeight = dc.getFontHeight(metrics.fontFor(0))
            + dc.getFontHeight(metrics.fontFor(valueTier));
        var gap = rowGap(metrics);

        // The divider lives in the gap between the rows, the only strip on
        // this screen guaranteed to have no type in it.
        var ruleY = gridTop + cellHeight + gap / 2;
        var ruleHalf = layout.safeHalfWidth(metrics, ruleY, ruleY) - metrics.px(10);
        if (ruleHalf > metrics.px(10)) {
            dc.setColor(Palette.CHARCOAL, Graphics.COLOR_TRANSPARENT);
            var pen = metrics.px(2);
            dc.setPenWidth(pen > 0 ? pen : 1);
            dc.drawLine(metrics.centerX - ruleHalf, ruleY, metrics.centerX + ruleHalf, ruleY);
            dc.setPenWidth(1);
        }

        drawRow(dc, metrics, layout, gridTop, cellHeight, valueTier,
            [WatchUi.loadResource(Rez.Strings.LabelDistance) as String,
             WatchUi.loadResource(Rez.Strings.LabelDistanceShort) as String,
             WatchUi.loadResource(Rez.Strings.LabelPace) as String,
             WatchUi.loadResource(Rez.Strings.LabelPaceShort) as String],
            [Utils.formatDistance(summary.meters),
             Utils.formatPace(summary.meters, summary.seconds)]);

        drawRow(dc, metrics, layout, gridTop + cellHeight + gap, cellHeight, valueTier,
            [WatchUi.loadResource(Rez.Strings.LabelHeartRate) as String,
             WatchUi.loadResource(Rez.Strings.LabelHeartRateShort) as String,
             WatchUi.loadResource(Rez.Strings.LabelMaxHeartRate) as String,
             WatchUi.loadResource(Rez.Strings.LabelMaxHeartRateShort) as String],
            [Utils.formatOptionalNumber(summary.averageHeartRate),
             Utils.formatOptionalNumber(summary.maxHeartRate)]);
    }

    // `labels` is [fullLeft, shortLeft, fullRight, shortRight] and `values`
    // is [left, right]. They arrive as arrays rather than six separate
    // strings because the low-end devices in the target list cap methods at
    // nine arguments.
    //
    // The two column centres sit exactly `half` apart, so a cell wider than
    // `half` runs into its neighbour - and tier 0 is the smallest font there
    // is, so a label that does not fit cannot be shrunk, only swapped. The
    // bottom row is where this bites: it sits low on the circle and gets
    // barely half the width of the row above it, which is how "AVG HR" and
    // "MAX HR" once printed through each other as "AVG HMAX HR".
    function drawRow(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, rowTop as Number, cellHeight as Number, valueTier as Number, labels as Array<String>, values as Array<String>) as Void {
        var half = layout.safeHalfWidth(metrics, rowTop, rowTop + cellHeight);
        var cellWidth = half - metrics.px(6);
        if (cellWidth < metrics.px(24)) {
            cellWidth = metrics.px(24);
        }
        var labelFont = metrics.fontFor(0);
        var labelHeight = dc.getFontHeight(labelFont);

        for (var i = 0; i < 2; i += 1) {
            var x = metrics.centerX + ((i == 0) ? -half / 2 : half / 2);

            var label = labels[i * 2];
            if (dc.getTextWidthInPixels(label, labelFont) > cellWidth) {
                label = labels[i * 2 + 1];
            }

            dc.setColor(Palette.AMBER_DIM, Graphics.COLOR_TRANSPARENT);
            drawFitAt(dc, metrics, x, rowTop, 0, label, cellWidth);

            dc.setColor(Palette.BONE, Graphics.COLOR_TRANSPARENT);
            drawFitAt(dc, metrics, x, rowTop + labelHeight, valueTier, values[i], cellWidth);
        }
    }

    // Hud's fitting helper centres on the screen; a grid cell needs the same
    // behaviour around an arbitrary column centre.
    function drawFitAt(dc as Graphics.Dc, metrics as ScreenMetrics, x as Number, y as Number, tier as Number, text as String, maxWidth as Number) as Void {
        var t = tier;
        while (t > 0 && dc.getTextWidthInPixels(text, metrics.fontFor(t)) > maxWidth) {
            t -= 1;
        }
        dc.drawText(x, y, metrics.fontFor(t), text, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
