import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  // Per-screen bar properties (for multi-monitor and vertical bar support)
  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  // Content dimensions (visual capsule size)
  readonly property real contentWidth: row.implicitWidth + Style.marginM * 2
  readonly property real contentHeight: capsuleHeight

  // Widget dimensions (extends to full bar height for better click area)
  implicitWidth: contentWidth
  implicitHeight: contentHeight

  // Machine shorthand
  readonly property var machine: pluginApi?.mainInstance ?? null
  readonly property bool spinning: machine?.spinning ?? false
  readonly property int credits: machine?.credits ?? 0
  readonly property var lastResult: machine?.lastResult ?? SPIN
  readonly property int lastGain: machine?.lastGain ?? 0
  readonly property int spinSerial: machine?.spinSerial ?? 0
  readonly property int centerReel: machine?.reel1 ?? 0
  readonly property bool withClovers: machine?.withClovers ?? false

  // Plugin settings
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property string iconColorKey: cfg.iconColor ?? defaults.iconColor ?? "none"
  readonly property bool showCredits: cfg.showCredits ?? defaults.showCredits ?? true
  readonly property color iconColor: Color.resolveColorKey(iconColorKey)

  // Pulse animation while spinning
  property real pulseOpacity: 1.0

  SequentialAnimation on pulseOpacity {
    running: root.spinning
    loops: Animation.Infinite
    NumberAnimation {
      to: 0.4
      duration: 300
    }
    NumberAnimation {
      to: 1.0
      duration: 300
    }
    onStopped: root.pulseOpacity = 1.0
  }

  // Win flash triggered by spinSerial (always fires)
  property bool winFlash: false
  property int winFlashCount: 0

  onSpinSerialChanged: {
    if (lastGain > 0) {
      winFlashCount = 0;
      winFlash = false;
      winFlashTimer.restart();
    } else {
      winFlashTimer.stop();
      winFlash = false;
    }
  }

  Connections {
    target: root.machine
    function onReplayFlash() {
      if (root.lastGain <= 0)
        return;
      root.winFlashCount = 0;
      root.winFlash = false;
      winFlashTimer.restart();
    }
  }

  Timer {
    id: winFlashTimer
    interval: 150
    repeat: true
    onTriggered: {
      root.winFlash = !root.winFlash;
      root.winFlashCount++;
      var limit = root.lastResult === "jackpot" ? 10 : 6;
      if (root.winFlashCount >= limit) {
        stop();
        root.winFlash = false;
      }
    }
  }

  // Visual capsule
  Rectangle {
    id: visualCapsule

    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)

    width: root.contentWidth
    height: root.contentHeight

    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    color: {
      if (root.winFlash && (root.lastResult === "jackpot" || root.lastResult === "twoseven"))
        return "#FFD700";
      if (root.winFlash && (root.lastResult === "diamondwin" || root.lastResult === "diamondsmallwin"))
        return "lightblue";
      if (root.winFlash && (root.lastResult === "win" || root.lastResult === "smallwin"))
        return root.withClovers ? "lightgreen" : Color.mPrimary;
      if (mouseArea.containsMouse)
        return Color.mHover;
      return Style.capsuleColor;
    }

    Behavior on color {
      ColorAnimation {
        duration: 80
      }
    }

    RowLayout {
      id: row
      anchors.centerIn: parent
      spacing: Style.marginS
      opacity: root.pulseOpacity

      NIcon {
        icon: {
          var syms = root.machine?.symbols;
          if (!syms || syms.length === 0)
            return "brand-mastercard";
          return syms[root.centerReel]?.icon ?? "brand-mastercard";
        }
        color: {
          if (root.winFlash)
            return Color.mOnPrimary;
          return root.machine?.symbols[root.centerReel]?.color ?? root.iconColor;
        }
        pointSize: root.barFontSize
      }

      NText {
        visible: !root.isBarVertical && root.showCredits
        text: root.credits + "cr"
        color: {
          if (root.winFlash)
            return Color.mOnPrimary;
          return Color.mOnSurface;
        }
        pointSize: root.barFontSize
        font.weight: Font.Medium
      }
    }
  }

  // MouseArea
  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: mouse => {
                 if (mouse.button === Qt.LeftButton) {
                   if (pluginApi)
                   pluginApi.openPanel(root.screen, root);
                 } else if (mouse.button === Qt.RightButton) {
                   PanelService.showContextMenu(contextMenu, root, screen);
                 }
               }

    onEntered: {
      TooltipService.show(root, root.credits + " credits", BarService.getTooltipDirection());
    }
    onExited: {
      TooltipService.hide();
    }
  }

  // Context menu
  NPopupContextMenu {
    id: contextMenu
    model: [
      {
        label: "Spin",
        action: "spin",
        icon: "refresh"
      },
      {
        label: "Reset Credits",
        action: "reset",
        icon: "coin",
        disabled: root.credits > 0
      },
      {
        label: "Settings",
        action: "settings",
        icon: "settings"
      }
    ]
    onTriggered: action => {
                   contextMenu.close();
                   PanelService.closeContextMenu(screen);
                   if (action === "spin") {
                     if (pluginApi) {
                       if (pluginApi.panelOpenScreen) {
                         // Spin if panel is already open
                         if (root.machine)
                         root.machine.spin();
                       } else {
                         // Open panel and spin if panel weren't opened with a delay
                         pluginApi.openPanel(root.screen, root);
                         contextSpinDelay.restart();
                       }
                     }
                   } else if (action === "reset") {
                     if (root.machine)
                     root.machine.resetCredits();
                   } else if (action === "settings") {
                     BarService.openPluginSettings(screen, pluginApi.manifest);
                   }
                 }
  }

  // Delay spin so panel has time to open first
  Timer {
    id: contextSpinDelay
    interval: 350
    repeat: false
    onTriggered: {
      if (root.machine)
        root.machine.spin();
    }
  }

  Component.onCompleted: {
    Logger.i("SlotMachine", "BarWidget loaded on screen:", screenName);
  }
}
