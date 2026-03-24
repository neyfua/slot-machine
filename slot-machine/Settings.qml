import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  spacing: Style.marginL

  property var pluginApi: null

  property bool editShowCredits: pluginApi?.pluginSettings?.showCredits !== undefined ? pluginApi.pluginSettings.showCredits : true
  property string editIconColor: pluginApi?.pluginSettings?.iconColor ?? pluginApi?.manifest?.metadata?.defaultSettings?.iconColor ?? "none"

  Component.onCompleted: {
    Logger.i("Slot Machine", "Settings UI loaded");
  }

  // Show credits toggle
  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("panel.settings.show-credits")
    description: pluginApi?.tr("panel.settings.show-credits-desc")
    checked: root.editShowCredits
    onToggled: checked => root.editShowCredits = checked
    defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.showCredits || true
  }

  // Change BarWidget icon's color
  NColorChoice {
    label: pluginApi?.tr("panel.settings.icon-color")
    description: pluginApi?.tr("panel.settings.icon-color-desc")
    currentKey: root.editIconColor
    onSelected: key => root.editIconColor = key
  }

  // IPC keybinding
  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: infoCol.implicitHeight + Style.marginM * 2
    color: Color.mSurfaceVariant
    radius: Style.radiusM

    ColumnLayout {
      id: infoCol
      anchors {
        fill: parent
        margins: Style.marginM
      }
      spacing: Style.marginS

      RowLayout {
        spacing: Style.marginS

        NIcon {
          icon: "info-circle"
          pointSize: Style.fontSizeS
          color: Color.mPrimary
        }

        NText {
          text: pluginApi?.tr("panel.settings.ipc-commands")
          pointSize: Style.fontSizeS
          font.weight: Font.Medium
          color: Color.mOnSurface
        }
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("panel.settings.ipc-toggle-panel") + " qs -c noctalia-shell ipc call plugin:slot-machine toggle"
        pointSize: Style.fontSizeXS
        font.family: Settings.data.ui.fontFixed
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WrapAnywhere
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("panel.settings.ipc-spin") + " qs -c noctalia-shell ipc call plugin:slot-machine spin"
        pointSize: Style.fontSizeXS
        font.family: Settings.data.ui.fontFixed
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WrapAnywhere
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("panel.settings.ipc-reset-credits") + " qs -c noctalia-shell ipc call plugin:slot-machine reset"
        pointSize: Style.fontSizeXS
        font.family: Settings.data.ui.fontFixed
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WrapAnywhere
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Slot Machine", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.pluginSettings.showCredits = root.editShowCredits;
    pluginApi.pluginSettings.iconColor = root.editIconColor;

    pluginApi.saveSettings();
    Logger.i("Slot Machine", "Settings saved successfully");
  }
}
