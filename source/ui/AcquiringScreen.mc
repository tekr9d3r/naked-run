import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// The GPS gate: what SELECT gets when there is no fix yet.
//
// It exists because this app hides the very numbers that would otherwise warn
// you. On a normal run app a missing fix announces itself - distance sits at
// zero and you notice within a minute. Here the screen looks identical either
// way, so a run started without GPS would look perfectly healthy right up
// until the summary showed nothing. The check has to happen before the run,
// because there is no during.
//
// No numbers here either - not the accuracy value, not a satellite count.
// Those would be the first data fields in the app, and they would be teaching
// the habit of looking at the watch that everything else here is trying to
// break. A sweep of dots says "working on it", which is all that is
// actionable: the only thing the runner can do is wait or walk into clearer
// sky.
module AcquiringScreen {

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, controller as RunController) as Void {
        var titleY = metrics.centerY - metrics.px(96);
        dc.setColor(Palette.AMBER, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, titleY, 2,
            WatchUi.loadResource(Rez.Strings.GpsTitle) as String,
            layout.safeWidthForLine(metrics, titleY, metrics.px(34)));

        // The same indicator as the start screen, just larger - the wait
        // carried over from there, so it should look like the same wait.
        Hud.drawSearchDots(dc, metrics, metrics.centerY - metrics.px(14),
            controller.searchTicks(), metrics.px(8), metrics.px(30));

        // Capped a tier below the heading so it stays supporting copy.
        var bodyTop = metrics.centerY + metrics.px(26);
        dc.setColor(Palette.GREY, Graphics.COLOR_TRANSPARENT);
        Hud.drawWrappedBlock(dc, metrics, layout,
            WatchUi.loadResource(Rez.Strings.GpsBody) as String,
            bodyTop, layout.hintY - metrics.px(8), 1);

        Hud.drawFitCenteredText(dc, metrics, layout.hintY, 0,
            WatchUi.loadResource(Rez.Strings.GpsHintCancel) as String,
            layout.safeWidthForLine(metrics, layout.hintY, metrics.px(24)));

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

}
