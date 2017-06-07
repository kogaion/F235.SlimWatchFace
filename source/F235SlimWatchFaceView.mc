using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time.Gregorian as Greg;
using Toybox.ActivityMonitor as Act;
using Toybox.Math as Math;

class F235SlimWatchFaceView extends Ui.WatchFace {

    hidden var screenWidth;
    hidden var screenHeight;

    hidden var noOfAreas;
    hidden var offsetX = 47; // experimental; semi-round watch, distance from left edge to the visible top left corner
    hidden var offsetDegrees = {"top" => 35, "bottom" => 35}; // experimental; semi-round watch, how many degrees are not available on the left and right screen edges

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
        var settings = Sys.getDeviceSettings();
        me.screenWidth = settings.screenWidth;
        me.screenHeight = settings.screenHeight;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {

        me.noOfAreas = 5;

        // clear background
        dc.setColor(Gfx.COLOR_TRANSPARENT, Gfx.COLOR_BLACK);
        dc.clear();

        var linesStatus = me.getLinesStatus();
        me.drawLines(dc, [linesStatus[0] > 0 ? Gfx.COLOR_RED : Gfx.COLOR_TRANSPARENT, linesStatus[1] > 0 ? Gfx.COLOR_GREEN : Gfx.COLOR_TRANSPARENT]);

        me.drawTime(dc, [Gfx.FONT_SYSTEM_NUMBER_THAI_HOT, Gfx.FONT_SYSTEM_NUMBER_THAI_HOT], [Gfx.COLOR_WHITE, Gfx.COLOR_LT_GRAY]);
        me.drawDate(dc, Gfx.FONT_SMALL, Gfx.COLOR_WHITE);

        me.drawSteps(dc, [Gfx.COLOR_DK_GRAY, Gfx.COLOR_RED, Gfx.COLOR_ORANGE, Gfx.COLOR_BLUE, Gfx.COLOR_GREEN]);
        me.drawBattery(dc, [0, 10, 90], [Gfx.COLOR_RED, Gfx.COLOR_BLUE, Gfx.COLOR_GREEN]);
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

    // draw the first and the last horizontal lines
    hidden function drawLines(dc, colors) {

        dc.setPenWidth(2);

        var offsetX = 50;

        // first line
        dc.setColor(colors[0], Gfx.COLOR_TRANSPARENT);
        dc.drawLine(
            offsetX,
            1 * me.screenHeight / me.noOfAreas,
            me.screenWidth - offsetX,
            1 * me.screenHeight / me.noOfAreas
        );

        // last line
        dc.setColor(colors[1], Gfx.COLOR_TRANSPARENT);
        dc.drawLine(
            offsetX,
            (me.noOfAreas - 1) * me.screenHeight / me.noOfAreas,
            me.screenWidth - offsetX,
            (me.noOfAreas - 1) * me.screenHeight / me.noOfAreas
        );
    }

    // draw the clock time (hh:mm) in the middle of the screen
    hidden function drawTime(dc, fonts, colors) {
        var time = Sys.getClockTime();

        dc.setColor(colors[0], Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            me.screenWidth / 2,
            me.screenHeight / 2,
            fonts[0],
            time.hour.format("%02d"),
            Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER
        );

        dc.setColor(colors[1], Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            me.screenWidth / 2,
            me.screenHeight / 2,
            fonts[1],
            time.min.format("%02d"),
            Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    hidden function drawDate(dc, font, color) {
        var date = Greg.info(Time.now(), Time.FORMAT_MEDIUM);

        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            me.screenWidth / 2,
            (me.noOfAreas * 2 - 1) * me.screenHeight / (me.noOfAreas * 2),
            font,
            date.day_of_week + ", " + date.month + " " + date.day,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    hidden function drawSteps(dc, colors) {
        var size = colors.size();
        var info = Act.getInfo();
        var goal = info.stepGoal;
        var steps = info.steps;

        if (steps == 0 || goal == 0) {
            return ;
        }

        var ratio = 100.0 * steps / goal;
        var level = (Math.floor(ratio * size / 100)).toLong();
        if (level > size - 1) {
            level = size - 1;
        }

        var startDegree = 270 + me.offsetDegrees["bottom"];
        startDegree = me.degree(startDegree);

        var degreeStep = Math.floor((180 - me.offsetDegrees["top"] - me.offsetDegrees["bottom"]) / size);
        for (var i = 0; i <= level; i ++) {
            var endDegree = startDegree + degreeStep;
            endDegree = me.degree(endDegree);

            me.drawSideArc(dc, colors[i], dc.ARC_COUNTER_CLOCKWISE, startDegree, endDegree);
            startDegree = endDegree;
        }
    }

    hidden function drawBattery(dc, thresholds, colors) {
        var stats = Sys.getSystemStats();
        var battery = stats.battery;

        var startDegree = 270 - me.offsetDegrees["bottom"];
        startDegree = me.degree(startDegree);

        var endDegree = startDegree - (battery / 100) * (startDegree - (90 + me.offsetDegrees["top"]));
        endDegree = me.degree(endDegree);

        var color = colors[0];
        var size = thresholds.size();
        for (var i = 0; i < size; i ++) {

            if (battery < thresholds[i]) {
                break;
            }
            color = colors[i];
        }

        me.drawSideArc(dc, color, dc.ARC_CLOCKWISE, startDegree, endDegree);
    }

    hidden function degree(d) {
        if (d >= 360) {
            d = d - 360;
        }
        if (d < 0) {
            d = d + 360;
        }
        return d;
    }

    hidden function drawSideArc(dc, color, direction, startDegree, endDegree) {
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(8);
        dc.drawArc(
            me.screenWidth / 2,
            me.screenHeight / 2,
            me.screenWidth / 2 - 2,
            direction,
            startDegree,
            endDegree
        );
    }

    hidden function getLinesStatus() {
        var settings = Sys.getDeviceSettings();
        return [settings.notificationCount > 0 ? 1 : 0, settings.phoneConnected ? 1 : 0];
    }
}
