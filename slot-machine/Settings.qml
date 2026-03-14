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
        label: "Show Credits"
        description: "Display credit count next to the icon on horizontal bars."
        checked: root.editShowCredits
        onToggled: checked => root.editShowCredits = checked
        defaultValue: pluginApi?.manifest?.metadata?.defaultSettings?.editShowCredits || true
    }

    // Separator
    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginS
        Layout.bottomMargin: Style.marginS
    }

    // Change BarWidget icon's color
    NColorChoice {
        label: "Icon Color"
        description: "Color of the slot icon shown in the bar widget."
        currentKey: root.editIconColor
        onSelected: key => root.editIconColor = key
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
