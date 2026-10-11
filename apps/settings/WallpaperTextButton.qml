import QtQuick

// macOS-style capsule: the emphasized form is the filled primary button
// (accent fill, white label), the plain form is a borderless label that
// picks up a neutral tint on hover. Both dip on press.
Rectangle {
    id: button
    property string label: ""
    property var colors
    property bool emphasized: false
    signal clicked()
    implicitWidth: textItem.implicitWidth + 28
    implicitHeight: 34
    radius: Math.round(implicitHeight / 2)
    opacity: enabled ? 1 : 0.45
    scale: pointer.pressed ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    readonly property color hoverTint: colors.primaryText
    color: emphasized
        ? (pointer.containsMouse ? Qt.lighter(colors.accent, 1.06) : colors.accent)
        : (pointer.containsMouse
            ? Qt.rgba(hoverTint.r, hoverTint.g, hoverTint.b, 0.08)
            : "transparent")
    Behavior on color { ColorAnimation { duration: 140 } }
    Text {
        id: textItem
        anchors.centerIn: parent
        text: button.label
        color: button.emphasized ? "white" : button.colors.primaryText
        font.pixelSize: 12
        font.weight: Font.Medium
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: button.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}
