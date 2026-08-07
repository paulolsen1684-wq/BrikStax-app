// android/app/src/main/kotlin/com/brikstax/brikstax/RandomSetWidgetProvider.kt
//
// Shows a random set from the user's collection with stats (pieces, retail,
// sealed value). Data is populated from Dart via HomeWidget SharedPreferences.
// Tapping opens the set detail screen.
package com.brikstax.brikstax

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class RandomSetWidgetProvider : AppWidgetProvider() {

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
        val views = RemoteViews(context.packageName, R.layout.random_set_widget)

        // Fetch random set data from SharedPreferences (populated by Dart)
        val setName = widgetData.getString("random_set_name", "No sets") ?: "No sets"
        val setNum = widgetData.getString("random_set_num", "") ?: ""
        val setYear = widgetData.getString("random_set_year", "") ?: ""
        val pieces = widgetData.getString("random_set_pieces", "—") ?: "—"
        val retail = widgetData.getString("random_set_retail", "—") ?: "—"
        val sealedValue = widgetData.getString("random_set_sealed", "—") ?: "—"

        // Update text views
        views.setTextViewText(R.id.widget_set_name, setName)
        views.setTextViewText(R.id.widget_set_meta,
            if (setNum.isNotEmpty()) "#$setNum" + (if (setYear.isNotEmpty()) " · $setYear" else "")
            else "—")
        views.setTextViewText(R.id.widget_retail, retail)
        views.setTextViewText(R.id.widget_value, sealedValue)

        // Tapping opens the set detail screen via deep link (brikstax://set/12345)
        val setDetailIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            action = Intent.ACTION_VIEW
            data = Uri.parse("brikstax://set/$setNum")
        }
        val setDetailPending = PendingIntent.getActivity(
            context, 0, setDetailIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, setDetailPending)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
