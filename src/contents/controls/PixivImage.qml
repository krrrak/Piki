// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025 Micro <microgamercz@proton.me>

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Image {
    id: px
    asynchronous: true
    retainWhileLoading: true

    Rectangle {
        z: 1
        visible: px.status === Image.Loading
        anchors.fill: parent
        color: "white"

        Column {
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Controls.BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: true
            }

            Controls.Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Math.round(px.progress * 100) + "%"
                color: Kirigami.Theme.textColor
            }
        }
    }
}
