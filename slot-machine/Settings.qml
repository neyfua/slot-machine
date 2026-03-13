import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
		id: root

    property var pluginApi: null

		property var cfg: pluginApi?.pluginSettings || ({})
		property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

		property bool valueShowCredits: pluginApi?.pluginSettings?.showCredits ?? pluginApi?.manifest?.metadata?.defaultSettings?.showCredits ?? true
		property string valueIconColor: cfg.iconColor ?? defaults.iconColor

		spacing: Style.marginM

    Component.onCompleted: {
        Logger.i("Slot Machine", "Settings UI loaded");
    }

		readonly property var colorOptions: [
        { key: "Default", labelKey: "colors.default", color: Color.mOnSurface },
        { key: "Primary", labelKey: "colors.primary", color: Color.mPrimary },
        { key: "Secondary", labelKey: "colors.secondary", color: Color.mSecondary },
        { key: "Tertiary", labelKey: "colors.tertiary", color: Color.mTertiary },
				{ key: "Error", labelKey: "colors.error", color: Color.mError }
    ]

    // Show credits toggle
    NToggle {
        Layout.fillWidth: true
        label: "Show Credits"
        description: "Display credit count next to the icon on horizontal bars."
        checked: root.valueShowCredits
        onCheckedChanged: root.valueShowCredits = checked
    }

    // Separator
    NDivider {
			Layout.fillWidth: true
			Layout.topMargin: Style.marginS
			Layout.bottomMargin: Style.marginS
		}

    // Change BarWidget icon's color
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NComboBox {
            label: "Icon Color"
            description: "Color of the slot icon shown in the bar widget."
            model: Color.colorKeyModel
            currentKey: root.valueIconColor
            onSelected: key => root.valueIconColor = key
        }
    }

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("Slot Machine", "Cannot save settings: pluginApi is null");
            return;
        }

				pluginApi.pluginSettings.showCredits = root.valueShowCredits;
				pluginApi.pluginSettings.iconColor = root.valueIconColor;

				pluginApi.saveSettings();

        Logger.i("Slot Machine", "Settings saved successfully");
    }
}
