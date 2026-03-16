import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null

  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  // Height adapts per tab: Spin tab is compact, Paytable tab is taller
  property real contentPreferredWidth: 400 * Style.uiScaleRatio
  property real contentPreferredHeight: activeTab === 0 ? 450 * Style.uiScaleRatio : 640 * Style.uiScaleRatio

  anchors.fill: parent

  readonly property var machine: pluginApi?.mainInstance ?? null

  readonly property var symbols: machine?.symbols ?? []
  readonly property int reel0: machine?.reel0 ?? 0
  readonly property int reel1: machine?.reel1 ?? 0
  readonly property int reel2: machine?.reel2 ?? 0
  readonly property bool spinning: machine?.spinning ?? false
  readonly property string lastResult: machine?.lastResult ?? ""
  readonly property bool withClovers: machine?.withClovers ?? false
  readonly property int lastGain: machine?.lastGain ?? 0
  readonly property int spinSerial: machine?.spinSerial ?? 0
  readonly property int credits: machine?.credits ?? 0
  readonly property int totalWeight: machine?.totalWeight ?? 128

  // 0 = Spin, 1 = Paytable
  property int activeTab: 0

  property bool reel0Spinning: false
  property bool reel1Spinning: false
  property bool reel2Spinning: false

  onSpinningChanged: {
    if (spinning) {
      reel0Spinning = true;
      reel1Spinning = true;
      reel2Spinning = true;
      r0Stop.restart();
    }
  }

  Timer {
    id: r0Stop
    interval: 600
    onTriggered: {
      reel0Spinning = false;
      r1Stop.restart();
    }
  }
  Timer {
    id: r1Stop
    interval: 400
    onTriggered: {
      reel1Spinning = false;
      r2Stop.restart();
    }
  }
  Timer {
    id: r2Stop
    interval: 300
    onTriggered: {
      reel2Spinning = false;
    }
  }

  property bool flashActive: false
  property int flashCount: 0
  property bool jackpotActive: false

  onSpinSerialChanged: {
    if (lastGain > 0) {
      flashCount = 0;
      flashActive = true;
      flashTimer.restart();
      root.winDelayActive = true;
      winDelayTimer.restart();
    } else {
      flashActive = false;
    }
    if (lastResult === "jackpot") {
      jackpotActive = true;
      jackpotEndTimer.restart();
    } else {
      jackpotActive = false;
    }
  }

  Timer {
    id: flashTimer
    interval: 120
    repeat: true
    onTriggered: {
      root.flashActive = !root.flashActive;
      root.flashCount++;
      if (root.flashCount >= (root.lastResult === "jackpot" ? 16 : 8)) {
        stop();
        root.flashActive = false;
      }
    }
  }

  Timer {
    id: jackpotEndTimer
    interval: 3200
    onTriggered: {
      root.jackpotActive = false;
    }
  }

  property bool winDelayActive: false

  Timer {
    id: winDelayTimer
    interval: 1000
    repeat: false
    onTriggered: {
      root.winDelayActive = false;
    }
  }

  // Tab button component
  component TabButton: Rectangle {
    id: tabBtn

    property string icon: ""
    property string label: ""
    property bool isActive: false

    signal clicked

    implicitWidth: tabBtnContent.implicitWidth + Style.marginM * 2
    implicitHeight: tabBtnContent.implicitHeight + Style.marginS * 2

    color: isActive ? Color.mPrimary : (tabBtnMouse.containsMouse ? Color.mHover : "transparent")
    radius: Style.radiusS

    Behavior on color {
      ColorAnimation {
        duration: 120
      }
    }

    RowLayout {
      id: tabBtnContent
      anchors.centerIn: parent
      spacing: Style.marginS

      NIcon {
        icon: tabBtn.icon
        color: tabBtn.isActive ? Color.mOnPrimary : Color.mOnSurfaceVariant
        pointSize: Style.fontSizeM
      }

      NText {
        text: tabBtn.label
        color: tabBtn.isActive ? Color.mOnPrimary : Color.mOnSurfaceVariant
        pointSize: Style.fontSizeS
        font.weight: tabBtn.isActive ? Font.Medium : Font.Normal
      }
    }

    MouseArea {
      id: tabBtnMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: tabBtn.clicked()
    }
  }

  // Panel
  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    Rectangle {
      anchors.fill: parent
      color: Color.mSurface
      radius: Style.radiusL
      border.color: Style.capsuleBorderColor
      border.width: Style.capsuleBorderWidth
      clip: true

      ColumnLayout {
        anchors {
          fill: parent
          margins: Style.marginM
        }
        spacing: 0

        // Header
        RowLayout {
          Layout.fillWidth: true
          Layout.topMargin: Style.marginXS
          Layout.bottomMargin: Style.marginM

          NIcon {
            icon: "brand-mastercard"
            color: Color.mPrimary
            pointSize: Style.fontSizeL
          }

          NText {
            text: "Slot Machine"
            pointSize: Style.fontSizeL
            font.weight: Font.Bold
            color: Color.mOnSurface
            Layout.fillWidth: true
            leftPadding: Style.marginS
          }

          NIconButton {
            icon: "x"
            onClicked: {
              if (pluginApi)
                pluginApi.closePanel(pluginApi.panelOpenScreen);
            }
          }
        }

        // Credits bar
        Rectangle {
          Layout.fillWidth: true
          Layout.bottomMargin: Style.marginM
          height: 40 * Style.uiScaleRatio
          color: Color.mSurfaceVariant
          radius: Style.radiusM

          RowLayout {
            anchors {
              fill: parent
              margins: Style.marginM
            }
            spacing: Style.marginS

            NIcon {
              icon: "coin"
              color: Color.mPrimary
            }

            NText {
              text: "Credits: " + root.credits
              color: Color.mOnSurface
              pointSize: Style.fontSizeM
              font.weight: Font.Medium
              Layout.fillWidth: true
            }

            NText {
              text: (root.machine?.totalSpins ?? 0) + " spins"
              color: Color.mOnSurfaceVariant
              pointSize: Style.fontSizeS
            }
          }
        }

        // Tab bar
        Rectangle {
          Layout.fillWidth: true
          Layout.bottomMargin: Style.marginM
          implicitHeight: tabRow.implicitHeight + Style.marginS * 2
          color: Color.mSurfaceVariant
          radius: Style.radiusM

          RowLayout {
            id: tabRow
            anchors.centerIn: parent
            spacing: Style.marginS

            TabButton {
              icon: "play-card-7"
              label: "Spin"
              isActive: root.activeTab === 0
              onClicked: root.activeTab = 0
            }

            TabButton {
              icon: "list"
              label: "Paytable"
              isActive: root.activeTab === 1
              onClicked: root.activeTab = 1
            }
          }
        }

        // Tab content
        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          // Spin tab
          ColumnLayout {
            anchors.fill: parent
            spacing: Style.marginM
            visible: root.activeTab === 0

            Rectangle {
              Layout.fillWidth: true
              Layout.fillHeight: true
              radius: Style.radiusL
              clip: true

              color: {
                if (!root.flashActive)
                  return Color.mSurfaceVariant;
                if (root.lastResult === "jackpot")
                  return "#FFD700";
                if (root.lastGain > 0)
                  return root.withClovers ? "lightgreen" : Color.mPrimary;
                if (root.lastGain < 0)
                  return "indianred";
                return Color.mSurfaceVariant;
              }
              Behavior on color {
                ColorAnimation {
                  duration: 60
                }
              }

              border.color: root.jackpotActive ? "#FFD700" : Style.capsuleBorderColor
              border.width: root.jackpotActive ? 3 : Style.capsuleBorderWidth

              RowLayout {
                anchors.centerIn: parent
                spacing: Style.marginL

                ReelColumn {
                  reelIndex: 0
                  symbolIndex: root.reel0
                  symbols: root.symbols
                  isSpinning: root.reel0Spinning
                  isWin: root.lastGain > 0
                  flashActive: root.flashActive
                }
                ReelColumn {
                  reelIndex: 1
                  symbolIndex: root.reel1
                  symbols: root.symbols
                  isSpinning: root.reel1Spinning
                  isWin: root.lastGain > 0
                  flashActive: root.flashActive
                }
                ReelColumn {
                  reelIndex: 2
                  symbolIndex: root.reel2
                  symbols: root.symbols
                  isSpinning: root.reel2Spinning
                  isWin: root.lastGain > 0
                  flashActive: root.flashActive
                }
              }
            }

            NText {
              Layout.alignment: Qt.AlignHCenter
              text: {
                var credits = root.lastGain + " credits!";
                if (root.spinning)
                    return "Spinning...";
                if (root.lastResult === "jackpot")
                    return "JACKPOT! +" + credits;

                if (root.lastResult === "win" && root.withClovers)
                    return "Lucky winner! +" + credits;
                if (root.lastResult === "win")
                    return "Winner! +" + credits;

                if (root.lastResult === "smallwin" && root.withClovers)
                    return "Lucky you! +" + credits;
                if (root.lastResult === "smallwin")
                    return "Two of a kind! +" + credits;

                if (root.lastResult === "poowin")
                    return "Poo Poo Poo! +" + credits;

                if (root.lastResult === "bombloss")
                  return "Boom Boom Pow! " + credits;

                if (root.lastResult === "loss") {
                  if (root.lastGain < 0)
                    return "Boom ! " + credits
                  else if (root.withClovers)
                    return "Balanced as all things should be!"
                  else
                    return "No match. Try again!";
                }
                return "Press SPIN to play";
              }
              color: {
                if (root.spinning)
                    return Color.mOnSurfaceVariant
                if (root.lastResult === "jackpot")
                  return "#FFD700";
                if (root.withClovers && root.lastGain > 0)
                  return "lightgreen";
                if (root.lastGain > 0)
                  return Color.mPrimary;
                if (root.lastGain < 0)
                  return "indianred";
                return Color.mOnSurfaceVariant;
              }
              pointSize: root.lastResult === "jackpot" ? Style.fontSizeL : Style.fontSizeM
              font.weight: root.lastResult === "jackpot" ? Font.Bold : Font.Normal
            }

            NButton {
              Layout.fillWidth: true
              text: {
                if (root.credits <= 0)
                  return "No credits - hit Reset Credits to keep playing!";
                if (root.spinning)
                  return "Spinning...";
                return "SPIN  (-1 credit)";
              }
              backgroundColor: (!root.spinning && !root.winDelayActive && root.credits > 0) ? Color.mPrimary : Color.mSurfaceVariant
              textColor: (!root.spinning && !root.winDelayActive && root.credits > 0) ? Color.mOnPrimary : Color.mOnSurfaceVariant
              enabled: !root.spinning && !root.winDelayActive && root.credits > 0
              onClicked: {
                if (root.machine)
                  root.machine.spin();
              }
            }

            NButton {
              Layout.fillWidth: true
              text: "Reset Credits"
              enabled: root.credits <= 0 && !root.reel2Spinning && !root.spinning
              backgroundColor: (root.credits <= 0 && !root.reel2Spinning && !root.spinning) ? Color.mPrimary : Color.mSurfaceVariant
              textColor: (root.credits <= 0 && !root.reel2Spinning && !root.spinning) ? Color.mOnPrimary : Color.mOnSurfaceVariant
              onClicked: {
                if (root.machine)
                  root.machine.resetCredits();
              }
            }
          }

          // Paytable tab
          ColumnLayout {
            anchors.fill: parent
            spacing: Style.marginM
            visible: root.activeTab === 1

            // Payout rules
            Rectangle {
                Layout.fillWidth: true
                color: Color.mSurfaceVariant
                radius: Style.radiusM
                implicitHeight: payoutRules.implicitHeight + Style.marginM * 2

                RowLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: Style.marginM
                    }
                    spacing: Style.marginL
                    ColumnLayout {
                        id: payoutRules
                        spacing: Style.marginS
                        Layout.alignment: Qt.AlignTop

                        NText {
                            text: "Symbol values"
                            pointSize: Style.fontSizeS
                            font.weight: Font.Bold
                            color: Color.mOnSurface
                            bottomPadding: 2
                        }

                        Repeater {
                            model: root.symbols

                            RowLayout {
                                width: symbolList.width
                                spacing: Style.marginS

                                NIcon {
                                    icon: modelData.icon
                                    pointSize: Style.fontSizeM
                                    color: modelData?.color ?? Color.mOnSurface
                                }

                                NText {
                                    text: modelData.label
                                    pointSize: Style.fontSizeS
                                    color: modelData?.color ?? Color.mOnSurface
                                    font.weight: modelData.label === "7" ? Font.Bold : Font.Normal
                                    Layout.fillWidth: true
                                }

                                NText {
                                    text: modelData.gain
                                    pointSize: Style.fontSizeS
                                    color: modelData?.color ?? Color.mOnSurface
                                    font.weight: modelData.label === "7" ? Font.Bold : Font.Normal
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.preferredWidth: 25 * Style.uiScaleRatio
                                }
                            }
                        }
                    }
                    NDivider {
                        vertical: true
                        Layout.fillHeight: true
                    }
                    GridLayout {
                        id: payoutRules2
                        rows: -1
                        columns: 2
                        rowSpacing: Style.marginS
                        Layout.alignment: Qt.AlignTop

                        NText {
                            text: "Combinations"
                            pointSize: Style.fontSizeS
                            font.weight: Font.Bold
                            color: Color.mOnSurface
                            bottomPadding: 2
                            Layout.fillWidth: true
                        }

                        NText {
                            text: "Value"
                            pointSize: Style.fontSizeS
                            font.weight: Font.Bold
                            color: Color.mOnSurface
                            bottomPadding: 2
                        }
                        NText {
                            text: "777"
                            color: "#FFD700"
                            pointSize: Style.fontSizeS
                            font.weight: Font.Bold
                        }
                        NText {
                            text: "77"
                            color: "#FFD700"
                            pointSize: Style.fontSizeS
                            font.weight: Font.Bold
                        }
                        NText {
                            text: "Triple Clover"
                            color: "lightgreen"
                            pointSize: Style.fontSizeS
                        }
                        NText {
                            text: "Value * 5"
                            color: "lightgreen"
                            pointSize: Style.fontSizeS
                        }
                        NText {
                            text: "Triple Bomb"
                            color: "indianred"
                            pointSize: Style.fontSizeS
                        }
                        NText {
                            text: "Value * 5"
                            color: "indianred"
                            pointSize: Style.fontSizeS
                        }
                        NText {
                            text: "Three of a kind"
                            color: Color.mPrimary
                            pointSize: Style.fontSizeS
                        }
                        NText {
                            text: "Value * 2"
                            color: Color.mPrimary
                            pointSize: Style.fontSizeS
                        }
                        NText {
                            text: "Two of a kind"
                            color: Color.mOnSurface
                            pointSize: Style.fontSizeS
                        }
                        NText {
                            text: "Value"
                            color: Color.mOnSurface
                            pointSize: Style.fontSizeS
                        }
                        NText {
                            text: "No match"
                            color: Color.mOnSurfaceVariant
                            pointSize: Style.fontSizeS
                        }
                        NText {
                            text: "Lose (-1 credit)"
                            color: Color.mOnSurfaceVariant
                            pointSize: Style.fontSizeS
                        }
                        NText {
                            text: "Clover"
                            color: "lightgreen"
                            pointSize: Style.fontSizeS
                        }
                        NText {
                            text: "Joker + Value"
                            color: "lightgreen"
														pointSize: Style.fontSizeS
                        }
                        NText {
                            text: "Any bomb"
                            color: "indianred"
                            pointSize: Style.fontSizeS
                        }
                        NText {
                            text: "Lose value"
                            color: "indianred"
                            pointSize: Style.fontSizeS
                        }
                    }
                }
            }

            // Symbol list (scrollable)
            Rectangle {
              Layout.fillWidth: true
              Layout.fillHeight: true
              color: Color.mSurfaceVariant
              radius: Style.radiusM
              clip: true

              Flickable {
                anchors {
                  fill: parent
                  margins: Style.marginM
                }
                contentHeight: symbolList.implicitHeight
                clip: true

                ColumnLayout {
                  id: symbolList
                  width: parent.width
                  spacing: Style.marginXS

                  NText {
                    text: "All symbols"
                    pointSize: Style.fontSizeS
                    font.weight: Font.Bold
                    color: Color.mOnSurface
                    bottomPadding: 2
                  }

                  Repeater {
                    model: root.symbols

                    RowLayout {
                      width: symbolList.width
                      spacing: Style.marginS

                      NIcon {
                        icon: modelData.icon
                        pointSize: Style.fontSizeM
                        color: modelData?.color ?? Color.mOnSurface
                      }

                      NText {
                        text: modelData.label
                        pointSize: Style.fontSizeS
                        color: modelData?.color ?? Color.mOnSurface
                        font.weight: modelData.label === "7" ? Font.Bold : Font.Normal
                        Layout.fillWidth: true
                      }

                      Rectangle {
                        width: 150 * Style.uiScaleRatio
                        height: 5 * Style.uiScaleRatio
                        radius: 3
                        color: Color.mSurface

                        Rectangle {
                          width: parent.width * (modelData.weight / root.totalWeight)
                          height: parent.height
                          radius: parent.radius
                          color: modelData?.color ?? Color.mPrimary
                        }
                      }

                      NText {
                        text: (modelData.weight / root.totalWeight * 100).toFixed(1) + "%"
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant

                        Layout.preferredWidth: 40 * Style.uiScaleRatio
                        horizontalAlignment: Text.AlignRight
                        font.family: "monospace"
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    // Jackpot coin rain
    Item {
      anchors.fill: parent
      z: 10
      visible: root.jackpotActive
      clip: true

      Repeater {
        model: 30
        CoinParticle {
          parentWidth: parent.width
          parentHeight: parent.height
        }
      }
    }
  }
}
