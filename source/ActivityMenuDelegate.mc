import Toybox.Lang;
import Toybox.WatchUi;

// The in-run menu (MENU or BACK): Resume, End Run, Discard Run. Native Menu2
// and Confirmation on purpose - this is the utility surface, and a runner who
// wants to stop should meet the same widget every other Garmin app gives them
// rather than a bespoke one they have to learn mid-run.
class ActivityMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var controller = getApp().controller;

        if (id == :menu_resume) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            controller.resumeFromMenu();
        } else if (id == :menu_end_activity) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            controller.endRunAndSave();
        } else if (id == :menu_discard_activity) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.DiscardConfirmMessage) as String);
            WatchUi.pushView(dialog, new DiscardConfirmDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    // The system has no idea the run is paused behind this menu, so BACK has
    // to resume explicitly rather than relying on the default dismiss.
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        getApp().controller.resumeFromMenu();
    }
}

class DiscardConfirmDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        var controller = getApp().controller;
        if (response == WatchUi.CONFIRM_YES) {
            WatchUi.popView(WatchUi.SLIDE_DOWN); // confirmation
            WatchUi.popView(WatchUi.SLIDE_DOWN); // menu
            controller.endRunAndDiscard();
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN); // back to the menu
        }
        return true;
    }
}
