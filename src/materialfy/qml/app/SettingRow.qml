import QtQuick
import QtQuick.Layouts
import Md3

// Строка настройки: заголовок + пояснение слева, контрол справа (кладётся внутрь).
// Если контрол не помещается рядом с подписью (узкое окно) — он уходит под неё.
GridLayout {
    id: root

    property string title
    property string description
    default property alias control: slot.data

    Layout.fillWidth: true
    // ширину задаёт родитель: иначе неявная ширина двух колонок распирает строку и она не переносится
    Layout.preferredWidth: 0
    // перенос контрола под подпись — с запасом ±16 px, иначе у границы строка мигала бы при растягивании
    property bool _stacked: false
    function _updateStack() {
        if (width <= 0)
            return
        const edge = slot.implicitWidth + 200
        _stacked = _stacked ? width < edge + 16 : width < edge - 16
    }
    onWidthChanged: _updateStack()
    Component.onCompleted: _stacked = width > 0 && width < slot.implicitWidth + 200
    columns: _stacked ? 1 : 2
    columnSpacing: 24
    rowSpacing: 10

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        // длинный заголовок (узкий экран, русский) — переносится, а не обрезается
        Label { Layout.fillWidth: true; text: root.title; type: "bodyLarge"; wrapMode: Text.WordWrap; elide: Text.ElideNone }
        Label {
            visible: root.description !== ""
            Layout.fillWidth: true
            text: root.description
            type: "bodySmall"
            color: Theme.fgSurfaceVariant
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            lineHeightMode: Text.ProportionalHeight
            lineHeight: 1.2
        }
    }
    Item {
        id: slot
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        // контрол стал шире (другой язык, длиннее подпись кнопки) — пересчитать перенос
        onImplicitWidthChanged: root._updateStack()
    }
}
