import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// The footprints, the wordmark, the promise, and how to begin. No numbers - not
// even a clock, because a screen that shows you the time is already the thing
// this app is trying not to be.
module StartScreen {

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, controller as RunController) as Void {
        FootprintMark.drawPair(dc, metrics.centerX, layout.markCenterY, layout.markWidth,
            Palette.AMBER);

        drawWordmark(dc, metrics, layout);

        dc.setColor(Palette.AMBER_DIM, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, layout.taglineY, 1,
            WatchUi.loadResource(Rez.Strings.Tagline) as String,
            layout.safeWidthForLine(metrics, layout.taglineY, metrics.px(30)));

        drawStartPrompt(dc, metrics, layout, controller.isGpsReady());
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // The prompt doubles as the GPS indicator, so the state of the fix is
    // visible before the button is pressed rather than only after. When a fix
    // is still coming this says so in amber; pressing anyway is allowed and
    // simply lands on the gate, which is a better answer than a dead button
    // with no explanation.
    function drawStartPrompt(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, ready as Boolean) as Void {
        dc.setColor(ready ? Palette.GREY : Palette.AMBER_DIM, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, layout.hintY, 0,
            WatchUi.loadResource(ready
                ? Rez.Strings.HintStart
                : Rez.Strings.HintSearching) as String,
            layout.safeWidthForLine(metrics, layout.hintY, metrics.px(24)));
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
