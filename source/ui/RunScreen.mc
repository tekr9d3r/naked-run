import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// The screen this app was built to show, and the shortest file that draws
// one: a quote, and a dot.
//
// Nothing here reads Activity.getActivityInfo(). Not guarded by a flag, not
// drawn in a smaller font somewhere - the data simply is not fetched, which
// is the only version of this promise that cannot be broken by a later edit
// adding "just one" field.
//
// The logo deliberately does not appear here. The start and summary screens
// are the app talking about itself; this screen is supposed to disappear.
module RunScreen {

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, controller as RunController) as Void {
        dc.setColor(Palette.BONE, Graphics.COLOR_TRANSPARENT);
        Hud.drawQuoteBlock(dc, metrics, layout, controller.currentQuote(),
            layout.quoteBandTop, layout.quoteBandBottom);

        drawRecordingDot(dc, metrics, layout, controller.dotPhase());
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // The entire user interface of a recording run.
    //
    // It breathes on a three second cycle rather than sitting still, because
    // a static dot is indistinguishable from a frozen app, and "is it still
    // recording?" is the one question this screen has to answer without
    // showing a single number. Amber at full, amber dimmed, then grey: three
    // brightness steps rather than a fade, since a MIP panel would band a
    // fade and the whole point is that the step is visible.
    function drawRecordingDot(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, phase as Number) as Void {
        var radius = metrics.px(7);
        if (radius < 2) {
            radius = 2;
        }

        var color = Palette.AMBER;
        if (phase == 1) {
            color = Palette.AMBER_DIM;
        } else if (phase == 2) {
            color = Palette.GREY;
        }

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(metrics.centerX, layout.dotCenterY, radius);
    }

    // Paused keeps the same shape as the run screen so the transition is a
    // change of state rather than a change of screen: the quote stays exactly
    // where it was, dimmed, and the dot is replaced by the word PAUSED. Still
    // no numbers - a pause is not a moment to sneak a split in.
    function drawPaused(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, controller as RunController) as Void {
        dc.setColor(Palette.GREY, Graphics.COLOR_TRANSPARENT);
        Hud.drawQuoteBlock(dc, metrics, layout, controller.currentQuote(),
            layout.quoteBandTop, layout.quoteBandBottom);

        var pausedY = layout.dotCenterY - metrics.px(16);
        dc.setColor(Palette.AMBER, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, pausedY, 1,
            WatchUi.loadResource(Rez.Strings.StatePaused) as String,
            layout.safeWidthForLine(metrics, pausedY, metrics.px(30)));

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
}
