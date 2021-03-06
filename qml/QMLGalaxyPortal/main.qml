import QtQuick 2.3
import QtQuick.Window 2.2
import Qt.labs.settings 1.0
import QtMultimedia 5.4

import "utils.js" as Utils

Rectangle {
    id: main
    width: Screen.width
    height: Screen.height

    // Title and ID of any selected history and job item.
    property string currentHistory: ""
    property string currentHistoryID: ""
    property string currentJobID: ""

    // String of fields displayed on the flipped job items to store between sessions
    property string fieldList: "update_time,data_type,misc_blurb"
    property bool advancedFields: true;

    // Instance list to store between sessions
    property string instanceList: ""
    property string instanceListKeys: ""

    // Galaxy API key for the dataSource used to retrieve data for user.
    property string dataSource: "https://usegalaxy.org"
    property string dataKey: ""
    property string username: ""
    property string passcode: ""
    property bool passcodeEnabled: false

    // Frequency of periodic polls (zero means no polling) - default is never (requiring user to enable).
    property int periodicPolls: 0

    property bool audioNotifications: true

    // User set size multiplier.
    property real scale: 1.0

    // List item in millimetre (pixelDensity is number of pixels per mm).
    property int mmItemHeight: Screen.pixelDensity * 10 * scale;
    property int mmItemMargin: Screen.pixelDensity * 3 * scale;

    property bool largeFonts: false;

    property bool wideScreen: width >= 1000 ? true : false

    // Save settings.
    Settings {
        // Galaxy API settings.
        property alias dataKey: main.dataKey
        property alias dataSource: main.dataSource
        property alias username: main.username

        // Passcode settings.
        property alias passcode: main.passcode
        property alias passcodeEnabled : main.passcodeEnabled

        // Job item flip fields.
        property alias fieldList : main.fieldList
        property alias advancedFields : main.advancedFields

        // Currently viewed history and job.
        property alias currentHistory : main.currentHistory
        property alias currentHistoryID : main.currentHistoryID
        property alias currentJobID : main.currentJobID

        // Polling frequency.
        property alias periodicPolls : main.periodicPolls

        // Instance List
        property alias instanceList : main.instanceList
        property alias instanceListKeys : main.instanceListKeys

        // Audio Alerts
        property alias audioNotifications : main.audioNotifications

        // User set size multiplier.
        property alias scale : main.scale

        // Larger font size.
        property alias largeFonts : main.largeFonts

        property alias state : main.state
    }

    // loader to spawn pages on top of list (e.g. for settings)
    Loader {  z: 1; id: mainLoader }

    // we only want to go to job when one is loaded
    function doJobTransition() {
        // Trigger the state change to show the jobs list view.
        if (main.state != "historyItems" && !wideScreen) {
            main.state = "historyItems";
        }
    }

    Audio {
        id: notificationSound
        source: "qrc:/resources/resources/sounds/ping.mp3"
    }
    Audio {
        id: alertSound
        source: "qrc:/resources/resources/sounds/alert.mp3"
    }

    // Properties to manage different device resolutions and screen sizes (handled in utils.js).
    readonly property var res: ["mdpi","hdpi","xhdpi", "xxhdpi"]
    readonly property int resIndex: Utils.getResolutionIndex(Screen.pixelDensity)
    readonly property string iconRoot: "qrc:/resources/resources/icons/" + res[resIndex] + "/"
    readonly property string imageRoot: "qrc:/resources/resources/images/" + res[resIndex] + "/"

    // Model for the list of histories (main list).
    JSONListModel {
        id: jsonHistoriesModel
        pollInterval: main.periodicPolls
        source: dataKey.length > 0 ? dataSource.length > 0 ? dataSource + "/api/histories?key=" + dataKey : "" : ""
    }
    
    // Model for list of histories (shared with user)
    JSONListModel {
        id: jsonSharedHistoriesModel
        pollInterval: main.periodicPolls
        source: dataKey.length > 0 ? dataSource.length > 0 ? dataSource + "/api/histories/shared_with_me?key=" + dataKey : "" : ""
    }

    // Model for the list of jobs in a selected history (source set when history selected).
    JSONListModel {
        id: jsonHistoryJobsModel
        pollInterval: main.periodicPolls
        source: main.currentHistoryID.length > 0 ? dataSource + "/api/histories/" + main.currentHistoryID + "/contents?key=" + dataKey : "";
    }

    JSONDataset {
        id: jsonHistoryJobContent
        pollInterval: main.periodicPolls
        source: main.currentHistoryID.length > 0 ? dataSource + "/api/histories/" + main.currentHistoryID + "/contents/datasets/" + main.currentJobID + "?key=" + dataKey : "";
    }

    PasscodeChallenge {
        id: challengeDialog
        visible: passcodeEnabled
        anchors.fill: parent
        onDone: {
          challengeDialog.visible = false;
        }
    }

    Column {
        visible: !challengeDialog.visible
        anchors.fill: parent
        ActionBar {
            id: mainActionbar
            width: main.width
            // Back button only visible when possible to navigate back.
            backButton.visible: main.state === "" ? false : true
            actionBarTitle: wideScreen ? (currentHistory + " - " + jsonHistoryJobsModel.count + " items") :
                                            (main.state === "" ? "Galaxy Portal - " + jsonHistoriesModel.count + " items" :  currentHistory + " - " + jsonHistoryJobsModel.count + " items")
        }
        // Empty list view.
        Welcome {
            width: main.width
            height: main.height - mainActionbar.height
            visible: (!challengeDialog.visible && jsonHistoriesModel.count === 0 && main.state === "")
        }
        Row {
            id: screenlayout
			Column {
				ListView {
					id: historyListView
					width: wideScreen ? main.width / 2 : main.width
					//height: ListView.count * itemHeight //main.height - mainActionbar.height
					model: jsonHistoriesModel.model
					delegate: HistoryDelegate {}
					clip: true
					boundsBehavior: Flickable.StopAtBounds

					
					onCountChanged: {
						// Calculate height of listview, so that it does not overlap the listview below
						var root = historyListView.visibleChildren[0];
						var listViewHeight = 0;	var listViewWidth = 0;

						// iterate over each delegate item to get their sizes
						for (var i = 0; i < root.visibleChildren.length; i++) {
							listViewHeight += root.visibleChildren[i].height
							listViewWidth  = Math.max(listViewWidth, root.visibleChildren[i].width)
						}

						historyListView.height = listViewHeight
					}
				}
				
				Text {
					x: 20;
					text: "<b>Histories shared with me</b>"
                    visible: (jsonSharedHistoriesModel.count > 0)
				}
				
				ListView {
					id: sharedHistoryListView
					width: wideScreen ? main.width / 2 : main.width
					height: main.height - mainActionbar.height - historyListView.height
					model: jsonSharedHistoriesModel.model
					delegate: HistoryDelegate {}
					clip: true
					boundsBehavior: Flickable.StopAtBounds
				}
			}
			
            ListView {
                id: jobListItems
                width: wideScreen ? main.width / 2 : main.width
                height: main.height - mainActionbar.height
                model: jsonHistoryJobsModel.model
                delegate: JobDelegate {}
                clip: true
                boundsBehavior: Flickable.StopAtBounds
            }
        }
    }
    transitions: Transition {
        NumberAnimation {
            target: screenlayout
            easing.type: Easing.OutCubic
            property: "x"
            duration: 1000.0
        }
    }
    states:
        State {
        name: "historyItems"
        PropertyChanges {
            target: screenlayout
            x: -main.width
        }
    }
}
