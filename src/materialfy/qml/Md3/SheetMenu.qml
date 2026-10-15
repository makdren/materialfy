import QtQuick
import QtQuick.Shapes

// Меню нижним листом MD3 (раскладка телефона): тот же API, что у Menu — open(items), close(), picked(index),
// triggered(id, item); пункты — { id, text, icon, enabled, checked, hint, separator, submenu }.
// Подменю открывается на месте списка (сверху — строка «‹ назад» с именем родителя). Закрыть — тап по
// затемнению, свайп листа вниз или «назад» системы (MobileMain зовёт back()).
Item {
    id: root

    property var items: []
    // вершина стека — показанный список: [{ items, title, parentIndex }]
    property var _levels: []
    readonly property var _current: _levels.length ? _levels[_levels.length - 1] : { items: [], title: "", parentIndex: -1 }
    property bool opened: false

    signal picked(int index)
    signal triggered(string id, var item)

    function open(list) {
        items = list
        _levels = [{ items: list, title: "", parentIndex: -1 }]
        sheet.dragOffset = 0
        flick.contentY = 0
        opened = true
    }
    function close() { opened = false }
    // «назад» системы: из подменю — к родителю, иначе закрыть. false — лист и так закрыт
    function back() {
        if (!opened)
            return false
        if (_levels.length > 1)
            _levels = _levels.slice(0, -1)
        else
            close()
        return true
    }

    function _usable(item) {
        return item && !item.separator && item.enabled !== false
    }
    function _activate(index) {
        const item = _current.items[index]
        if (!_usable(item))
            return
        if (item.submenu && item.submenu.length > 0) {
            _levels = _levels.concat([{ items: item.submenu, title: item.text ?? "", parentIndex: index }])
            flick.contentY = 0
            return
        }
        const top = _levels.length === 1
        close()
        if (top)
            picked(index)
        triggered(item.id ?? "", item)
    }

    property real progress: opened ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: root.opened ? Theme.motion.spatialFast : Theme.motion.effectsDefault
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.opened ? Theme.motion.emphasizedDecelerate : Theme.motion.emphasizedAccelerate
        }
    }
    visible: progress > 0.001

    // Затемнение под листом: клики по приложению не проходят, тап — закрыть
    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
        opacity: 0.32 * root.progress
        MouseArea {
            anchors.fill: parent
            enabled: root.opened
            onClicked: root.close()
            onWheel: wheel => wheel.accepted = true
        }
    }

    Rectangle {
        id: sheet
        property real dragOffset: 0
        readonly property real maxHeight: root.height - Theme.safeTop - 48
        width: Math.min(root.width, 640)
        height: Math.min(maxHeight, column.implicitHeight + 8 + Theme.safeBottom)
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height - height * root.progress + dragOffset
        topLeftRadius: Theme.shape.extraLarge
        topRightRadius: Theme.shape.extraLarge
        color: Theme.surfaceContainerLow
        Behavior on height { NumberAnimation { duration: Theme.motion.spatialFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.emphasized } }

        // клики внутри листа не уходят в затемнение
        MouseArea { anchors.fill: parent; onWheel: wheel => wheel.accepted = true }

        // Ручка и свайп вниз — закрыть
        Item {
            id: grip
            width: parent.width
            height: 28
            Rectangle {
                anchors.centerIn: parent
                width: 32
                height: 4
                radius: 2
                color: Theme.fgSurfaceVariant
                opacity: 0.4
            }
            DragHandler {
                target: null
                xAxis.enabled: false
                onTranslationChanged: sheet.dragOffset = Math.max(0, translation.y)
                onActiveChanged: {
                    if (active)
                        return
                    if (sheet.dragOffset > sheet.height * 0.25)
                        root.close()
                    sheet.dragOffset = 0
                }
            }
        }

        Flickable {
            id: flick
            anchors.top: grip.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.safeBottom
            contentHeight: column.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Column {
                id: column
                width: flick.width
                bottomPadding: 8

                // Подменю: «‹ Добавить в плейлист»
                Item {
                    visible: root._levels.length > 1
                    width: parent.width
                    height: visible ? 52 : 0
                    Shape {
                        x: 24
                        width: 24
                        height: 24
                        anchors.verticalCenter: parent.verticalCenter
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: Theme.fgSurface
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            startX: 15; startY: 6
                            PathLine { x: 9; y: 12 }
                            PathLine { x: 15; y: 18 }
                        }
                    }
                    Label {
                        x: 64
                        width: parent.width - x - 24
                        anchors.verticalCenter: parent.verticalCenter
                        text: root._current.title
                        type: "titleMedium"
                        weight: 600
                    }
                    StateLayer {
                        anchors.fill: parent
                        onClicked: root.back()
                    }
                }
                Rectangle {
                    visible: root._levels.length > 1
                    x: 24
                    width: parent.width - 48
                    height: visible ? 1 : 0
                    color: Theme.outlineVariant
                    opacity: 0.6
                }

                Repeater {
                    model: root._current.items

                    Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool isSeparator: modelData.separator === true
                        readonly property bool usable: root._usable(modelData)
                        readonly property bool hasSub: !isSeparator && !!modelData.submenu && modelData.submenu.length > 0

                        width: column.width
                        height: isSeparator ? 17 : 52

                        Rectangle {
                            visible: row.isSeparator
                            x: 24
                            width: parent.width - 48
                            height: 1
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.outlineVariant
                            opacity: 0.6
                        }

                        Item {
                            visible: !row.isSeparator
                            anchors.fill: parent
                            opacity: row.usable ? 1 : Theme.stateLayer.disabledContent

                            Icon {
                                visible: (row.modelData.icon ?? "") !== ""
                                x: 24
                                anchors.verticalCenter: parent.verticalCenter
                                name: row.modelData.icon ?? ""
                                size: 24
                                color: Theme.fgSurfaceVariant
                            }
                            Label {
                                x: 64
                                width: parent.width - x - 24 - (row.hasSub || row.modelData.checked === true ? 32 : 0)
                                       - (hint.visible ? hint.implicitWidth + 12 : 0)
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData.text ?? ""
                                type: "bodyLarge"
                                color: Theme.fgSurface
                            }
                            Label {
                                id: hint
                                visible: (row.modelData.hint ?? "") !== ""
                                anchors.right: parent.right
                                anchors.rightMargin: 24 + (row.hasSub || row.modelData.checked === true ? 32 : 0)
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData.hint ?? ""
                                type: "labelMedium"
                                color: Theme.fgSurfaceVariant
                            }
                            Icon {
                                visible: row.modelData.checked === true
                                anchors.right: parent.right
                                anchors.rightMargin: 24
                                anchors.verticalCenter: parent.verticalCenter
                                name: "check"
                                size: 24
                                color: Theme.primary
                            }
                            Shape {
                                visible: row.hasSub
                                anchors.right: parent.right
                                anchors.rightMargin: 24
                                width: 24
                                height: 24
                                anchors.verticalCenter: parent.verticalCenter
                                preferredRendererType: Shape.CurveRenderer
                                ShapePath {
                                    strokeColor: Theme.fgSurfaceVariant
                                    strokeWidth: 2
                                    fillColor: "transparent"
                                    capStyle: ShapePath.RoundCap
                                    joinStyle: ShapePath.RoundJoin
                                    startX: 9; startY: 6
                                    PathLine { x: 15; y: 12 }
                                    PathLine { x: 9; y: 18 }
                                }
                            }
                        }

                        StateLayer {
                            visible: !row.isSeparator
                            enabled: row.usable
                            anchors.fill: parent
                            onClicked: root._activate(row.index)
                        }
                    }
                }
            }
        }
    }
}
