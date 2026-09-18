import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// The state machine, the clock, and the two side effects (recording, quote
// rotation) that the screens are not allowed to touch.
//
//   START -> [ACQUIRING] -> RUN <-> PAUSED -> SUMMARY -> START
//
// It holds exactly one number the UI may read while running - the tick count -
// and that number drives the quote rotation and the blink of the recording
// dot, never a readout. Elapsed time, distance, pace and heart rate are not
// even fetched until the run is over.
class RunController {

    var state as Number;

    private var _timer as Timer.Timer?;
    private var _recorder as ActivityRecorder;
    private var _gps as GpsStatus;

    // Seconds of *running* time, paused stretches excluded. Used only for
    // quote timing and the dot's blink.
    private var _ticks as Number;
    private var _quoteIndex as Number;

    // Counts seconds spent waiting for a fix, on the start screen and on the
    // gate alike. It drives the searching indicator in both places and never
    // leaks into the run's own clock or its quote rotation.
    private var _searchTicks as Number;

    private var _summary as RunSummary?;
    private var _endReason as Number;

    function initialize() {
        state = RunConstants.STATE_START;
        _recorder = new ActivityRecorder();
        // Built here rather than at the start of a run: the receiver switches
        // on with the app, so it is acquiring while the start screen is being
        // read.
        _gps = new GpsStatus();
        _ticks = 0;
        _quoteIndex = 0;
        _searchTicks = 0;
        _summary = null;
        _endReason = RunConstants.END_SAVED;
    }

    // --- transitions -----------------------------------------------------

    // What SELECT on the start screen asks for. It is a request rather than a
    // command, because a run that starts without a fix is a run with no route,
    // no distance and no pace - and on this app, which shows nothing while you
    // run, you would not find that out until you had already finished.
    //
    // So: fix present, go. Fix absent, hold on the gate and start the moment
    // it lands. The intent has already been given, so the runner should not
    // have to press again while standing in the cold watching dots.
    function requestStart() as Void {
        if (state != RunConstants.STATE_START) {
            return;
        }
        if (_gps.isReady()) {
            beginRecording();
            return;
        }
        // _searchTicks deliberately keeps counting rather than resetting: the
        // dots were already sweeping on the start screen and this is the same
        // wait continuing, so restarting the animation here would read as a
        // stutter at the exact moment the user is watching it.
        state = RunConstants.STATE_ACQUIRING;
        startClock();
        WatchUi.requestUpdate();
    }

    function cancelAcquiring() as Void {
        if (state != RunConstants.STATE_ACQUIRING) {
            return;
        }
        state = RunConstants.STATE_START;
        syncSearchClock();
        WatchUi.requestUpdate();
    }

    private function beginRecording() as Void {
        _ticks = 0;
        _quoteIndex = Quotes.randomStartIndex();
        _summary = null;
        _recorder.start();
        state = RunConstants.STATE_RUN;
        startClock();
        WatchUi.requestUpdate();
    }

    function togglePause() as Void {
        if (state == RunConstants.STATE_RUN) {
            stopClock();
            _recorder.pause();
            state = RunConstants.STATE_PAUSED;
        } else if (state == RunConstants.STATE_PAUSED) {
            _recorder.resume();
            state = RunConstants.STATE_RUN;
            startClock();
        } else {
            return;
        }
        WatchUi.requestUpdate();
    }

    // Used by the in-activity menu, which pauses on the way in so the run is
    // never still counting behind a menu the runner is reading.
    function ensurePausedForMenu() as Void {
        if (state == RunConstants.STATE_RUN) {
            togglePause();
        }
    }

    function resumeFromMenu() as Void {
        if (state == RunConstants.STATE_PAUSED) {
            togglePause();
        }
    }

    function endRunAndSave() as Void {
        finish(RunConstants.END_SAVED);
    }

    function endRunAndDiscard() as Void {
        finish(RunConstants.END_DISCARDED);
    }

    // The snapshot has to be taken before the session is saved or discarded -
    // afterwards Activity.getActivityInfo() has nothing left to say about the
    // run that just ended. See RunSummary.
    private function finish(reason as Number) as Void {
        if (state != RunConstants.STATE_RUN && state != RunConstants.STATE_PAUSED) {
            return;
        }
        stopClock();
        _endReason = reason;
        _summary = new RunSummary();

        if (reason == RunConstants.END_DISCARDED) {
            _recorder.discard();
        } else {
            _recorder.save();
        }

        state = RunConstants.STATE_SUMMARY;
        WatchUi.requestUpdate();
    }

    function returnToStart() as Void {
        state = RunConstants.STATE_START;
        syncSearchClock();
        WatchUi.requestUpdate();
    }

    // Called when the root view appears, which is the first moment a timer has
    // a view to redraw.
    function onViewShown() as Void {
        syncSearchClock();
    }

    // The start screen would otherwise have no clock at all, leaving the
    // searching dots frozen mid-sweep - which looks exactly like the hung app
    // the indicator exists to rule out. So the tick runs while a fix is
    // missing and stops the moment one lands: there is nothing left to animate
    // then, and a 1 Hz wakeup on an idle screen is not free.
    private function syncSearchClock() as Void {
        if (state != RunConstants.STATE_START) {
            return;
        }
        if (_gps.isReady()) {
            stopClock();
        } else {
            startClock();
        }
    }

    // If the watch tears the app down mid-run - low battery, a long press out,
    // the system reclaiming memory - the run is worth more than the app's
    // opinion about how it should have ended, so it is saved rather than lost.
    // The receiver is then shut down explicitly rather than left running.
    function onAppStop() as Void {
        stopClock();
        if (_recorder.hasSession()) {
            _recorder.save();
        }
        _gps.disable();
    }

    // --- clock -----------------------------------------------------------

    private function startClock() as Void {
        if (_timer != null) {
            return;
        }
        _timer = new Timer.Timer();
        (_timer as Timer.Timer).start(method(:onTick), RunConstants.TICK_MS, true);
    }

    private function stopClock() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        // On the start screen the clock only animates the searching dots, and
        // retires itself as soon as the fix it is waiting on arrives.
        if (state == RunConstants.STATE_START) {
            if (_gps.isReady()) {
                stopClock();
            } else {
                _searchTicks += 1;
            }
            WatchUi.requestUpdate();
            return;
        }

        // On the gate the clock's only job is to animate the search and to
        // notice the instant a fix arrives, at which point the run the runner
        // already asked for begins by itself.
        if (state == RunConstants.STATE_ACQUIRING) {
            _searchTicks += 1;
            if (_gps.isReady()) {
                beginRecording();
            } else {
                WatchUi.requestUpdate();
            }
            return;
        }

        _ticks += 1;
        if (_ticks % RunConstants.QUOTE_INTERVAL_SEC == 0) {
            _quoteIndex += 1;
        }
        WatchUi.requestUpdate();
    }

    // --- what the screens may read ---------------------------------------

    function currentQuote() as String {
        return Quotes.at(_quoteIndex);
    }

    // 0 .. DOT_CYCLE_SEC-1. The recording dot's position in its blink, and
    // the only use the run screen has for the clock.
    function dotPhase() as Number {
        return _ticks % RunConstants.DOT_CYCLE_SEC;
    }

    function isGpsReady() as Boolean {
        return _gps.isReady();
    }

    // Drives the searching indicator on the start screen and the gate.
    function searchTicks() as Number {
        return _searchTicks;
    }

    function summary() as RunSummary? {
        return _summary;
    }

    function endReason() as Number {
        return _endReason;
    }
}
