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
    hidden var colors;
    hidden var fonts;
    hidden var thresholds;
    //hidden var offsetX = 47; // experimental; semi-round watch, distance from left edge to the visible top left corner
    hidden var offsetD = 35; // experimental; semi-round watch, how many degrees are not available on the left and right screen edges

    hidden var notifications;
    hidden var connected;
    hidden var battery;
    hidden var steps;
    hidden var time;
    hidden var date;

    function initialize() {
        WatchFace.initialize();

        var settings = Sys.getDeviceSettings();
        me.screenWidth = settings.screenWidth;
        me.screenHeight = settings.screenHeight;

        me.noOfAreas = 5;

        me.colors = {
            "background"    => Gfx.COLOR_BLACK,
            "notifications" => Gfx.COLOR_RED,
            "connected"     => Gfx.COLOR_GREEN,
            "time"          => {"hour" => Gfx.COLOR_WHITE, "min" => Gfx.COLOR_LT_GRAY},
            "date"          => Gfx.COLOR_WHITE,
            "steps"         => [Gfx.COLOR_DK_GRAY, Gfx.COLOR_RED, Gfx.COLOR_ORANGE, Gfx.COLOR_BLUE, Gfx.COLOR_GREEN],
            "battery"       => [Gfx.COLOR_RED, Gfx.COLOR_BLUE, Gfx.COLOR_GREEN]
        };

        me.fonts = {
            "time"          => {"hour" => Gfx.FONT_SYSTEM_NUMBER_THAI_HOT, "min" => Gfx.FONT_SYSTEM_NUMBER_THAI_HOT},
            "date"          => Gfx.FONT_SMALL
        };

        me.thresholds = {
            "battery"       => [0, 10, 90]
        };
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

        // get the current data
        var stats = Sys.getSystemStats();
        var settings = Sys.getDeviceSettings();

        // init the current values
        me.battery = stats.battery;
        me.time = Sys.getClockTime();
        me.date = Greg.info(Time.now(), Time.FORMAT_MEDIUM);
        me.steps = Act.getInfo();
        me.connected = settings.phoneConnected ? 1 : 0;
        me.notifications = settings.notificationCount;

        // clear background
        dc.setColor(Gfx.COLOR_TRANSPARENT, me.colors["background"]);
        dc.clear();

        me.drawNotifications(dc, me.colors["notifications"]);
        me.drawConnected(dc, me.colors["connected"]);
        me.drawTime(dc, me.fonts["time"], me.colors["time"]);
        me.drawDate(dc, me.fonts["date"], me.colors["date"]);
        me.drawSteps(dc, me.colors["steps"]);
        me.drawBattery(dc, me.thresholds["battery"], me.colors["battery"]);
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

    hidden function drawNotifications(dc, color) {
        if (me.notifications <= 0) {
            return;
        }

        var offsetX = 50;

        dc.setPenWidth(2);
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(
            offsetX,
            1 * me.screenHeight / me.noOfAreas,
            me.screenWidth - offsetX,
            1 * me.screenHeight / me.noOfAreas
        );
    }

    hidden function drawConnected(dc, color) {
        if (me.connected <= 0) {
            return;
        }

        var offsetX = 50;

        dc.setPenWidth(2);
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.drawLine(
            offsetX,
            (me.noOfAreas - 1) * me.screenHeight / me.noOfAreas,
            me.screenWidth - offsetX,
            (me.noOfAreas - 1) * me.screenHeight / me.noOfAreas
        );
    }

    // draw the clock time (hh mm)
    hidden function drawTime(dc, fonts, colors) {

        dc.setColor(colors["hour"], Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            me.screenWidth / 2,
            me.screenHeight / 2,
            fonts["hour"],
            me.time.hour.format("%02d"),
            Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER
        );

        dc.setColor(colors["min"], Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            me.screenWidth / 2,
            me.screenHeight / 2,
            fonts["min"],
            time.min.format("%02d"),
            Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    hidden function drawDate(dc, font, color) {

        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            me.screenWidth / 2,
            (me.noOfAreas * 2 - 1) * me.screenHeight / (me.noOfAreas * 2),
            font,
            me.date.day_of_week + ", " + me.date.month + " " + me.date.day,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    hidden function drawSteps(dc, colors) {

        var steps = me.steps.steps;
        var goal = me.steps.stepGoal;

        if (steps == 0 || goal == 0) {
            return ;
        }

        var ratio = 100.0 * steps / goal;
        var level = (Math.floor(ratio * size / 100)).toLong();
        if (level > size - 1) {
            level = size - 1;
        }

        var startDegree = 270 + me.offsetD;
        startDegree = me.degree(startDegree);

        var degreeStep = Math.floor((180 - 2 * me.offsetD) / size);
        for (var i = 0; i <= level; i ++) {
            var endDegree = startDegree + degreeStep;
            endDegree = me.degree(endDegree);

            me.drawSideArc(dc, colors[i], dc.ARC_COUNTER_CLOCKWISE, startDegree, endDegree);
            startDegree = endDegree;
        }
    }

    hidden function drawBattery(dc, thresholds, colors) {

        var startDegree = 270 - me.offsetD;
        startDegree = me.degree(startDegree);

        var endDegree = startDegree - (me.battery / 100) * (startDegree - (90 + me.offsetD));
        endDegree = me.degree(endDegree);

        var color = colors[0];
        var size = thresholds.size();
        for (var i = 0; i < size; i ++) {

            if (me.battery < thresholds[i]) {
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
}
