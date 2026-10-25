// Independent notification daemon: restarting the bar does not lose history.
import Quickshell
import Quickshell.Io
import "notifications/services"
import "notifications/core"
import "notifications/popups"
ShellRoot {
    NotificationCenter {}
    CalendarPopup {}
    NotificationToasts {}
    IpcHandler {
        target: "notifications"
        function toggle(): void { PanelState.toggle("notifications"); }
        function calendar(): void { PanelState.toggle("calendar"); }
        function close(): void { PanelState.close(); }
        function dnd(enabled: bool): void { NotificationStore.dnd = enabled; }
        function clear(): void { NotificationStore.clear(); }
        function dismiss(id: int): void { NotificationStore.dismiss(id); }
        function invoke(id: int, action: string): void { NotificationStore.invoke(id, action); }
        function status(): string {
            return JSON.stringify({panel: PanelState.opened, count: NotificationStore.count, unread: NotificationStore.unreadCount,
                popups: NotificationStore.popups.length, dnd: NotificationStore.dnd,
                ids: NotificationStore.history.map(e => e.notification.id),
                timeouts: NotificationStore.entries.map(e => ({id: e.notification.id, timeout: e.notification.expireTimeout}))});
        }
    }
}
