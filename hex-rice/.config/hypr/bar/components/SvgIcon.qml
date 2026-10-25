// Render a local SVG, independently of the text font and text size.
// ColorOverlay recolors the SVG's alpha shape; no glyph font or downloads are used.
import QtQuick
import Qt5Compat.GraphicalEffects
import ".."
Item {
    id: root
    property string name: ""
    property color color: Settings.foreground
    implicitWidth: Settings.iconSize
    implicitHeight: Settings.iconSize

    Image {
        id: artwork
        anchors.fill: parent
        visible: false // Only the tinted result below should be drawn.
        source: root.name === "" ? "" : Qt.resolvedUrl("../assets/icons/" +
            (root.name === "archlinux" ? "brands/archlinux.svg" : "lucide/" + root.name + ".svg"))
        // Rasterize at the display's pixel density to keep SVG edges sharp.
        sourceSize.width: Math.ceil(root.width * Screen.devicePixelRatio)
        sourceSize.height: Math.ceil(root.height * Screen.devicePixelRatio)
        fillMode: Image.PreserveAspectFit
    }
    ColorOverlay {
        anchors.fill: artwork
        source: artwork
        color: root.color
    }
}
