# Budgie Screenshot

## General
Budgie Screenshot runs as a daemon, waiting for Dbus calls to perform an action. 

## Basics
GUI exists of three windows, mainwindow, select-area window (transparent layer) and aftershot. When calling screenshot from main menu, mainwindow is called by Dbus call*.

To make sure that calls from outside will not clash with currently running actions from GUI, Screenshot keeps track of the state it is in (enum WindowState).

* NONE - No GUI element is active, no action is running
* MAINWINDOW - Mainwindow is running
* SELECTINGAREA - Transparent overlay is active, waiting for user to select an area
* AFTERSHOT - The window in which user is to decide what to do with the shot is active (save to file, copy to clipboard, save & open in default app)
* WAITINGFORSHOT - User initiated screenshot, but waiting for it to happen (possibly/probably with a set delay)

External calls will be blocked unless current state is WindowState.NONE.

## Classes:
#### namespace BudgieScreenshotControl:
* BudgieScreenshotServer
####  namespace NewScreenshotApp:
* CurrentState - Signal handling
* MakeScreenshot - Performing screenshots
* ScreenshotHomeWindow (window) - Mainwindow
* SelectLayer (window) - Transparent layer to select an area
* AfterShotWindow (window) - Decide what to do with the screenshot

