import Toybox.Position;
import Toybox.WatchUi;
import Toybox.Lang;

// Live GPS fix quality.
//
// The receiver is switched on in the constructor - which runs when the app
// opens, not when the run starts - so it spends the whole time the runner is
// looking at the start screen acquiring. By the time anyone has read the
// wordmark and reached for the button, a fix is usually already there and the
// gate never appears.
//
// Enabling location events is also what puts GPS into the recording itself.
// Leaving it to ActivityRecording alone is the reason an activity can come
// back with time but no track.
class GpsStatus {

    private var _accuracy as Number;

    function initialize() {
        _accuracy = Position.QUALITY_NOT_AVAILABLE;
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    function onPosition(info as Position.Info) as Void {
        _accuracy = info.accuracy;
        WatchUi.requestUpdate();
    }

    function accuracy() as Number {
        return _accuracy;
    }

    function isReady() as Boolean {
        return GpsQuality.isReady(_accuracy);
    }

    function disable() as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        _accuracy = Position.QUALITY_NOT_AVAILABLE;
    }
}

// The readiness threshold, split out from the class so it can be tested
// without a live receiver.
module GpsQuality {

    // QUALITY_USABLE rather than QUALITY_GOOD. Usable is the point at which
    // Garmin considers a fix adequate to record an activity, and insisting on
    // GOOD would leave someone standing at the trailhead under tree cover
    // waiting for a bar that may never arrive on a day the sky is poor.
    function isReady(accuracy as Number) as Boolean {
        return accuracy >= Position.QUALITY_USABLE;
    }
}
