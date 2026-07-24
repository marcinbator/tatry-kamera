package pl.bator.tatry_kamera

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.widget.RemoteViews
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

class ToprCamWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val DEFAULT_CAM_CODE = "mors"
        private const val DEFAULT_CAM_NAME = "Morskie Oko: Rysy"
        private val executor = Executors.newCachedThreadPool()

        private fun pendingIntentFlags(): Int {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
        }

        private fun buildBaseViews(context: Context, camName: String): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.tatry_kamera_widget)
            views.setTextViewText(R.id.widget_cam_name, camName)

            val launchIntent =
                context.packageManager.getLaunchIntentForPackage(context.packageName)
                    ?: Intent()
            val pendingIntent = PendingIntent.getActivity(
                context, 0, launchIntent, pendingIntentFlags()
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            return views
        }

        private fun refreshWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            onDone: () -> Unit
        ) {
            val prefs: SharedPreferences =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val scanMode = prefs.getBoolean("scan_mode", false)
            val camCode: String
            val camName: String
            if (scanMode) {
                val codes = (prefs.getString("scan_cam_codes", null) ?: DEFAULT_CAM_CODE)
                    .split("|")
                    .filter { it.isNotEmpty() }
                val names = (prefs.getString("scan_cam_names", null) ?: DEFAULT_CAM_NAME)
                    .split("|")
                    .filter { it.isNotEmpty() }
                if (codes.isEmpty()) {
                    camCode = DEFAULT_CAM_CODE
                    camName = DEFAULT_CAM_NAME
                } else {
                    val index = prefs.getInt("scan_index", 0) % codes.size
                    camCode = codes[index]
                    camName = names.getOrElse(index) { camCode }
                    prefs.edit().putInt("scan_index", (index + 1) % codes.size).apply()
                }
            } else {
                camCode = prefs.getString("cam_code", DEFAULT_CAM_CODE) ?: DEFAULT_CAM_CODE
                camName = prefs.getString("cam_name", DEFAULT_CAM_NAME) ?: DEFAULT_CAM_NAME
            }

            appWidgetManager.updateAppWidget(appWidgetId, buildBaseViews(context, camName))

            executor.execute {
                var bitmap: Bitmap? = null
                try {
                    val url = URL("https://pogoda.topr.pl/download/current/$camCode.jpeg")
                    val connection = url.openConnection() as HttpURLConnection
                    connection.connectTimeout = 8000
                    connection.readTimeout = 8000
                    connection.doInput = true
                    connection.connect()
                    if (connection.responseCode == 200) {
                        bitmap = BitmapFactory.decodeStream(connection.inputStream)
                    }
                    connection.disconnect()
                } catch (_: Exception) {
                    // keep previously shown image on transient network errors
                }

                if (bitmap != null) {
                    val views = buildBaseViews(context, camName)
                    views.setImageViewBitmap(R.id.widget_image, bitmap)
                    val timeText = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
                    views.setTextViewText(R.id.widget_updated_at, "$timeText")
                    appWidgetManager.updateAppWidget(appWidgetId, views)
                }
                onDone()
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        if (appWidgetIds.isEmpty()) return

        val pendingResult = goAsync()
        val remaining = AtomicInteger(appWidgetIds.size)
        for (appWidgetId in appWidgetIds) {
            refreshWidget(context, appWidgetManager, appWidgetId) {
                if (remaining.decrementAndGet() <= 0) {
                    pendingResult.finish()
                }
            }
        }
    }
}
