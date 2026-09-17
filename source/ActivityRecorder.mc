import Toybox.ActivityRecording;
import Toybox.Activity;
import Toybox.Lang;

// The FIT recording, and nothing else.
//
// This is deliberately the most boring file in the project. Naked Run's whole
// claim is that the run it records is an ordinary run - same GPS track, same
// pace and HR and cadence streams, same place in Garmin Connect as one
// started from the watch's own Run app. That is achieved by doing exactly
// what the stock app does and adding nothing: a plain SPORT_RUNNING session,
// started and stopped, with no custom FIT fields and no post-processing.
//
// Session.stop() is the pause: it suspends recording without ending the
// activity, and start() resumes it. Only save() finalises the FIT file.
class ActivityRecorder {

    private var _session as ActivityRecording.Session?;

    function start() as Void {
        if (_session != null) {
            return;
        }
        _session = ActivityRecording.createSession({
            :name => "Naked Run",
            :sport => Activity.SPORT_RUNNING,
            :subSport => Activity.SUB_SPORT_GENERIC
        });
        (_session as ActivityRecording.Session).start();
    }

    function pause() as Void {
        var session = _session;
        if (session != null && session.isRecording()) {
            session.stop();
        }
    }

    function resume() as Void {
        var session = _session;
        if (session != null && !session.isRecording()) {
            session.start();
        }
    }

    // Ends the activity and writes it to the watch's activity list, where the
    // next sync picks it up like any other run.
    function save() as Void {
        var session = _session;
        if (session == null) {
            return;
        }
        if (session.isRecording()) {
            session.stop();
        }
        session.save();
        _session = null;
    }

    // Throws the recording away. Only ever reached through the confirmation
    // dialog behind "Discard Run".
    function discard() as Void {
        var session = _session;
        if (session == null) {
            return;
        }
        if (session.isRecording()) {
            session.stop();
        }
        session.discard();
        _session = null;
    }

    function hasSession() as Boolean {
        return _session != null;
    }

    function isRecording() as Boolean {
        var session = _session;
        return session != null && session.isRecording();
    }
}
