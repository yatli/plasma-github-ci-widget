/*
    SPDX-License-Identifier: MIT
*/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras

PlasmaExtras.Representation {
    id: popup

    property var listModel: null
    property string repoName: ""
    property string openUrl: ""
    property string emptyText: ""

    collapseMarginsHint: true

    implicitWidth: Kirigami.Units.gridUnit * 16
    implicitHeight: Kirigami.Units.gridUnit * 20

    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.minimumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        // Header
        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            Label {
                text: popup.repoName
                font.weight: Font.Bold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Label {
                text: i18n("CI runs")
                color: Kirigami.Theme.disabledTextColor
            }
        }

        // Runs list
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: popup.emptyText === ""
            model: popup.listModel
            spacing: Kirigami.Units.smallSpacing

            delegate: MouseArea {
                width: list.width
                height: row.implicitHeight
                hoverEnabled: true
                cursorShape: model.url !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (model.url !== "") Qt.openUrlExternally(model.url)

                RowLayout {
                    id: row
                    width: parent.width
                    spacing: Kirigami.Units.smallSpacing

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: model.color
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label {
                            text: model.title
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Label {
                            text: model.time
                            color: Kirigami.Theme.disabledTextColor
                        }
                    }

                    Label {
                        text: model.statusText
                        color: model.color
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

        // Empty / error state
        Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: popup.emptyText !== ""
            text: popup.emptyText
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        // Footer: open in GitHub
        Label {
            Layout.fillWidth: true
            visible: popup.openUrl !== ""
            text: i18n("Open workflow in GitHub →")
            color: Kirigami.Theme.highlightColor
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (popup.openUrl !== "") Qt.openUrlExternally(popup.openUrl)
            }
        }
    }
}
