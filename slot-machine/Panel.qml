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
  property real contentPreferredHeight: activeTab === 0 ? 450 * Style.uiScaleRatio : 621 * Style.uiScaleRatio

  anchors.fill: parent

  readonly property var machine: pluginApi?.mainInstance ?? null

  readonly property var symbols: machine?.symbols ?? []
  readonly property int reel0: machine?.reel0 ?? 0
  readonly property int reel1: machine?.reel1 ?? 0
  readonly property int reel2: machine?.reel2 ?? 0
  readonly property bool spinning: machine?.spinning ?? false
  readonly property string lastResult: machine?.lastResult ?? ""
  readonly property bool withClovers: machine?.withClovers ?? false
  readonly property bool withBombs: machine?.withBombs ?? false
  readonly property int cloverCount: {
    var count = 0;
    var syms = root.symbols;
    if (syms.length > 0) {
      if (syms[root.reel0]?.label === "Clover") count++;
      if (syms[root.reel1]?.label === "Clover") count++;
      if (syms[root.reel2]?.label === "Clover") count++;
    }
    return count;
  }
  readonly property int lastGain: machine?.lastGain ?? 0
  readonly property int credits: machine?.credits ?? 0
  readonly property int totalWeight: machine?.totalWeight ?? 128
  readonly property bool winDelayActive: machine?.winDelayActive ?? false

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
    }
  }

  property bool flashActive: false
  property int flashCount: 0
  property bool jackpotActive: false

  function doFlash() {
    flashTimer.stop();
    flashActive = false;
    flashCount = 0;
    jackpotActive = false;
    jackpotEndTimer.stop();
    if (lastGain > 0) {
      flashActive = true;
      flashTimer.restart();
    }
    if (lastResult === "jackpot") {
      jackpotActive = true;
      jackpotEndTimer.restart();
    }
  }

  Connections {
    target: root.machine
    function onReel0Landed() {
      root.reel0Spinning = false;
    }
    function onReel1Landed() {
      root.reel1Spinning = false;
    }
    function onReel2Landed() {
      root.reel2Spinning = false;
    }
    function onReelsLanded() {
      if (root.machine?.silentSpin)
        return;
      root.doFlash();
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
            text: pluginApi?.tr("panel.slot-machine")
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
							text: pluginApi?.tr("panel.Credits") + ": " + root.credits
              color: Color.mOnSurface
              pointSize: Style.fontSizeM
              font.weight: Font.Medium
              Layout.fillWidth: true
            }

            NText {
              text: (root.machine?.totalSpins ?? 0) + " " + pluginApi?.tr("panel.spins")
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
              label: pluginApi?.tr("panel.tab-spin.Spin")
              isActive: root.activeTab === 0
              onClicked: root.activeTab = 0
            }

            TabButton {
              icon: "list"
              label: pluginApi?.tr("panel.tab-paytable.Paytable")
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
                if (root.lastResult === "jackpot" || root.lastResult === "twoseven")
                  return "#FFD700";
                if (root.lastResult === "diamondwin" || root.lastResult === "diamondsmallwin")
                  return "lightblue";
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
                var credits = root.lastGain + " " + pluginApi?.tr("panel.tab-spin.credits") + "!";
                if (root.spinning)
                  return pluginApi?.tr("panel.tab-spin.Spinning") + "...";

                if (root.lastResult === "twoseven")
                  return pluginApi?.tr("panel.tab-spin.glory") + "! +" + credits;
                if (root.lastResult === "jackpot")
                  return pluginApi?.tr("panel.tab-spin.JACKPOT") + "! +" + credits;

                if (root.lastResult === "win" && root.withClovers && root.cloverCount === 3)
                  return pluginApi?.tr("panel.tab-spin.lucky-winner") + "! +" + credits;
                if (root.lastResult === "win" && root.withClovers && root.cloverCount === 2)
                  return pluginApi?.tr("panel.tab-spin.winner") + "! +" + credits;
                if (root.lastResult === "win" && root.withClovers && root.cloverCount === 1)
                  return pluginApi?.tr("panel.tab-spin.lucky-you") + "! +" + credits;
                if (root.lastResult === "win")
                  return pluginApi?.tr("panel.tab-spin.three-of-a-kind") + "! +" + credits;

                if (root.lastResult === "diamondwin")
                  return pluginApi?.tr("panel.tab-spin.triple-diamonds") + "! +" + credits;
                if (root.lastResult === "diamondsmallwin")
                  return pluginApi?.tr("panel.tab-spin.double-diamonds") + "! +" + credits;

                if (root.lastResult === "smallwin" && root.withClovers || root.lastResult === "twopoo" && root.withClovers)
                  return pluginApi?.tr("panel.tab-spin.lucky-you") + "! +" + credits;
                if (root.lastResult === "smallwin")
                  return pluginApi?.tr("panel.tab-spin.two-of-a-kind") + "! +" + credits;

                if (root.lastResult === "twopoo" && !root.withBombs && !root.withClovers)
								return pluginApi?.tr("panel.tab-spin.twopoopoo") + "! +" + credits;
                if (root.lastResult === "twopoo" && root.withBombs)
                  return pluginApi?.tr("panel.tab-spin.twopoobomb") + "! " + credits;
                if (root.lastResult === "poowin")
                  return pluginApi?.tr("panel.tab-spin.poopoopoo") + "! +" + credits;

								if (root.lastResult === "brokebombloss")
									return pluginApi?.tr("panel.tab-spin.bombloss") + "! " + pluginApi?.tr("panel.tab-spin.brokebombloss") + "!";
                if (root.lastResult === "twobombbroke")
                  return pluginApi?.tr("panel.tab-spin.loss") + "! " + pluginApi?.tr("panel.tab-spin.loss") + "! " + pluginApi?.tr("panel.tab-spin.twobombbroke") + "!";
                if (root.lastResult === "bombloss")
                  return pluginApi?.tr("panel.tab-spin.bombloss") + "! " + credits;

                if (root.lastResult === "loss") {
                  if (root.lastGain < 0)
									return pluginApi?.tr("panel.tab-spin.loss") + "! " + credits;
                  else if (root.withClovers)
                    return pluginApi?.tr("panel.tab-spin.balanced") + "!";
                  else
                    return pluginApi?.tr("panel.tab-spin.no-match-try-again") + "!";
                }
                return pluginApi?.tr("panel.tab-spin.press-spin");
              }
              color: {
                if (root.spinning)
                  return Color.mOnSurfaceVariant;
                if (root.lastResult === "jackpot" || root.lastResult === "twoseven")
                  return "#FFD700";
                if (root.lastResult === "diamondwin" || root.lastResult === "diamondsmallwin")
                  return "lightblue";
                if (root.withClovers && root.lastGain > 0)
                  return "lightgreen";
                if (root.lastGain > 0)
                  return Color.mPrimary;
                if (root.lastGain < 0)
                  return "indianred";
                if (root.lastResult === "bombloss" || root.lastResult === "brokebombloss" || root.lastResult === "twobombbroke")
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
                  return pluginApi?.tr("panel.tab-spin.no-credits") + "!";
                if (root.spinning)
                  return pluginApi?.tr("panel.tab-spin.Spinning") + "...";
                return pluginApi?.tr("panel.tab-spin.minus-credits");
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
              text: pluginApi?.tr("panel.tab-spin.reset-credits")
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
                    text: pluginApi?.tr("panel.tab-paytable.symbol-values")
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
                    text: pluginApi?.tr("panel.tab-paytable.combinations")
                    pointSize: Style.fontSizeS
                    font.weight: Font.Bold
                    color: Color.mOnSurface
                    bottomPadding: 2
                    Layout.fillWidth: true
                  }

                  NText {
                    text: pluginApi?.tr("panel.tab-paytable.value")
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
                    text: pluginApi?.tr("panel.tab-paytable.triple-clovers")
                    color: "lightgreen"
                    pointSize: Style.fontSizeS
                  }
                  NText {
                    text: pluginApi?.tr("panel.tab-paytable.value-x-5")
                    color: "lightgreen"
                    pointSize: Style.fontSizeS
                  }
                  NText {
                    text: pluginApi?.tr("panel.tab-paytable.triple-bombs")
                    color: "indianred"
                    pointSize: Style.fontSizeS
                  }
                  NText {
                    text: pluginApi?.tr("panel.tab-paytable.value-x-5")
                    color: "indianred"
                    pointSize: Style.fontSizeS
                  }
                  NText {
                    text: pluginApi?.tr("panel.tab-spin.three-of-a-kind")
                    color: Color.mPrimary
                    pointSize: Style.fontSizeS
                  }
                  NText {
                    text: pluginApi?.tr("panel.tab-paytable.value-x-2")
                    color: Color.mPrimary
                    pointSize: Style.fontSizeS
                  }
                  NText {
                    text: pluginApi?.tr("panel.tab-spin.two-of-a-kind")
                    color: Color.mOnSurface
                    pointSize: Style.fontSizeS
                  }
                  NText {
                    text: pluginApi?.tr("panel.tab-paytable.value")
                    color: Color.mOnSurface
                    pointSize: Style.fontSizeS
                  }
                  NText {
                    text: pluginApi?.tr("panel.tab-paytable.no-match")
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                  }
                  NText {
                    text: pluginApi?.tr("panel.tab-paytable.lose")
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                  }
                  NText {
                    text: pluginApi?.tr("panel.tab-paytable.clover")
                    color: "lightgreen"
                    pointSize: Style.fontSizeS
                  }
                  NText {
                    text: pluginApi?.tr("panel.tab-paytable.joker")
                    color: "lightgreen"
                    pointSize: Style.fontSizeS
                  }
                  NText {
                    text: pluginApi?.tr("panel.tab-paytable.any-bomb")
                    color: "indianred"
                    pointSize: Style.fontSizeS
                  }
                  NText {
                    text: pluginApi?.tr("panel.tab-paytable.lose-value")
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
                    text: pluginApi?.tr("panel.tab-paytable.all-symbols")
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
