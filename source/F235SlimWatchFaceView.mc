using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;

class F235SlimWatchFaceView extends Ui.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {



        // clear background
        dc.setColor(Gfx.COLOR_TRANSPARENT, Gfx.COLOR_WHITE);
        dc.clear();
        //Sys.println("bg");

        me.drawLines(dc, Gfx.COLOR_BLACK);
        me.drawTime(dc, Gfx.FONT_NUMBER_HOT, Gfx.COLOR_BLACK);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }

    hidden function drawLines(dc, color) {
        var settings = Sys.getDeviceSettings();
        var noOfAreas = 3;

        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        for (var i = 1; i < noOfAreas; i ++) {
            dc.drawLine(
                0,
                i * settings.screenHeight / noOfAreas,
                settings.screenWidth,
                i * settings.screenHeight / noOfAreas
            );
        }
    }

    hidden function drawTime(dc, font, color) {
        var time = Sys.getClockTime();
        var settings = Sys.getDeviceSettings();

        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            settings.screenWidth / 2,
            settings.screenHeight / 2,
            font,
            time.hour.format("%02d") + ":" + time.min.format("%02d"),
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );

    }
}
