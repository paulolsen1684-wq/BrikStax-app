// android/app/src/main/kotlin/com/brikstax/brikstax/AvatarDenWidgetProvider.kt
//
// 2x2 Avatar/Den widget. Taps open the app to the main Dashboard.
// Displays a cached screenshot of the den if available, otherwise shows emoji fallback.
package com.brikstax.brikstax

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.widget.RemoteViews
import java.io.File

class AvatarDenWidgetProvider : AppWidgetProvider() {

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
        val views = RemoteViews(context.packageName, R.layout.avatar_den_widget)

        // Try to load cached den screenshot
        val cachedScreenshot = File(context.cacheDir, "den_screenshot.png")
        if (cachedScreenshot.exists()) {
            try {
                val bitmap = BitmapFactory.decodeFile(cachedScreenshot.absolutePath)
                if (bitmap != null) {
                    // Show the cached screenshot
                    views.setImageViewBitmap(R.id.den_image, bitmap)
                    views.setViewVisibility(R.id.den_image, android.view.View.VISIBLE)
                    views.setViewVisibility(R.id.fallback_preview, android.view.View.GONE)
                }
            } catch (e: Exception) {
                // Fall through to show fallback
            }
        }

        // Tapping opens the app normally, landing on Dashboard
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPending = PendingIntent.getActivity(
            context, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, openAppPending)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
