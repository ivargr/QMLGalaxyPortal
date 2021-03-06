import QtQuick 2.3
import QtQuick.Window 2.2
import QtQuick.Controls 1.1
//import QtWebView 1.0
import QtQuick.Layouts 1.1

Rectangle {
    width: main.width
    height: main.height

    ActionBar {
        id: webViewActionBar
        width: parent.width
        backButton.visible: true
        copyButton.visible: false
        backState: main.state
        actionBarTitle: main.dataSource
    }

        // TODO: resolve why doesn't work - i.e. draws over actionbar and is not flickable, at least WebView does not move content...
    /*Flickable {
        id: flickable
        anchors.top: webViewActionBar.bottom
        width: parent.width
        height: parent.height - webViewActionBar.height
        contentWidth: webView.width
        contentHeight: webView.height
        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds*/

        /*WebView {
        //Rectangle {
            anchors.top: webViewActionBar.bottom
            anchors.left: parent.left
            width: 1700
            height: parent.height
            //color: "green"
            url: main.dataSource
        }*/

        WebEngineView {
            id: webview
            url: "http://www.qt-project.org"
            anchors.fill: parent
        }
    /*}

    // Attach scrollbars to the right and bottom edges of the view.
     ScrollBar {
         id: horizontalScrollBar
         width: flickable.width-12; height: 12
         anchors.bottom: flickable.bottom
         opacity: 1
         orientation: Qt.Horizontal
         position: flickable.visibleArea.xPosition
         pageSize: flickable.visibleArea.widthRatio
     }*/
}
