import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Formatting for the summary screen - the only screen in this app that is
// allowed to contain a digit.
//
// Everything here respects the watch's own unit settings rather than
// hardcoding metric, because a run app that reports kilometres to someone
// whose watch is set to miles has got the one screen it has wrong.
module Utils {

    const METERS_PER_MILE = 1609.344;

    function isStatuteDistance() as Boolean {
        return System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE;
    }

    function isStatutePace() as Boolean {
        return System.getDeviceSettings().paceUnits == System.UNIT_STATUTE;
    }

    // h:mm:ss past the hour, m:ss below it. The hero stat on the summary
    // screen, so it is also the widest string the layout has to fit.
    function formatClock(totalSeconds as Number) as String {
        var s = (totalSeconds < 0) ? 0 : totalSeconds;
        var h = s / 3600;
        var m = (s % 3600) / 60;
        var sec = s % 60;
        if (h > 0) {
            return h.format("%01d") + ":" + m.format("%02d") + ":" + sec.format("%02d");
        }
        return m.format("%01d") + ":" + sec.format("%02d");
    }

    // Whole metres under a kilometre, two decimals above it - a 5.42 km run
    // wants its hundreds of metres, a 640 m warm-down does not want to read
    // as "0.64 km".
    function formatDistance(meters as Float) as String {
        var m = (meters < 0.0) ? 0.0 : meters;
        if (isStatuteDistance()) {
            var miles = m / METERS_PER_MILE;
            if (miles < 0.1) {
                return "0.00 mi";
            }
            return miles.format("%.2f") + " mi";
        }
        if (m < 1000.0) {
            return m.format("%.0f") + " m";
        }
        return (m / 1000.0).format("%.2f") + " km";
    }

    // Average pace derived from the run's own distance and timer time rather
    // than read from Activity.Info.averageSpeed, so it matches the "Avg Pace"
    // Garmin Connect will show for the same activity.
    //
    // Under 20 m of distance there is no meaningful pace - a run that was
    // started and stopped at the door should say so rather than print a
    // number built from GPS noise.
    function formatPace(meters as Float, seconds as Number) as String {
        if (meters < 20.0 || seconds <= 0) {
            return "--:--";
        }
        var perUnit = isStatutePace() ? METERS_PER_MILE : 1000.0;
        var units = meters / perUnit;
        if (units <= 0.0) {
            return "--:--";
        }
        var secPerUnit = (seconds / units).toNumber();
        if (secPerUnit > 3599) {
            return "--:--";
        }
        return (secPerUnit / 60).format("%01d") + ":" + (secPerUnit % 60).format("%02d")
            + (WatchUi.loadResource(isStatutePace()
                ? Rez.Strings.UnitPerMi
                : Rez.Strings.UnitPerKm) as String);
    }

    // Optional Activity.Info numbers arrive as null on a device that has no
    // such sensor, on a run where the strap never paired, or simply on a run
    // too short to have produced one.
    function formatOptionalNumber(value as Number?) as String {
        if (value == null || value <= 0) {
            return "--";
        }
        return value.format("%d");
    }
}
