// The notification daemon and history live in this independent Quickshell shell.
// Popup expiry hides a card; it does not destroy its history or app actions.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../../bar"
import "../core"
QtObject {
    id: root
    property var entries: []
    property bool dnd: false
    readonly property var history: entries.filter(e => !e.notification.transient)
    readonly property var popups: entries.filter(e => e.popup).slice(0, Settings.notificationPopupLimit)
    readonly property int count: history.length
    readonly property int unreadCount: history.filter(e => e.unread).length
    property SystemClock clock: SystemClock { precision: SystemClock.Minutes }
    readonly property date now: clock.date
    // Relative timestamps refresh every minute without one timer per card.
    function age(date): string {
        const minutes = Math.max(0, Math.floor((now.getTime() - date.getTime()) / 60000));
        return minutes < 1 ? "Now" : minutes < 60 ? minutes + "m"
            : minutes < 1440 ? Math.floor(minutes / 60) + "h" : Math.floor(minutes / 1440) + "d";
    }
    function markAllRead(): void {
        entries = entries.map(e => Object.assign({}, e, {unread: false}));
    }
    function markRead(id): void {
        entries = entries.map(e => e.notification.id === id ? Object.assign({}, e, {unread: false}) : e);
    }
    property NotificationServer server: NotificationServer {
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        persistenceSupported: true
        // Text is rendered as plain text, never untrusted rich text or images.
        bodyMarkupSupported: false
        onNotification: notification => root.receive(notification)
    }
    function receive(n): void {
        n.tracked = true;
        const existing = entries.find(e => e.notification.id === n.id);
        // Installed Quickshell 0.3.2 returns the D-Bus timeout in milliseconds.
        const timeout = n.expireTimeout;
        const duration = timeout === 0 ? 0 : timeout > 0 ? timeout : Settings.notificationTimeout;
        const entry = {notification: n, received: new Date(), unread: PanelState.opened !== "notifications",
            popup: !n.lastGeneration && !dnd && PanelState.opened !== "notifications",
            deadline: duration > 0 ? Date.now() + duration : 0};
        entries = [entry].concat(entries.filter(e => e.notification.id !== n.id));
        if (!existing) n.closed.connect(() => root.remove(n.id));
        // Bound memory, explicitly dismissing only the oldest excess entries.
        if (entries.length > Settings.notificationHistoryLimit)
            entries[entries.length - 1].notification.dismiss();
    }
    function remove(id): void { entries = entries.filter(e => e.notification.id !== id); }
    function hidePopups(): void {
        const transient = entries.filter(e => e.popup && e.notification.transient);
        entries = entries.map(e => Object.assign({}, e, {popup: false}));
        transient.forEach(e => e.notification.expire());
    }
    function clear(): void { entries.slice().forEach(e => e.notification.dismiss()); }
    function dismiss(id): void {
        const entry = entries.find(e => e.notification.id === id);
        if (entry) entry.notification.dismiss();
    }
    function invoke(id, actionId): void {
        const entry = entries.find(e => e.notification.id === id);
        if (!entry) return;
        const action = entry.notification.actions.find(a => a.identifier === actionId);
        if (action) { markRead(id); action.invoke(); }
    }
    function activate(id): void {
        const entry = entries.find(e => e.notification.id === id);
        if (!entry) return;
        const action = entry.notification.actions.find(a => a.identifier === "default");
        if (!action) { markRead(id); return; }
        entries = entries.map(e => e.notification.id === id
            ? Object.assign({}, e, {unread: false, popup: false}) : e);
        PanelState.close();
        action.invoke();
    }
    property Connections panel: Connections {
        target: PanelState
        function onOpenedChanged() { if (PanelState.opened === "notifications") root.hidePopups(); }
    }
    onDndChanged: { if (dnd) hidePopups(); }
    property Timer expiry: Timer {
        interval: 250; repeat: true
        running: root.entries.some(e => (e.popup || e.notification.transient) && e.deadline > 0)
        onTriggered: {
            const expired = root.entries.filter(e => (e.popup || e.notification.transient) && e.deadline > 0 && e.deadline <= Date.now());
            if (!expired.length) return;
            const ids = expired.map(e => e.notification.id);
            root.entries = root.entries.map(e => ids.includes(e.notification.id)
                ? Object.assign({}, e, {popup: false}) : e);
            expired.filter(e => e.notification.transient).forEach(e => e.notification.expire());
        }
    }
}
