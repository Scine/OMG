import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Card {
    id: newsCard
    title: i18n("News")
    iconName: "news-subscribe"
    loading: root.newsLoading
    errorText: root.newsError

    Repeater {
        model: root.newsData
        delegate: RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.topMargin: Kirigami.Units.smallSpacing
                width: Kirigami.Units.smallSpacing
                height: Kirigami.Units.smallSpacing
                radius: width / 2
                color: Kirigami.Theme.highlightColor
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    text: modelData.title
                    wrapMode: Text.WordWrap
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: modelData.link.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (modelData.link.length > 0) Qt.openUrlExternally(modelData.link)
                    }
                }
                PlasmaComponents.Label {
                    visible: modelData.source.length > 0 || modelData.date.length > 0
                    font: Kirigami.Theme.smallFont
                    opacity: 0.55
                    text: {
                        var parts = [];
                        if (modelData.source.length > 0) parts.push(modelData.source);
                        if (modelData.date.length > 0) parts.push(modelData.date);
                        return parts.join(" · ");
                    }
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }

    PlasmaComponents.Label {
        visible: root.newsData.length === 0 && !root.newsLoading && root.newsError.length === 0
        text: i18n("No headlines.")
        opacity: 0.6
    }
}
