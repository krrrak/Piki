import QtQuick
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import "../controls"

Rectangle {
    id: fsv
    color: "white"
    property var onClose: function() {}

    required property var metaPages
    required property var metaSinglePage
    required property int pageCount

    function close() {
        onClose();
        destroy();
    }

    PixivImage {
        visible: fsv.pageCount <= 1
        source: fsv.metaSinglePage
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
    }

    ListView {
        visible: fsv.pageCount > 1
        anchors.fill: parent
        model: fsv.metaPages
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        clip: true
        interactive: fsv.pageCount > 1

        delegate: PixivImage {
            required property var modelData
            source: modelData.original
            fillMode: Image.PreserveAspectFit
            width: ListView.view.width
            height: ListView.view.height
        }
    }

    Controls.ToolButton {
        anchors {
            top: parent.top
            right: parent.right
            margins: Kirigami.Units.mediumSpacing
        }
        icon.name: "dialog-close"
        icon.width: 20
        icon.height: 20
        onClicked: fsv.close()
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: fsv.close()
    }
}
