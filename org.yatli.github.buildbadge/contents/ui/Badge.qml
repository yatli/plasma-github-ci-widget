/*
    SPDX-License-Identifier: MIT
*/
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: badge

    signal clicked()

    property string label: "build"
    property string statusText: "no status"
    property string statusColor: "#6e7781"
    property string labelColor: "#555555"
    property var recentColors: []   // oldest → newest (rightmost = latest)

    // Compact: font never larger than 11px, never smaller than 9px.
    readonly property real fs: Math.max(9, Math.min(11, Kirigami.Theme.defaultFont.pixelSize))
    readonly property real hPad: 4
    readonly property real pillHeight: Math.max(15, fs + 6)
    readonly property real dotSize: 5
    readonly property real dotSpacing: 2
    readonly property real rowGap: 3

    // Measure text widths synchronously (TextMetrics) so the panel gets the
    // right cell size on the very first layout — avoids overflowing neighbors.
    TextMetrics {
        id: labelMetrics
        text: badge.label
        font.pixelSize: badge.fs
        font.weight: Font.DemiBold
    }
    TextMetrics {
        id: statusMetrics
        text: badge.statusText
        font.pixelSize: badge.fs
        font.weight: Font.DemiBold
    }

    readonly property real pillWidth: labelMetrics.advanceWidth + statusMetrics.advanceWidth + 4 * hPad
    readonly property real dotsWidth: recentColors.length > 0
        ? recentColors.length * dotSize + (recentColors.length - 1) * dotSpacing : 0
    readonly property bool hasDots: recentColors.length > 0

    implicitWidth: Math.max(pillWidth, dotsWidth)
    implicitHeight: pillHeight + (hasDots ? rowGap + dotSize : 0)

    // Explicit size hints so the panel cell hugs the badge exactly
    // (prevents it overflowing neighbors like the system monitor).
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.minimumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight

    Column {
        anchors.centerIn: parent
        width: badge.implicitWidth
        spacing: badge.rowGap

        Rectangle {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            height: badge.pillHeight
            width: badge.pillWidth
            radius: height / 2
            color: badge.statusColor
            clip: true

            Row {
                height: parent.height

                Rectangle {
                    id: leftPart
                    width: labelMetrics.advanceWidth + 2 * badge.hPad
                    height: parent.height
                    color: badge.labelColor
                    Text {
                        anchors.centerIn: parent
                        text: badge.label
                        color: "#ffffff"
                        font.pixelSize: badge.fs
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    id: rightPart
                    width: statusMetrics.advanceWidth + 2 * badge.hPad
                    height: parent.height
                    color: badge.statusColor
                    Text {
                        anchors.centerIn: parent
                        text: badge.statusText
                        color: "#ffffff"
                        font.pixelSize: badge.fs
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        // Recent-run status overview: a row of colored dots.
        Row {
            id: dotsRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: badge.dotSpacing
            visible: badge.hasDots

            Repeater {
                model: badge.recentColors
                delegate: Rectangle {
                    width: badge.dotSize
                    height: badge.dotSize
                    radius: badge.dotSize / 2
                    color: modelData
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: badge.clicked()
    }
}
