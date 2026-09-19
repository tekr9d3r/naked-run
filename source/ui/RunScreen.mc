import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// The screen this app was built to show, and the shortest file that draws
// one: a quote, and a recording light.
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

        drawRecordingIndicator(dc, metrics, layout, controller.dotPhase());
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // The entire user interface of a recording run: a blinking red light and
    // the words next to it.
    //
    // The light used to be an amber dot shading through three brightness
    // steps, which asked the runner to decode a colour. It could not say what
    // it was the status *of* - amber is the app's accent, so an amber dot is
    // just as easily decoration. A red light next to the letters REC needs no
    // decoding: the label says what is happening and the blink says it is
    // still happening now.
    //
    // It blinks on and off rather than fading. A recording light is a binary
    // thing, a MIP panel would band a fade anyway, and a hard step is what
    // proves the clock behind it is still running - a frozen app and a
    // motionless indicator look identical.
    //
    // Laid out as one centred row, light then label, the way every camera has
    // always done it.
    // "REC" is three characters, which is short enough to fit the chord on
    // every screen in the target list with room to spare - so there is no
    // fitting, no shortening and no fallback here. A longer label needed all
    // three; this one needs none of it, and the code says so.
    function drawRecordingIndicator(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, phase as Number) as Void {
        var radius = metrics.px(7);
        if (radius < 2) {
            radius = 2;
        }
        var gap = metrics.px(9);

        var font = metrics.fontFor(0);
        var text = WatchUi.loadResource(Rez.Strings.StateRecording) as String;
        var startX = metrics.centerX - (radius * 2 + gap + dc.getTextWidthInPixels(text, font)) / 2;

        dc.setColor((phase == 0) ? Palette.RECORD : Palette.RECORD_OFF,
            Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(startX + radius, layout.recordingY, radius);

        // The label holds still while only the light blinks - text that
        // flashed too would read as a fault rather than as a heartbeat.
        dc.setColor(Palette.GREY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + radius * 2 + gap, layout.recordingY, font, text,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Paused keeps the same shape as the run screen so the transition is a
    // change of state rather than a change of screen: the quote stays exactly
    // where it was, dimmed, and the recording row is replaced by the word
    // PAUSED. Still no numbers - a pause is not a moment to sneak a split in.
    //
    // The red light does not merely stop blinking, it goes away completely.
    // A light that has stopped moving is ambiguous - stopped, or hung? - and
    // this is the one distinction on this screen that has to be unmistakable.
    function drawPaused(dc as Graphics.Dc, metrics as ScreenMetrics, layout as Layout, controller as RunController) as Void {
        dc.setColor(Palette.GREY, Graphics.COLOR_TRANSPARENT);
        Hud.drawQuoteBlock(dc, metrics, layout, controller.currentQuote(),
            layout.quoteBandTop, layout.quoteBandBottom);

        var pausedY = layout.recordingY - metrics.px(14);
        dc.setColor(Palette.AMBER, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitCenteredText(dc, metrics, pausedY, 1,
            WatchUi.loadResource(Rez.Strings.StatePaused) as String,
            layout.safeWidthForLine(metrics, pausedY, metrics.px(30)));

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
}
