// Your customization file: dimensions, font, colors, and workspace count.
// Save this file to reload Quickshell automatically.
pragma Singleton
import QtQuick
QtObject {
    // Passive volume indicator below the clock; timeout resets on every change.
    readonly property int volumeOsdWidth: 280
    readonly property int volumeOsdTimeout: 1500
    // Hover descriptions are disabled globally; click menus still work.
    readonly property bool showTooltips: false
    // The whole bar's appearance, in one small settings file.
    // Empty chooses the first connected screen; set a name to pin the bar.
    readonly property string monitor: ""
    readonly property int height: 30
    readonly property int topMargin: 7
    readonly property int sideMargin: 6
    readonly property int workspaceCount: 5
    readonly property color background: "#1d2021"
    readonly property color border: "#424544"
    readonly property color foreground: "#dddddd"
    readonly property color muted: "#4d4d4d"
    readonly property color active: "#ad685a"
    readonly property color hover: "#282c2d"
    readonly property color warning: "#d8a080"
    readonly property string font: "JetBrainsMono Nerd Font"
    // Text and SVG sizes are independent. Keep height at least iconSize + 4.
    readonly property int fontSize: 16
    readonly property int iconSize: 18
    readonly property int iconSpacing: 4
    // Large circular workspace indicators, using colors sampled from your image.
    readonly property int workspaceDotSize: 15
    readonly property int workspaceWidth: 39
    readonly property color workspaceOccupied: "#4d4d4d"
    readonly property color workspaceEmpty: "#2c2c2c"
    // Only workspace selection animates: the active circle expands into a pill.
    readonly property bool workspaceAnimations: true
    readonly property int workspaceAnimationDuration: 180 // Milliseconds.
    readonly property int workspaceActiveDotWidth: 25
    // The screenshot's exact font is unknown; JetBrains Mono Bold is a close match.
    readonly property int fontWeight: Font.Bold
    readonly property int clockFontSize: 18
    readonly property string clockFormat: "h:mm AP"
    // Power-menu tiles: separate sizing and accent from the monochrome bar.
    readonly property int powerTileWidth: (powerMenuWidth - powerMenuPadding * 2 - powerMenuSpacing) / 2
    readonly property int powerTileHeight: 78
    readonly property color powerAccent: "#9fe3d5"
    // Translucent power popup with animated controls and session tiles.
    readonly property int powerMenuWidth: 370
    readonly property int powerMenuPadding: 20
    readonly property int powerMenuSpacing: 12
    readonly property int powerMenuRadius: 22
    readonly property color powerMenuBackground: "#1b1c22"
    readonly property real powerMenuOpacity: 0.84
    readonly property color powerTileBackground: "#70383d46"
    readonly property color powerText: "#f1f1f5"
    readonly property color powerMuted: "#999aa7"
    readonly property color powerSelectedText: "#10201c"
    readonly property string powerFont: "Noto Sans"
    readonly property int powerTextSize: 14
    readonly property int powerSliderRowHeight: 62
    readonly property int powerSliderTrackHeight: 6
    readonly property int powerSliderHandleSize: 14
    readonly property int brightnessMinimum: 1

    // Independent bar groups. Transparent gaps reveal the wallpaper underneath.
    readonly property int barRadius: 10
    readonly property int barGroupGap: 10 // Gaps between the right-hand cards.
    readonly property int barGroupPadding: 6 // Inside each card's left/right edges.
    readonly property int barGroupSpacing: 2 // Between controls in the same card.
    readonly property int barGroupBorderWidth: 1
    // Translucent card backgrounds: 0 = transparent, 1 = solid. Icons/text stay opaque.
    readonly property real barGroupOpacity: 0.80
    readonly property int barCenterMinimumGap: 20 // Hide the center card if space runs out.

    // Notification/calendar windows share these constants; the bar keeps its colors.
    readonly property color panelBackground: "#201e20"
    readonly property color panelCard: "#342a36"
    readonly property color panelHover: "#443548"
    readonly property color panelBorder: "#483b49"
    readonly property color panelText: "#f1eaf2"
    readonly property color panelMuted: "#b5a7b8"
    readonly property color panelAccent: "#e3ade8"
    readonly property int panelRadius: 14
    readonly property int panelPadding: 16
    readonly property int panelGap: 8
    readonly property int panelFontSize: 13
    readonly property int panelTitleSize: 17
    readonly property int panelButtonHeight: 32
    readonly property int notificationWidth: 440
    readonly property int notificationHeight: 700
    readonly property int notificationIconSize: 52
    readonly property int notificationCardPadding: 16
    readonly property int notificationPopupWidth: 380
    readonly property int notificationTimeout: 5000 // Milliseconds; default popup timeout for all urgencies.
    readonly property int notificationPopupLimit: 3
    readonly property int notificationHistoryLimit: 100
    // Notification-only styling: adjustable background, opaque readable cards.
    // Change these here without changing the separate calendar or top bar.
    readonly property color notificationBackground: "#1b1c22"
    // Background opacity: 0 = fully transparent, 1 = fully solid.
    // Only the panel background changes; text, icons and cards stay readable.
    readonly property real notificationBackgroundOpacity: 0.85
    readonly property color notificationCard: "#25262e"
    readonly property color notificationCardHover: "#2d2e38"
    readonly property color notificationText: "#f1f1f5"
    readonly property color notificationMuted: "#999aa7"
    readonly property color notificationControl: "#343540"
    readonly property color notificationAccent: "#8ab4ff"
    readonly property string notificationFont: "Noto Sans"
    readonly property int notificationTitleSize: 28
    readonly property int notificationTextSize: 14
    readonly property int notificationRadius: 18
    readonly property int notificationSpacing: 12
    readonly property int notificationControlHeight: 34
    readonly property int notificationDndHeight: 88
    readonly property int notificationSwitchWidth: 48
    readonly property int notificationSwitchHeight: 28
    readonly property int calendarWidth: 360
    readonly property int calendarHeight: 470
    readonly property int calendarClockSize: 52
    readonly property int calendarCellHeight: 34
    // Wi-Fi overlay. Opacity applies to the background, not text or controls.
    readonly property int wifiWidth: 400
    readonly property int wifiHeight: 540
    readonly property int wifiRowHeight: 64
    readonly property int wifiRadius: 22
    readonly property real wifiBackgroundOpacity: 0.95
    readonly property color wifiBackground: "#1b1c22"
    readonly property color wifiCard: "#25262e"
    readonly property color wifiHover: "#30313c"
    readonly property color wifiText: "#f1f1f5"
    readonly property color wifiMuted: "#999aa7"
    readonly property color wifiAccent: "#8ab4ff"
    readonly property string wifiFont: "Noto Sans"
    readonly property int wifiTextSize: 15
    readonly property int wifiTitleSize: 24
    readonly property int wifiPadding: 18
    readonly property int wifiSpacing: 10
    readonly property int wifiSwitchWidth: 56
    readonly property int wifiSwitchHeight: 32
    readonly property int wifiButtonHeight: 36
    readonly property int wifiPasswordHeight: 42
    readonly property int wifiConnectTimeout: 45000
    // Bluetooth matches Wi-Fi by default; override any value independently here.
    readonly property int bluetoothWidth: wifiWidth
    readonly property int bluetoothHeight: 580
    readonly property int bluetoothRowHeight: 82
    readonly property int bluetoothRadius: wifiRadius
    readonly property real bluetoothBackgroundOpacity: wifiBackgroundOpacity
    readonly property color bluetoothBackground: wifiBackground
    readonly property color bluetoothCard: wifiCard
    readonly property color bluetoothHover: wifiHover
    readonly property color bluetoothText: wifiText
    readonly property color bluetoothMuted: wifiMuted
    readonly property color bluetoothAccent: wifiAccent
    readonly property string bluetoothFont: wifiFont
    readonly property int bluetoothTextSize: wifiTextSize
    readonly property int bluetoothTitleSize: wifiTitleSize
    readonly property int bluetoothPadding: wifiPadding
    readonly property int bluetoothSpacing: wifiSpacing

    // Wallpaper collection (recursive). JPG, PNG, WebP and BMP are supported.
    // Only this folder is scanned; incomplete downloads are ignored.
    readonly property string wallpaperFolder: "~/Pictures/Wallpapers"
    readonly property string wallpaperFit: "cover" // cover, contain, tile, fit
    readonly property int wallpaperWidth: 820
    readonly property int wallpaperHeight: 610
    readonly property int wallpaperColumns: 3
    readonly property int wallpaperMinimumTileWidth: 160
    readonly property int wallpaperPadding: 22
    readonly property int wallpaperSpacing: 14
    readonly property int wallpaperRadius: 24
    readonly property int wallpaperCardRadius: 12
    readonly property int wallpaperLabelHeight: 42
    readonly property int wallpaperButtonHeight: 36
    readonly property int wallpaperIconSize: 18
    readonly property int wallpaperScrollBarWidth: 6
    readonly property real wallpaperDisabledOpacity: 0.45
    readonly property int wallpaperTitleSize: 26
    readonly property int wallpaperTextSize: 14
    readonly property int wallpaperThumbnailWidth: 480
    readonly property int wallpaperThumbnailHeight: 270
    readonly property real wallpaperBackgroundOpacity: 0.95
    readonly property color wallpaperBackground: "#1b1c22"
    readonly property color wallpaperCard: "#25262e"
    readonly property color wallpaperHover: "#30313c"
    readonly property color wallpaperBorder: "#353640"
    readonly property color wallpaperText: "#f1f1f5"
    readonly property color wallpaperMuted: "#999aa7"
    readonly property color wallpaperAccent: "#8ab4ff"
    readonly property color wallpaperAccentText: "#102039"
    readonly property color wallpaperError: warning
    readonly property string wallpaperFont: "Noto Sans"


}
