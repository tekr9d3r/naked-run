import Toybox.Lang;
import Toybox.Math;

// Named anchors for the three screens, plus the one piece of geometry this
// design genuinely needs: the circular safe area.
//
// A round watch is not a rectangle with rounded corners - it is a circle, and
// a line of text 80% of the screen's width will hang out of it near the top
// and bottom while looking perfectly safe at the middle. Since the largest
// thing in this app is a centred quote that may wrap to three lines and
// therefore reaches well above and below the centre, the layout solves the
// chord width properly instead of guessing an inset.
class Layout {

    // Start screen. Only the two fixed points and the mark's width: the
    // stack between them is measured and centred at draw time, because what
    // fits underneath the wordmark differs per device and px() cannot say so.
    var gpsStatusY as Number;
    var markWidth as Number;
    var contentBottom as Number;

    // Run screen.
    var quoteBandTop as Number;
    var quoteBandBottom as Number;
    // The recording light and its label, as one centred row.
    var recordingY as Number;

    // Summary screen.
    var summaryMarkCenterY as Number;
    var summaryMarkWidth as Number;
    var titleY as Number;
    // Where the title goes when the footprint mark has been dropped for want
    // of room; see SummaryScreen.
    var titleYNoMark as Number;
    // Only the bottom edge: the grid measures its own height and grows
    // upward from here, so a fixed top would fight the font metrics.
    var gridBottom as Number;

    var hintY as Number;

    private var _inset as Number;

    function initialize(metrics as ScreenMetrics) {
        if (metrics.isRound) {
            _inset = metrics.px(20);

            gpsStatusY = metrics.px(38);
            contentBottom = metrics.height - metrics.px(24);
            markWidth = metrics.px(64);

            quoteBandTop = metrics.px(96);
            quoteBandBottom = metrics.height - metrics.px(96);
            recordingY = metrics.height - metrics.px(76);

            summaryMarkCenterY = metrics.px(38);
            summaryMarkWidth = metrics.px(24);
            titleY = metrics.px(76);
            titleYNoMark = metrics.px(20);
            gridBottom = metrics.height - metrics.px(40);

            hintY = metrics.height - metrics.px(62);
        } else {
            _inset = metrics.px(14);

            gpsStatusY = metrics.px(24);
            contentBottom = metrics.height - metrics.px(18);
            markWidth = metrics.px(58);

            quoteBandTop = metrics.px(56);
            quoteBandBottom = metrics.height - metrics.px(70);
            recordingY = metrics.height - metrics.px(52);

            summaryMarkCenterY = metrics.px(34);
            summaryMarkWidth = metrics.px(22);
            titleY = metrics.px(62);
            titleYNoMark = metrics.px(16);
            gridBottom = metrics.height - metrics.px(30);

            hintY = metrics.height - metrics.px(40);
        }
    }

    // Half the width available to content whose vertical extent runs from
    // topY to bottomY, measured from the screen's centre line.
    //
    // On a round screen this is the half-chord of the safe circle at
    // whichever of the two edges is further from the centre - the worst case
    // for the block as a whole, so a three-line quote is sized by its top and
    // bottom lines rather than by its comfortable middle one.
    function safeHalfWidth(metrics as ScreenMetrics, topY as Number, bottomY as Number) as Number {
        if (!metrics.isRound) {
            var half = metrics.width / 2 - _inset;
            return (half < 8) ? 8 : half;
        }

        var radius = metrics.minDim / 2 - _inset;
        var dTop = (topY - metrics.centerY).abs();
        var dBottom = (bottomY - metrics.centerY).abs();
        var d = (dTop > dBottom) ? dTop : dBottom;

        if (d >= radius) {
            return 8;
        }
        var chord = Math.sqrt((radius * radius - d * d).toFloat()).toNumber();
        return (chord < 8) ? 8 : chord;
    }

    // Convenience for a single line of known height.
    function safeWidthForLine(metrics as ScreenMetrics, topY as Number, lineHeight as Number) as Number {
        return 2 * safeHalfWidth(metrics, topY, topY + lineHeight);
    }

}
