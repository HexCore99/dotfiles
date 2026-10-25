// One keyboard-accessible thumbnail. This component emits intent only; it does
// not run commands. The active badge follows confirmed Hyprpaper state.
import QtQuick
import QtQuick.Controls.Basic
import Quickshell.Widgets
import ".."
Button {
    id: control
    required property var wallpaper
    property bool current: false
    padding: 0
    Accessible.name: wallpaper.name + (current ? ", active wallpaper" : "")
    background: Rectangle {
        radius: Settings.wallpaperCardRadius
        color: control.hovered ? Settings.wallpaperHover : Settings.wallpaperCard
    }
    contentItem: ClippingRectangle {
        radius: Settings.wallpaperCardRadius
        color: "transparent"
        Image {
            id: preview
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: parent.height - Settings.wallpaperLabelHeight
            source: control.wallpaper.thumbnail
            asynchronous: true; cache: false
            sourceSize.width: Settings.wallpaperThumbnailWidth
            sourceSize.height: Settings.wallpaperThumbnailHeight
            fillMode: Image.PreserveAspectCrop
        }
        SvgIcon {
            visible: preview.status === Image.Error
            name: "image"; color: Settings.wallpaperMuted
            anchors.centerIn: preview
            width: Settings.wallpaperIconSize * 2; height: width
        }
        Rectangle {
            visible: control.current
            anchors { top: parent.top; right: parent.right; margins: Settings.wallpaperSpacing / 2 }
            width: badge.implicitWidth + Settings.wallpaperSpacing
            height: Settings.wallpaperButtonHeight - Settings.wallpaperSpacing / 2
            radius: Settings.wallpaperCardRadius
            color: Settings.wallpaperAccent
            Text {
                id: badge
                anchors.centerIn: parent; text: "Active"
                color: Settings.wallpaperAccentText
                font.family: Settings.wallpaperFont; font.pixelSize: Settings.wallpaperTextSize - 2; font.bold: true
            }
        }
        Text {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: Settings.wallpaperSpacing; rightMargin: Settings.wallpaperSpacing }
            height: Settings.wallpaperLabelHeight
            text: control.wallpaper.name; textFormat: Text.PlainText
            color: Settings.wallpaperText; elide: Text.ElideMiddle; verticalAlignment: Text.AlignVCenter
            font.family: Settings.wallpaperFont; font.pixelSize: Settings.wallpaperTextSize - 1
        }
        // Draw above the image so selection remains visible against any artwork.
        Rectangle {
            anchors.fill: parent; radius: Settings.wallpaperCardRadius
            color: "transparent"
            border.width: control.current || control.visualFocus ? 2 : 1
            border.color: control.current || control.visualFocus ? Settings.wallpaperAccent : Settings.wallpaperBorder
        }
    }
}
