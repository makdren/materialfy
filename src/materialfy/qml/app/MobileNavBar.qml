import QtQuick
import QtQuick.Layouts
import Md3

// Нижняя навигация MD3 (телефон): 3–5 разделов, у активного — иконка залита и стоит на «пилюле»
// secondaryContainer. Под панелью — отступ навигационной полосы системы (Theme.safeBottom).
// items: [{ name, icon, text }]; current — имя активного раздела; activated(name) — тап (повторный тап по
// активному разделу — reselected: вернуться к его корню / прокрутить вверх).
Rectangle {
    id: root

    property var items: []
    property string current
    signal activated(string name)
    signal reselected(string name)

    implicitHeight: 80 + Theme.safeBottom
    color: Theme.surfaceContainer

    // клики сквозь панель не проходят
    MouseArea { anchors.fill: parent; onWheel: wheel => wheel.accepted = true }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 80
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Repeater {
            model: root.items

            Item {
                id: tab
                required property var modelData
                readonly property bool active: root.current === modelData.name
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    id: pill
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 12
                    height: 32
                    width: tab.active ? 64 : 32
                    radius: height / 2
                    color: Theme.secondaryContainer
                    opacity: tab.active ? 1 : 0
                    Behavior on width { NumberAnimation { duration: Theme.motion.spatialFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.motion.emphasizedDecelerate } }
                    Behavior on opacity { NumberAnimation { duration: Theme.motion.effectsFast } }
                }
                Icon {
                    anchors.centerIn: pill
                    name: tab.modelData.icon
                    size: 24
                    fill: tab.active ? 1 : 0
                    weight: tab.active ? 500 : 400
                    color: tab.active ? Theme.fgSecondaryContainer : Theme.fgSurfaceVariant
                    Behavior on fill { NumberAnimation { duration: Theme.motion.effectsDefault } }
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: pill.bottom
                    anchors.topMargin: 4
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: tab.modelData.text
                    type: "labelMedium"
                    weight: tab.active ? 700 : 500
                    color: tab.active ? Theme.fgSurface : Theme.fgSurfaceVariant
                }
                // Касание — вся высота колонки; волна — на месте пилюли, как у системной навигации
                Rectangle {
                    x: (parent.width - 64) / 2
                    y: 12
                    width: 64
                    height: 32
                    radius: 16
                    color: Theme.fgSurface
                    opacity: tapArea.pressed ? Theme.stateLayer.pressed : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.motion.effectsFast } }
                }
                MouseArea {
                    id: tapArea
                    anchors.fill: parent
                    onClicked: {
                        if (tab.active)
                            root.reselected(tab.modelData.name)
                        else
                            root.activated(tab.modelData.name)
                    }
                }
            }
        }
    }
}
