package com.moneycash.money_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

// Home screen widget 4x2 "Na rukah". The picture is drawn by the Flutter app
// (dark and light versions); here we only pick one and show it.
class BalanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val systemNight = (context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        // Тема приложения: system, light или dark (Flutter кладёт её сюда).
        // «Как в системе» следует за телефоном, остальное его не слушает.
        val night = when (widgetData.getString("theme_mode", "system")) {
            "dark" -> true
            "light" -> false
            else -> systemNight
        }
        val path = widgetData.getString(if (night) "balance_dark" else "balance_light", null)
        val bitmap = path?.let { BitmapFactory.decodeFile(it) }
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.balance_widget)
            if (bitmap != null) {
                views.setImageViewBitmap(R.id.widget_image, bitmap)
                views.setViewVisibility(R.id.widget_image, View.VISIBLE)
                views.setViewVisibility(R.id.widget_empty, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_image, View.GONE)
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            }
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse("tiyn://open")),
            )
            views.setOnClickPendingIntent(
                R.id.widget_add,
                HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse("tiyn://add")),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
