import QtQuick
import qs.desktop.modules.bar
import qs.desktop.modules.common
import qs.desktop.modules.dock

// Presentational transfer-rate readout for the network tray cell. Sampling
// lives in NetworkService (1 Hz while a device is connected) so the Wi-Fi
// tooltip can show the same rates; this component only formats the shared
// snapshot and never performs network-management actions.
Item {
    id: root

    property bool dockHosted: false

    signal panelToggleRequested()

    // Keep the arrows with the adjacent labels: wallpaper-facing bar content
    // uses the bar's white ink, while Dock-hosted content follows its glass.
    readonly property color glyphInk: root.dockHosted
        ? AppearanceTokens.content.glassInk() : ThemeService.barForegroundColor

    implicitWidth: trafficContent.implicitWidth
    implicitHeight: 22
    width: implicitWidth
    height: implicitHeight
    visible: NetworkService.available && NetworkService.deviceState === "connected"

    Row {
        id: trafficContent
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        // Draw arrows ourselves so their white foreground is as dependable as
        // NetworkStatus on transparent glass, independent of icon themes.
        Canvas {
            id: directionGlyph
            width: 13
            height: 18
            // glyphInk lives on the root item, so the change signal is
            // reconnected here instead of as a Canvas-scoped handler.
            Connections {
                target: root
                function onGlyphInkChanged() { directionGlyph.requestPaint() }
            }
            // The two labels beside this glyph carry Text.Outline; the arrows
            // are painted, not typeset, so they draw the same edge themselves:
            // the whole mark once more with a wider stroke underneath.
            function traceArrows(ctx) {
                ctx.beginPath()
                // Keep the opposing arrows offset: together they read as one
                // compact traffic glyph, rather than two independent controls.
                // The adjacent labels explicitly identify the two data rows.
                // Download arrow.
                ctx.moveTo(3.5, 2.5); ctx.lineTo(3.5, 7.5)
                ctx.moveTo(1.4, 5.5); ctx.lineTo(3.5, 7.7); ctx.lineTo(5.6, 5.5)
                // Upload arrow.
                ctx.moveTo(9.5, 15.5); ctx.lineTo(9.5, 10.5)
                ctx.moveTo(7.4, 12.5); ctx.lineTo(9.5, 10.3); ctx.lineTo(11.6, 12.5)
                ctx.stroke()
            }
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                if (root.dockHosted ? AppearanceTokens.isDarkTheme
                        : ThemeService.barForegroundOutlined) {
                    ctx.save()
                    ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.38)
                    ctx.lineWidth = 1.35 + 2.2
                    traceArrows(ctx)
                    ctx.restore()
                }
                ctx.strokeStyle = root.glyphInk
                ctx.lineWidth = 1.35
                traceArrows(ctx)
            }
        }

        Column {
            spacing: -1
            Text {
                text: "下行 " + NetworkService.formatRate(NetworkService.downloadBytesPerSecond)
                color: root.dockHosted ? ThemeService.foregroundColor
                    : ThemeService.barForegroundColor
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.38)
                font { family: "SF Pro Display"; pixelSize: 9; weight: Font.DemiBold }
            }
            Text {
                text: "上行 " + NetworkService.formatRate(NetworkService.uploadBytesPerSecond)
                color: root.dockHosted ? ThemeService.foregroundColor
                    : ThemeService.barForegroundColor
                style: Text.Outline
                styleColor: Qt.rgba(0, 0, 0, 0.38)
                font { family: "SF Pro Display"; pixelSize: 9; weight: Font.DemiBold }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.panelToggleRequested()
    }
}
