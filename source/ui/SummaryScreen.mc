import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Everything the run screen refused to show, all at once.
//
// The hierarchy is deliberate: time is the hero because it is the number a
// runner actually chose - they decided to go out for forty minutes - while
// distance, pace and the two heart rates are the consequences, and sit in a
// quiet 2x2 grid underneath at a quarter of the size.
//
// Values come from the RunSummary snapshot taken before the session was
// saved, never from a live Activity.Info, which by this point has nothing
// left to report.
module SummaryScreen {

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, controller as RunController) as Void {
        // A single print here rather than the start screen's pair: at this
        // size a pair would give each toe less than a pixel.
        FootprintMark.drawSingle(dc, metrics.centerX, layout.summaryMarkCenterY,
            layout.summaryMarkWidth, Palette.AMBER);

        var discarded = (controller.endReason() == RunConstants.END_DISCARDED);
        dc.setColor(discarded ? Palette.GREY : Palette.AMBER, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, layout.titleY, 1,
            WatchUi.loadResource(discarded
                ? Rez.Strings.SummaryDiscarded
                : Rez.Strings.SummaryTitle) as String,
            layout.safeWidthForLine(metrics, layout.titleY, metrics.px(28)));

        var summary = controller.summary();
        if (summary == null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            return;
        }

        drawHero(dc, metrics, layout, summary);
        drawGrid(dc, metrics, layout, summary);

        dc.setColor(Palette.GREY, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, layout.hintY, 0,
            WatchUi.loadResource(Rez.Strings.HintDone) as String,
            layout.safeWidthForLine(metrics, layout.hintY, metrics.px(24)));
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // Total time, in the largest number font that fits the band between the
    // title and the grid.
    function drawHero(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, summary as RunSummary) as Void {
        var text = Utils.formatClock(summary.seconds);
        var band = layout.gridTop - layout.heroTop;
        var maxWidth = 2 * layout.safeHalfWidth(metrics, layout.heroTop, layout.gridTop);

        var font = Hud.fitNumberFont(dc, metrics, text, maxWidth, band);
        var y = layout.heroTop + (band - dc.getFontHeight(font)) / 2;
        if (y < layout.heroTop) {
            y = layout.heroTop;
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
    function drawGrid(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, summary as RunSummary) as Void {
        var rowHeight = (layout.gridBottom - layout.gridTop) / 2;
        var midY = layout.gridTop + rowHeight;

        var ruleHalf = layout.safeHalfWidth(metrics, midY, midY) - metrics.px(10);
        if (ruleHalf > metrics.px(10)) {
            dc.setColor(Palette.CHARCOAL, Graphics.COLOR_TRANSPARENT);
            var pen = metrics.px(2);
            dc.setPenWidth(pen > 0 ? pen : 1);
            dc.drawLine(metrics.centerX - ruleHalf, midY, metrics.centerX + ruleHalf, midY);
            dc.setPenWidth(1);
        }

        drawRow(dc, metrics, layout, layout.gridTop, rowHeight,
            WatchUi.loadResource(Rez.Strings.LabelDistance) as String,
            Utils.formatDistance(summary.meters),
            WatchUi.loadResource(Rez.Strings.LabelPace) as String,
            Utils.formatPace(summary.meters, summary.seconds));

        drawRow(dc, metrics, layout, midY, rowHeight,
            WatchUi.loadResource(Rez.Strings.LabelHeartRate) as String,
            Utils.formatOptionalNumber(summary.averageHeartRate),
            WatchUi.loadResource(Rez.Strings.LabelMaxHeartRate) as String,
            Utils.formatOptionalNumber(summary.maxHeartRate));
    }

    function drawRow(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, rowTop as Number, rowHeight as Number, leftLabel as String, leftValue as String, rightLabel as String, rightValue as String) as Void {
        var half = layout.safeHalfWidth(metrics, rowTop, rowTop + rowHeight);
        var cellWidth = half - metrics.px(8);
        if (cellWidth < metrics.px(30)) {
            cellWidth = metrics.px(30);
        }

        var labelFont = metrics.fontFor(0);
        var labelHeight = dc.getFontHeight(labelFont);
        var valueHeight = dc.getFontHeight(metrics.fontFor(2));
        var blockTop = rowTop + (rowHeight - (labelHeight + valueHeight)) / 2;
        if (blockTop < rowTop) {
            blockTop = rowTop;
        }

        drawCell(dc, metrics, metrics.centerX - half / 2, blockTop, labelHeight, cellWidth, leftLabel, leftValue);
        drawCell(dc, metrics, metrics.centerX + half / 2, blockTop, labelHeight, cellWidth, rightLabel, rightValue);
    }

    function drawCell(dc as Graphics.Dc, metrics as ScreenMetrics, x as Number, top as Number, labelHeight as Number, maxWidth as Number, label as String, value as String) as Void {
        dc.setColor(Palette.AMBER_DIM, Graphics.COLOR_TRANSPARENT);
        drawFitAt(dc, metrics, x, top, 0, label, maxWidth);

        dc.setColor(Palette.BONE, Graphics.COLOR_TRANSPARENT);
        drawFitAt(dc, metrics, x, top + labelHeight, 2, value, maxWidth);
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
