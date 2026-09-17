import Toybox.Lang;
import Toybox.Test;
import Toybox.Position;

// Unit tests for the parts of the app that are pure logic - the summary
// formatters and the quote rotation. They are compiled in only by
// `monkeyc -t` and stripped from a release build, so this file costs the
// shipped app nothing.
//
//   ./build.sh                       normal build
//   ./test.sh                        build with -t and run in the simulator
//
// The drawing code is not tested here: it needs a live Dc for font metrics,
// which only the simulator can provide, so the screens are verified by eye
// across the device spread instead.
module Tests {

    (:test)
    function clockUnderAnHour(logger as Test.Logger) as Boolean {
        Test.assertEqual(Utils.formatClock(0), "0:00");
        Test.assertEqual(Utils.formatClock(9), "0:09");
        Test.assertEqual(Utils.formatClock(59), "0:59");
        Test.assertEqual(Utils.formatClock(60), "1:00");
        Test.assertEqual(Utils.formatClock(2718), "45:18");
        return true;
    }

    (:test)
    function clockOverAnHour(logger as Test.Logger) as Boolean {
        Test.assertEqual(Utils.formatClock(3600), "1:00:00");
        Test.assertEqual(Utils.formatClock(3661), "1:01:01");
        Test.assertEqual(Utils.formatClock(37230), "10:20:30");
        return true;
    }

    // A run that was started and stopped at the door must not report a pace
    // assembled out of GPS noise.
    (:test)
    function clockRejectsNegative(logger as Test.Logger) as Boolean {
        Test.assertEqual(Utils.formatClock(-5), "0:00");
        return true;
    }

    (:test)
    function paceRefusesNonsense(logger as Test.Logger) as Boolean {
        Test.assertEqual(Utils.formatPace(0.0, 600), "--:--");     // no distance
        Test.assertEqual(Utils.formatPace(19.0, 600), "--:--");    // under the floor
        Test.assertEqual(Utils.formatPace(5000.0, 0), "--:--");    // no time
        Test.assertEqual(Utils.formatPace(5000.0, -1), "--:--");
        return true;
    }

    // Both branches are checked against whichever unit system the device
    // under test is set to, so the test is valid on a metric and a statute
    // watch rather than only on the one it was written on.
    (:test)
    function paceIsPerUnitDistance(logger as Test.Logger) as Boolean {
        if (Utils.isStatutePace()) {
            // 1609.344 m in 480 s is exactly 8:00 per mile.
            Test.assertEqual(Utils.formatPace(1609.344, 480), "8:00/mi");
        } else {
            // 1000 m in 324 s is 5:24 per km.
            Test.assertEqual(Utils.formatPace(1000.0, 324), "5:24/km");
        }
        return true;
    }

    (:test)
    function distanceSwitchesUnitAtAKilometre(logger as Test.Logger) as Boolean {
        if (Utils.isStatuteDistance()) {
            Test.assertEqual(Utils.formatDistance(1609.344), "1.00 mi");
            Test.assertEqual(Utils.formatDistance(0.0), "0.00 mi");
        } else {
            Test.assertEqual(Utils.formatDistance(0.0), "0 m");
            Test.assertEqual(Utils.formatDistance(999.0), "999 m");
            Test.assertEqual(Utils.formatDistance(1000.0), "1.00 km");
            Test.assertEqual(Utils.formatDistance(5420.0), "5.42 km");
        }
        return true;
    }

    // A missing sensor reads as a dash, never as a zero - a zero is a claim
    // that the runner's heart rate was nothing.
    (:test)
    function missingStatsReadAsDashes(logger as Test.Logger) as Boolean {
        Test.assertEqual(Utils.formatOptionalNumber(null), "--");
        Test.assertEqual(Utils.formatOptionalNumber(0), "--");
        Test.assertEqual(Utils.formatOptionalNumber(148), "148");
        return true;
    }

    (:test)
    function quotesWrapInBothDirections(logger as Test.Logger) as Boolean {
        var n = Quotes.count();
        Test.assert(n > 0);
        Test.assertEqual(Quotes.at(0), Quotes.at(n));
        Test.assertEqual(Quotes.at(1), Quotes.at(n + 1));
        Test.assertEqual(Quotes.at(0), Quotes.at(2 * n));
        return true;
    }

    // Every quote has to be short enough to set large. This is the only
    // guard rail on the one piece of content the app exists to show.
    (:test)
    function quotesAreShort(logger as Test.Logger) as Boolean {
        for (var i = 0; i < Quotes.count(); i += 1) {
            var line = Quotes.at(i);
            Test.assert(line.length() > 0);
            Test.assert(line.length() <= 40);
        }
        return true;
    }

    (:test)
    function quoteStartIndexIsInRange(logger as Test.Logger) as Boolean {
        for (var i = 0; i < 50; i += 1) {
            var index = Quotes.randomStartIndex();
            Test.assert(index >= 0);
            Test.assert(index < Quotes.count());
        }
        return true;
    }

    // The GPS gate's threshold. A fix that is merely "last known" or "poor"
    // must not open it - that is precisely the run that comes back with a
    // time and no route.
    (:test)
    function gpsGateOpensOnlyAtUsable(logger as Test.Logger) as Boolean {
        Test.assert(!GpsQuality.isReady(Position.QUALITY_NOT_AVAILABLE));
        Test.assert(!GpsQuality.isReady(Position.QUALITY_LAST_KNOWN));
        Test.assert(!GpsQuality.isReady(Position.QUALITY_POOR));
        Test.assert(GpsQuality.isReady(Position.QUALITY_USABLE));
        Test.assert(GpsQuality.isReady(Position.QUALITY_GOOD));
        return true;
    }
}
