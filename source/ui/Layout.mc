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

    // Start screen.
    var markCenterY as Number;
    var markWidth as Number;
    var wordmarkCenterY as Number;
    var taglineY as Number;
    var gpsStatusY as Number;
    var gpsDotsY as Number;

    // Run screen.
    var quoteBandTop as Number;
    var quoteBandBottom as Number;
    // The recording light and its label, as one centred row.
    var recordingY as Number;

    // Summary screen.
    var summaryMarkCenterY as Number;
    var summaryMarkWidth as Number;
    var titleY as Number;
    var heroTop as Number;
    var gridTop as Number;
    var gridBottom as Number;

    var hintY as Number;

    private var _inset as Number;

    function initialize(metrics as ScreenMetrics) {
        if (metrics.isRound) {
            _inset = metrics.px(20);

            gpsStatusY = metrics.px(38);
            gpsDotsY = metrics.px(76);
            markCenterY = metrics.px(134);
            markWidth = metrics.px(64);
            wordmarkCenterY = metrics.px(244);
            taglineY = metrics.px(322);

            quoteBandTop = metrics.px(96);
            quoteBandBottom = metrics.height - metrics.px(96);
            recordingY = metrics.height - metrics.px(76);

            summaryMarkCenterY = metrics.px(38);
            summaryMarkWidth = metrics.px(24);
            titleY = metrics.px(76);
            heroTop = metrics.px(108);
            gridTop = metrics.px(200);
            gridBottom = metrics.height - metrics.px(72);

            hintY = metrics.height - metrics.px(62);
        } else {
            _inset = metrics.px(14);

            gpsStatusY = metrics.px(24);
            gpsDotsY = metrics.px(80);
            markCenterY = metrics.px(152);
            markWidth = metrics.px(58);
            wordmarkCenterY = metrics.px(292);
            taglineY = metrics.px(388);

            quoteBandTop = metrics.px(56);
            quoteBandBottom = metrics.height - metrics.px(70);
            recordingY = metrics.height - metrics.px(52);

            summaryMarkCenterY = metrics.px(34);
            summaryMarkWidth = metrics.px(22);
            titleY = metrics.px(62);
            heroTop = metrics.px(90);
            gridTop = metrics.px(184);
            gridBottom = metrics.height - metrics.px(52);

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
