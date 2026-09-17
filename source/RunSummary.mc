import Toybox.Activity;
import Toybox.Lang;

// A frozen copy of the run's numbers, taken in the instant before the session
// is saved.
//
// This snapshot is not an optimisation, it is a requirement: once
// Session.save() has run, Activity.getActivityInfo() no longer reports on the
// activity that just ended, and the summary screen - the only screen in this
// app that shows any numbers at all - would have nothing to show. So the
// controller builds one of these first and saves second.
//
// Every field is optional in practice. A run that never got a GPS fix has no
// distance, and a watch with no wrist HR and no paired strap has neither
// average nor maximum heart rate. The formatters upstream turn each absence
// into "--" rather than a zero, because a dash is honest and a zero is a
// claim.
class RunSummary {

    var seconds as Number;          // timer time - what Garmin calls "Time"
    var meters as Float;
    var averageHeartRate as Number?;
    var maxHeartRate as Number?;

    function initialize() {
        seconds = 0;
        meters = 0.0;
        averageHeartRate = null;
        maxHeartRate = null;
        capture();
    }

    // Activity.getActivityInfo() itself is non-null - it is the individual
    // fields on it that go missing, so each one is checked rather than the
    // container.
    private function capture() as Void {
        var info = Activity.getActivityInfo();

        // timerTime excludes the stretches spent paused, which is what a
        // runner means by the time of their run; elapsedTime is the fallback
        // only because timerTime is documented optional.
        var millis = info.timerTime;
        if (millis == null) {
            millis = info.elapsedTime;
        }
        if (millis != null) {
            seconds = (millis / 1000).toNumber();
        }

        var distance = info.elapsedDistance;
        if (distance != null) {
            meters = distance;
        }

        averageHeartRate = info.averageHeartRate;
        maxHeartRate = info.maxHeartRate;
    }
}
