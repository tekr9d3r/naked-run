import Toybox.Lang;

// States, timings and the one number a user might reasonably want to change.
module RunConstants {

    // START -> [ACQUIRING] -> RUN <-> PAUSED -> SUMMARY -> START
    //
    // ACQUIRING is skipped entirely when the fix has already landed, which on
    // a normal outdoor start is most of the time.
    const STATE_START = 0;
    const STATE_ACQUIRING = 1;
    const STATE_RUN = 2;
    const STATE_PAUSED = 3;
    const STATE_SUMMARY = 4;

    // The controller's clock. One second is not needed for the quote - it is
    // needed for the recording dot, which is the only moving thing on the run
    // screen and the only reassurance the runner gets that the watch is still
    // working.
    const TICK_MS = 1000;

    // Seconds a quote stays on screen. Seven minutes sits in the middle of
    // the 5-10 minute band the design calls for: long enough that the line
    // stops being something you read and becomes something you are running
    // with, short enough that an hour's run sees a handful of them.
    //
    // This is a constant rather than a setting on purpose for v1 - see the
    // v1.1 notes in the README.
    const QUOTE_INTERVAL_SEC = 420;

    // The recording dot breathes over this many ticks.
    const DOT_CYCLE_SEC = 3;

    // Only quotes rotate while running; pausing freezes the line so coming
    // back from a stop at a crossing doesn't land you on a new one mid-thought.

    const END_SAVED = 0;
    const END_DISCARDED = 1;
}
