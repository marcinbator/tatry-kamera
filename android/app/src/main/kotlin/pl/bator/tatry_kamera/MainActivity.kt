package pl.bator.tatry_kamera

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "pl.bator.tatry_kamera/widget_configure"
        private var skipNextConfigure = false
    }

    private var configuringWidgetId: Int = AppWidgetManager.INVALID_APPWIDGET_ID
    private var pendingLaunchCamera: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        intent.getStringExtra(ToprCamWidgetProvider.EXTRA_CAM_NAME)?.let {
            pendingLaunchCamera = it
        }

        if (intent.action != AppWidgetManager.ACTION_APPWIDGET_CONFIGURE) return

        val widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )

        if (skipNextConfigure) {
            skipNextConfigure = false
            val result = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            setResult(RESULT_OK, result)
            finish()
            return
        }

        configuringWidgetId = widgetId
        val cancelResult = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
        setResult(RESULT_CANCELED, cancelResult)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isConfiguring" ->
                    result.success(configuringWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID)
                "finishConfiguration" -> {
                    if (configuringWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                        val resultValue = Intent().putExtra(
                            AppWidgetManager.EXTRA_APPWIDGET_ID,
                            configuringWidgetId
                        )
                        setResult(RESULT_OK, resultValue)
                    }
                    finish()
                    result.success(null)
                }
                "prepareForPin" -> {
                    skipNextConfigure = true
                    result.success(null)
                }
                "consumeLaunchCamera" -> {
                    val cam = pendingLaunchCamera
                    pendingLaunchCamera = null
                    result.success(cam)
                }
                else -> result.notImplemented()
            }
        }
    }
}
