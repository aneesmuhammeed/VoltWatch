package com.gurucool.voltwatch

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class BatteryWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.battery_widget_layout)

            val batteryLevel = widgetData.getInt("battery_level", -1)
            val batteryState = widgetData.getString("battery_state", "VoltWatch")
            
            val tempBits = widgetData.getLong("temperature", -1L)
            var temperature = -1.0
            if (tempBits != -1L) {
                temperature = java.lang.Double.longBitsToDouble(tempBits)
            }

            if (batteryLevel != -1) {
                views.setTextViewText(R.id.widget_battery_level, "$batteryLevel%")
            } else {
                views.setTextViewText(R.id.widget_battery_level, "--%")
            }

            views.setTextViewText(R.id.widget_battery_status, batteryState)

            if (temperature > 0.0) {
                views.setTextViewText(R.id.widget_battery_temp, String.format("| %.1f°C", temperature))
            } else {
                views.setTextViewText(R.id.widget_battery_temp, "")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
