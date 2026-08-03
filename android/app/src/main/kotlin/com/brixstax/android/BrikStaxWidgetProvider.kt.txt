// android/app/src/main/kotlin/com/brikstax/brikstax/BrikStaxWidgetProvider.kt
//
// Reads values written by the Dart side (via the home_widget package, which
// stores them in Android's SharedPreferences under a well-known key) and
// renders them into the widget's TextViews. Also wires up two tap targets:
// the whole widget body opens the app to Dashboard, and the Scan button
// opens straight to the Scanner screen via a custom URI the Dart side reads
// on launch.
package com.brikstax.brikstax

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class BrikStaxWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val views = RemoteViews(context.packageName, R.layout.brikstax_widget)

        val setCount = widgetData.getString("set_count", "0") ?: "0"
        val portfolioValue = widgetData.getString("portfolio_value", "\$0") ?: "\$0"

        views.setTextViewText(R.id.widget_set_count, setCount)
        views.setTextViewText(R.id.widget_portfolio_value, portfolioValue)

        // Tapping the widget body (outside the Scan button) opens the app
        // normally, landing on Dashboard.
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPending = PendingIntent.getActivity(
            context, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_title, openAppPending)
        views.setOnClickPendingIntent(R.id.widget_set_count, openAppPending)
        views.setOnClickPendingIntent(R.id.widget_portfolio_value, openAppPending)

        // Tapping "Scan" opens the app with a deep-link URI that the Dart
        // side checks on launch (see widget_service.dart /
        // MainActivity handling) and routes straight to ScannerScreen.
        val scanIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            action = Intent.ACTION_VIEW
            data = Uri.parse("brikstax://scan")
        }
        val scanPending = PendingIntent.getActivity(
            context, 1, scanIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_scan_button, scanPending)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}