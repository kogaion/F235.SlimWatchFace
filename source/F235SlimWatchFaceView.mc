using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time.Gregorian as Greg;
using Toybox.ActivityMonitor as Act;
using Toybox.Math as Math;
using Toybox.Application as App;

class F235SlimWatchFaceView extends Ui.WatchFace {

    hidden var screenWidth;
    hidden var screenHeight;
    hidden var noOfAreas;
    hidden var bgColor;

    //hidden var offsetX = 47; // experimental; semi-round watch, distance from left edge to the visible top left corner
    hidden var offsetD = 35; // experimental; semi-round watch, how many degrees are not available on the left and right screen edges

    function initialize() {
        WatchFace.initialize();

        var settings = Sys.getDeviceSettings();
        me.screenWidth = settings.screenWidth;
        me.screenHeight = settings.screenHeight;

        me.noOfAreas = 5;
        me.bgColor = App.getApp().getProperty("BackgroundColor");
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
        dc.setColor(Gfx.COLOR_TRANSPARENT, bgColor);
        dc.clear();

        me.drawNotifications(dc);
        me.drawConnected(dc);
        me.drawTime(dc);
        me.drawDate(dc);
        me.drawSteps(dc);
        me.drawBattery(dc);
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

    hidden function drawNotifications(dc) {

        var settings = Sys.getDeviceSettings();
        var notifications = settings.notificationCount;
        if (notifications <= 0) {
            return;
        }

        var offsetX = 50;

        dc.setPenWidth(2);
        dc.setColor(App.getApp().getProperty("NotificationsColor"), Gfx.COLOR_TRANSPARENT);
        dc.drawLine(
            offsetX,
            1 * me.screenHeight / me.noOfAreas,
            me.screenWidth - offsetX,
            1 * me.screenHeight / me.noOfAreas
        );
    }

    hidden function drawConnected(dc) {

        var settings = Sys.getDeviceSettings();
        var connected = settings.phoneConnected ? 1 : 0;
        if (connected <= 0) {
            return;
        }

        var offsetX = 50;

        dc.setPenWidth(2);
        dc.setColor(App.getApp().getProperty("ConnectedColor"), Gfx.COLOR_TRANSPARENT);
        dc.drawLine(
            offsetX,
            (me.noOfAreas - 1) * me.screenHeight / me.noOfAreas,
            me.screenWidth - offsetX,
            (me.noOfAreas - 1) * me.screenHeight / me.noOfAreas
        );
    }

    hidden function drawTime(dc) {

        var time = Sys.getClockTime();

        dc.setColor(App.getApp().getProperty("HoursColor"), Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            me.screenWidth / 2,
            me.screenHeight / 2,
            Gfx.FONT_SYSTEM_NUMBER_THAI_HOT,
            time.hour.format("%02d"),
            Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER
        );

        dc.setColor(App.getApp().getProperty("MinutesColor"), Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            me.screenWidth / 2,
            me.screenHeight / 2,
            Gfx.FONT_SYSTEM_NUMBER_THAI_HOT,
            time.min.format("%02d"),
            Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    hidden function drawDate(dc) {

        var date = Greg.info(Time.now(), Time.FORMAT_MEDIUM);

        dc.setColor(App.getApp().getProperty("DateColor"), Gfx.COLOR_TRANSPARENT);
        dc.drawText(
            me.screenWidth / 2,
            (me.noOfAreas * 2 - 1) * me.screenHeight / (me.noOfAreas * 2),
            Gfx.FONT_SMALL,
            date.day_of_week + ", " + date.month + " " + date.day,
            Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER
        );
    }

    hidden function drawSteps(dc) {

        var info = Act.getInfo();
        var steps = info.steps;
        var goal = info.stepGoal;

        if (steps > goal) {
            steps = goal;
        }

        var ratio = (steps == 0 || goal == 0) ? 0 : (100 * steps / goal);

        var colors = [App.getApp().getProperty("Steps1Color"), App.getApp().getProperty("Steps2Color"), App.getApp().getProperty("Steps3Color"), App.getApp().getProperty("Steps4Color"), App.getApp().getProperty("Steps5Color")];
        var thresholds = [0, 20, 40, 60, 80];

        var startDegree = 270 + me.offsetD;
        startDegree = me.degree(startDegree);

        var endDegree = 90 - me.offsetD;
        endDegree = me.degree(endDegree);

        var levelDegree = startDegree + ratio * (180 - 2 * me.offsetD) / 100;
        levelDegree = me.degree(levelDegree);

        me.drawArcLevel(dc, ratio, thresholds, colors, dc.ARC_COUNTER_CLOCKWISE, startDegree, endDegree, levelDegree, true);
    }

    hidden function drawBattery(dc) {

        var stats = Sys.getSystemStats();
        var battery = stats.battery;

        var thresholds = [0, 10];
        var colors = [App.getApp().getProperty("BatteryWarningColor"), App.getApp().getProperty("BatteryColor")];

        var startDegree = 270 - me.offsetD;
        startDegree = me.degree(startDegree);

        var endDegree = 90 + me.offsetD;
        endDegree = me.degree(endDegree);

        var levelDegree = startDegree - (battery / 100) * (startDegree - endDegree);
        levelDegree = me.degree(levelDegree);

        me.drawArcLevel(dc, battery, thresholds, colors, dc.ARC_CLOCKWISE, startDegree, endDegree, levelDegree, true);
    }

    hidden function drawArcLevel(dc, level, thresholds, colors, direction, startDegree, endDegree, levelDegree, drawAllColors) {

        var color = colors[0];
        var size = thresholds.size();

        var sign = (direction == dc.ARC_CLOCKWISE ? -1 : 1);

        // background arc
        me.drawSideArc(dc, App.getApp().getProperty("ArcBorderColor"), direction, startDegree, endDegree, me.screenWidth / 2 - 4, 8);
        me.drawSideArc(dc, bgColor, direction, startDegree + 1 * sign, endDegree - 1 * sign, me.screenWidth / 2 - 4, 6);

        if (startDegree == levelDegree) {
            return;
        }

        var radius = me.screenWidth / 2 - 4;
        var penWidth = 8;

        // get the color of the level and draw the level arc
        for (var i = 0; i < size; i ++) {
            if (level < thresholds[i]) {
                break;
            }
            color = colors[i];
        }
        me.drawSideArc(dc, color, direction, startDegree, levelDegree, radius, penWidth);

        // draw all colors?
        if (drawAllColors) {

            var degreeStep;
            var stepStartDegree = startDegree;
            stepStartDegree = me.degree(stepStartDegree);
            var stepEndDegree;

            for (var i = 0; i < size - 1; i ++) {

                if (level < thresholds[i + 1]) {
                    break;
                }

                degreeStep = sign * Math.floor(((180 - 2 * me.offsetD) * (thresholds[i + 1] - thresholds[i])) / 100);

                stepEndDegree = stepStartDegree + degreeStep;
                stepEndDegree = me.degree(stepEndDegree);

                me.drawSideArc(dc, colors[i], direction, stepStartDegree, stepEndDegree, radius, penWidth);

                stepStartDegree = stepEndDegree;
            }
        }
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

    hidden function drawSideArc(dc, color, direction, startDegree, endDegree, radius, penWidth) {
        dc.setColor(color, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(penWidth);
        dc.drawArc(
            me.screenWidth / 2,
            me.screenHeight / 2,
            radius,
            direction,
            startDegree,
            endDegree
        );
    }
}
