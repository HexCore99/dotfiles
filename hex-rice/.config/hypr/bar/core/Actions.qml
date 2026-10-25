// Launch external actions without putting app/menu code in visual modules.
// The Python action handler uses argument lists, never shell-evaluated menu text.
pragma Singleton
import QtQuick
import Quickshell
QtObject {
    // Dedicated allowlisted helper for the four system actions.
    function power(action: string): void {
        Quickshell.execDetached(["python", Quickshell.shellPath("core/power_actions.py"), action]);
    }
    function run(action: string): void {
        Quickshell.execDetached(["sh", Quickshell.shellPath("../scripts/bar-actions"), action]);
    }
}
