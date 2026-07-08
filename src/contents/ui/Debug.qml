import QtQuick
Item {
    id: debugRoot
    property bool debugVisible: false

    property int _lastDepth: 0
    property int _pagesCreated: 0
    property int _pagesDestroyed: 0
    property int _pagesAlive: 0

    onDebugVisibleChanged: {
        if (debugVisible) {
            _lastDepth = pageStack.depth;
            _pagesAlive = pageStack.depth;
        }
    }

    Rectangle {
        id: debugview
        visible: debugVisible
        z: 1000
        anchors { right: parent.right; bottom: parent.bottom; margins: 10 }
        width: 260; height: 130
        color: "#CC000000"
        radius: 6

        Column {
            anchors { fill: parent; margins: 8 }
            spacing: 4

            Text { text: "[MEM DEBUG]"; color: "#FF0"; font.bold: true; font.pointSize: 10 }
            Text { color: "white"; font.pointSize: 9
                text: "created: " + _pagesCreated + "  destroyed: " + _pagesDestroyed + "  alive: " + _pagesAlive
            }
            Text { color: "white"; font.pointSize: 9
                text: "stack depth: " + pageStack.depth + "  current idx: " + pageStack.currentIndex
            }
            Text { color: "white"; font.pointSize: 9
                text: "current page: " + (pageStack.currentItem?.title ?? "none")
            }
            Text { color: "#AAA"; font.pointSize: 8
                text: "component cache: " + (window && window._compCache ? Object.keys(window._compCache).length : "?")
            }
        }
    }

    Connections {
        target: pageStack
        enabled: debugVisible
        function onDepthChanged() {
            let diff = pageStack.depth - debugRoot._lastDepth;
            if (diff > 0)
                debugRoot._pagesCreated += diff;
            else if (diff < 0)
                debugRoot._pagesDestroyed += -diff;
            debugRoot._pagesAlive = pageStack.depth;
            debugRoot._lastDepth = pageStack.depth;
        }
    }
}
