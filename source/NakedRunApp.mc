import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class NakedRunApp extends Application.AppBase {

    var controller as RunController;

    function initialize() {
        AppBase.initialize();
        controller = new RunController();
    }

    function onStart(state as Dictionary?) as Void {
    }

    // Last chance to keep a run that the system is about to end for us, and
    // to switch the GPS receiver off behind us.
    function onStop(state as Dictionary?) as Void {
        controller.onAppStop();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new RunView(), new RunDelegate() ];
    }
}

function getApp() as NakedRunApp {
    return Application.getApp() as NakedRunApp;
}
