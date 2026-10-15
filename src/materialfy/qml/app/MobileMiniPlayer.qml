import QtQuick
import QtQuick.Layouts
import Md3
import Materialfy.Core

// Мини-плеер телефона: плашка над нижней навигацией — обложка, трек и исполнитель (или «Играет на …»),
// лайк, «играть/пауза»; снизу — тонкая полоска прогресса.
// Тап или свайп вверх — полноэкранный плеер; свайп влево/вправо — следующий/предыдущий трек.
Item {
    id: root

    readonly property Item coverItem: coverBox
    signal openNowPlaying(point coverCenter)

    implicitHeight: 64
    visible: opacity > 0.01
    opacity: Player.hasTrack ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.motion.effectsDefault } }

    function _open() {
        root.openNowPlaying(coverBox.mapToItem(null, coverBox.width / 2, coverBox.height / 2))
    }

    PlayerProgress { id: playerProgress; active: root.visible }

    // Плашка ездит за пальцем по горизонтали (переключение трека) и чуть вверх (раскрыть)
    Item {
        id: card
        width: parent.width
        height: parent.height
        x: swipe.active ? Math.max(-120, Math.min(120, swipe.translation.x * 0.6)) : 0
        y: swipe.active ? Math.max(-24, Math.min(0, swipe.translation.y * 0.3)) : 0
        Behavior on x { enabled: !swipe.active; NumberAnimation { duration: Theme.motion.spatialFast; easing.type: Easing.OutBack } }
        Behavior on y { enabled: !swipe.active; NumberAnimation { duration: Theme.motion.spatialFast; easing.type: Easing.OutBack } }
        opacity: 1 - Math.abs(x) / 240

        Rectangle {
            id: bg
            anchors.fill: parent
            radius: Theme.shape.large
            color: Theme.surfaceContainerHighest
        }
        Elevation { target: bg; level: 2 }

        // Тонкий прогресс по нижнему краю, внутри скругления
        Item {
            anchors.fill: parent
            clip: true
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: Theme.shape.large
                width: Math.max(0, (parent.width - 2 * Theme.shape.large) * playerProgress.value)
                height: 2
                radius: 1
                color: Theme.primary
            }
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.shape.large
                anchors.rightMargin: Theme.shape.large
                height: 2
                radius: 1
                color: Theme.fgSurface
                opacity: 0.12
                z: -1
            }
        }

        StateLayer {
            anchors.fill: parent
            radius: Theme.shape.large
            enabled: Player.hasTrack
            onClicked: root._open()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 4
            spacing: 12

            Item {
                id: coverBox
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                MorphImage {
                    id: miniCover
                    anchors.fill: parent
                    visible: Player.cover !== ""
                    source: Player.cover
                    fallbackKind: Player.album !== "" ? "album" : "track"
                    fallbackArtist: Player.artist.split(", ")[0]
                    fallbackTitle: Player.album !== "" ? Player.album : Player.title
                    shape: Player.playing ? "cookie12" : "softSquare"
                    MaskSpin { target: miniCover; spinning: Settings.coverSpin && Player.playing && Player.isLocal === true }
                }
                MorphShape {
                    anchors.fill: parent
                    visible: Player.cover === ""
                    shape: "softSquare"
                    color: Theme.surfaceContainerHigh
                    Icon { anchors.centerIn: parent; name: Player.isEpisode ? "podcasts" : "music_note"; size: 24; color: Theme.fgSurfaceVariant }
                }
                DeviceBadge {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: -4
                    anchors.bottomMargin: -4
                    ringColor: Theme.surfaceContainerHighest
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label {
                    Layout.fillWidth: true
                    text: Player.title
                    type: "titleSmall"
                    weight: 600
                }
                Label {
                    Layout.fillWidth: true
                    visible: !remoteLabel.shown || Player.errorText !== ""
                    text: Player.errorText !== "" ? Player.errorText : Player.artist
                    type: "bodySmall"
                    color: Player.errorText !== "" ? Theme.error : Theme.fgSurfaceVariant
                }
                RemoteLabel {
                    id: remoteLabel
                    Layout.fillWidth: true
                    visible: shown && Player.errorText === ""
                    brief: false
                }
            }

            // устройства — здесь, только пока музыка не на этом телефоне; иначе — в полноэкранном плеере
            DeviceButton {
                visible: Player.remote === true || Player.deviceLost === true || Player.transferring === true
                iconOnly: true
            }
            LikeButton { visible: !Player.isEpisode; track: Player.track }
            IconButton {
                visible: Player.isEpisode
                icon: "bookmark"
                checkable: true
                autoToggle: false
                checked: Library.savedRevision >= 0 && Player.uri !== "" && Library.isSaved(Player.uri)
                enabled: Player.uri !== ""
                onClicked: Library.toggleSaved(Player.uri)
            }
            Item {
                implicitWidth: 48
                implicitHeight: 48
                IconButton {
                    anchors.centerIn: parent
                    icon: Player.playing ? "pause" : "play_arrow"
                    iconSize: 30
                    iconFill: 1
                    iconColor: Theme.fgSurface
                    enabled: Player.hasTrack
                    onClicked: Player.togglePlay()
                }
                LoadingIndicator {
                    anchors.centerIn: parent
                    size: 44
                    color: Theme.primary
                    visible: Player.buffering
                    opacity: 0.5
                }
            }
        }
    }

    // Слой поверх плашки: обработчик на самом root не видел касаний — их забирали кнопки и область нажатия
    // плашки (MouseArea принимает нажатие, до обработчиков родителя оно не доходит). Здесь DragHandler получает
    // нажатие первым, держит его пассивно (тап по кнопке проходит) и забирает жест, когда палец поехал.
    Item {
        anchors.fill: parent
        z: 10
        DragHandler {
            id: swipe
            target: null
            enabled: Player.hasTrack
            onActiveChanged: {
                if (active)
                    return
                const t = translation
                if (Math.abs(t.x) > 72 && Math.abs(t.x) > Math.abs(t.y)) {
                    MobileShell.haptic()
                    if (t.x < 0)
                        Player.next()
                    else
                        Player.previous()
                } else if (t.y < -40 && Math.abs(t.y) > Math.abs(t.x)) {
                    root._open()
                }
            }
        }
    }
}
