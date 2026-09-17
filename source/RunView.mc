import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// One persistent view that redraws differently per state, so there is no
// view stack to get out of sync with the recording underneath it. Geometry
// lives in ScreenMetrics/Layout and content in one module per screen, which
// is what lets round and rectangular devices share a single composition.
class RunView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        // True black every frame, on every screen. It is the ground the whole
        // design sits on and the cheapest pixel an AMOLED can draw - which
        // matters here more than usual, since this view is the one thing lit
        // for the entire length of a run.
        dc.setColor(Palette.BONE, Palette.BLACK);
        dc.clear();

        var controller = getApp().controller;
        var metrics = new ScreenMetrics(dc);
        var layout = new Layout(metrics);
        var state = controller.state;

        if (state == RunConstants.STATE_START) {
            StartScreen.draw(dc, metrics, layout, controller);
        } else if (state == RunConstants.STATE_ACQUIRING) {
            AcquiringScreen.draw(dc, metrics, layout, controller);
        } else if (state == RunConstants.STATE_RUN) {
            RunScreen.draw(dc, metrics, layout, controller);
        } else if (state == RunConstants.STATE_PAUSED) {
            RunScreen.drawPaused(dc, metrics, layout, controller);
        } else {
            SummaryScreen.draw(dc, metrics, layout, controller);
        }
    }
}
