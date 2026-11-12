package io.github.jamesmangao.kumpleto

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget: the document that expires next, and how many are marked.
 *
 * The values are written from Dart by `lib/data/home_widget_sync.dart` into the
 * plugin's shared preferences file; this class only renders them, so there is no
 * data logic here and nothing to keep in sync by hand beyond the key names.
 *
 * Tapping anywhere on the widget opens the app.
 */
class ChecklistWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val title = widgetData.getString(KEY_TITLE, "").orEmpty()
        val subtitle = widgetData.getString(KEY_SUBTITLE, "").orEmpty()
        val summary = widgetData.getString(KEY_SUMMARY, "").orEmpty()

        appWidgetIds.forEach { appWidgetId ->
            // A RemoteViews tree can only be rearranged, never rebuilt, so empty
            // lines are hidden instead of removed.
            val views = RemoteViews(context.packageName, R.layout.kumpleto_widget).apply {
                setTextViewText(
                    R.id.widget_title,
                    if (title.isEmpty()) context.getString(R.string.widget_fallback_title) else title,
                )
                setTextViewText(R.id.widget_subtitle, subtitle)
                setViewVisibility(
                    R.id.widget_subtitle,
                    if (subtitle.isEmpty()) View.GONE else View.VISIBLE,
                )
                setTextViewText(R.id.widget_summary, summary)
                setViewVisibility(
                    R.id.widget_summary,
                    if (summary.isEmpty()) View.GONE else View.VISIBLE,
                )

                val launch = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    // The router does not know `home`, so a cold start from the
                    // widget lands on the normal first screen.
                    Uri.parse("kumpleto://home"),
                )
                setOnClickPendingIntent(R.id.widget_root, launch)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private companion object {
        // Must match the constants in lib/data/home_widget_sync.dart.
        const val KEY_TITLE = "kumpleto_next_title"
        const val KEY_SUBTITLE = "kumpleto_next_subtitle"
        const val KEY_SUMMARY = "kumpleto_summary"
    }
}
