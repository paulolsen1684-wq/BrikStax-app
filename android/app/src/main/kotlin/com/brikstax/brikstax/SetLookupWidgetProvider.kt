// android/app/src/main/kotlin/com/brikstax/brikstax/SetLookupWidgetProvider.kt
//
// 2x2 Set Lookup widget. Tapping opens the app straight to SetLookupScreen
// via the brikstax://lookup deep link that the Dart side reads on launch.
package com.brikstax.brikstax

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class SetLookupWidgetProvider : AppWidgetProvider() {

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
        val views = RemoteViews(context.packageName, R.layout.set_lookup_widget)

        // Tapping anywhere on the widget opens the app with the lookup deep link
        val lookupIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            action = Intent.ACTION_VIEW
            data = Uri.parse("brikstax://lookup")
        }
        val lookupPending = PendingIntent.getActivity(
            context, 0, lookupIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, lookupPending)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
