/*
    SPDX-License-Identifier: MIT
*/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_repo: repoField.text
    property alias cfg_workflow: workflowField.text
    property alias cfg_branch: branchField.text
    property alias cfg_label: labelField.text
    property alias cfg_intervalMinutes: intervalSpin.value
    property alias cfg_token: tokenField.text

    Kirigami.FormLayout {
        TextField {
            id: repoField
            Kirigami.FormData.label: i18n("Repository:")
            placeholderText: i18n("owner/repo or https://github.com/owner/repo")
            Layout.fillWidth: true
        }

        TextField {
            id: workflowField
            Kirigami.FormData.label: i18n("Workflow file:")
            placeholderText: i18n("ci.yml (leave empty for any workflow)")
            Layout.fillWidth: true
        }

        TextField {
            id: branchField
            Kirigami.FormData.label: i18n("Branch:")
            placeholderText: i18n("default branch")
            Layout.fillWidth: true
        }

        TextField {
            id: labelField
            Kirigami.FormData.label: i18n("Badge label:")
            placeholderText: i18n("ci")
            Layout.fillWidth: true
        }

        SpinBox {
            id: intervalSpin
            Kirigami.FormData.label: i18n("Refresh every (minutes):")
            from: 1
            to: 360
            editable: true
        }

        TextField {
            id: tokenField
            Kirigami.FormData.label: i18n("GitHub token:")
            placeholderText: i18n("fine-grained PAT with Actions read access")
            echoMode: TextInput.Password
            Layout.fillWidth: true
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.disabledTextColor
            text: i18n("The token is required for private repositories. Create a fine-grained token at github.com/settings/tokens with 'Actions: Read-only' access to the repository.")
        }
    }
}
