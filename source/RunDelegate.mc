import Toybox.Lang;
import Toybox.WatchUi;

class RunDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // SELECT does the obvious thing for whatever is on screen: start, pause,
    // resume, done. One key drives the entire app, because the point of the
    // run screen is that there is nothing on it to interact with.
    function onSelect() as Boolean {
        var controller = getApp().controller;
        var s = controller.state;

        if (s == RunConstants.STATE_START) {
            controller.requestStart();
        } else if (s == RunConstants.STATE_ACQUIRING) {
            // Deliberately inert. The request has already been made and the
            // run starts itself the moment a fix lands, so there is nothing
            // pressing again can do - and there is no override, because
            // starting anyway is exactly the outcome the gate exists to
            // prevent.
            return true;
        } else if (s == RunConstants.STATE_RUN || s == RunConstants.STATE_PAUSED) {
            controller.togglePause();
        } else {
            controller.returnToStart();
        }
        return true;
    }

    function onMenu() as Boolean {
        return openActivityMenu();
    }

    // BACK on a root view quits the app by default, which mid-run would
    // abandon a recording with one press. While a run exists it is routed to
    // the same menu as MENU, so ending is always a deliberate choice between
    // keeping the run and throwing it away.
    function onBack() as Boolean {
        var controller = getApp().controller;
        var s = controller.state;

        if (s == RunConstants.STATE_SUMMARY) {
            controller.returnToStart();
            return true;
        }
        if (s == RunConstants.STATE_ACQUIRING) {
            controller.cancelAcquiring();
            return true;
        }
        if (s == RunConstants.STATE_START) {
            return false; // fall through to the default quit
        }
        return openActivityMenu();
    }

    private function openActivityMenu() as Boolean {
        var controller = getApp().controller;
        var s = controller.state;

        if (s != RunConstants.STATE_RUN && s != RunConstants.STATE_PAUSED) {
            return false;
        }

        controller.ensurePausedForMenu();
        WatchUi.pushView(new Rez.Menus.ActivityMenu(), new ActivityMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
}
