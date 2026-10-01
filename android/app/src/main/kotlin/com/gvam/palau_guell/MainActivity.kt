package com.gvam.palau_guell

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import android.net.Uri
import android.view.Gravity
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import com.ryanheise.audioservice.AudioServiceActivity
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.system.exitProcess

class MainActivity : AudioServiceActivity() {

    companion object {
        private const val GCENTER_CHANNEL = "gcenter/app"
        private const val RESTART_REQUEST_CODE = 9876
    }

    private val handler = Handler(Looper.getMainLooper())

    private var gcenterOverlay: LinearLayout? = null
    private var gcenterTitle: TextView? = null
    private var gcenterDetail: TextView? = null
    private var gcenterProgress: ProgressBar? = null

    private val hideRunnable = object : Runnable {
        override fun run() {
            hideSystemUI()
            handler.postDelayed(this, 5_000)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GCENTER_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "showSyncProgress" -> {
                    val percent = (call.argument<Number>("percent")?.toInt() ?: 0)
                        .coerceIn(0, 100)
                    val title = call.argument<String>("title")
                        ?: "Actualizando contenido"
                    val detail = call.argument<String>("detail")
                        ?: "$percent %"

                    runOnUiThread {
                        showSyncProgress(percent, title, detail)
                    }
                    result.success(true)
                }

                "hideSyncProgress" -> {
                    runOnUiThread { hideSyncProgress() }
                    result.success(true)
                }

                "restartApp" -> {
                    result.success(true)
                    handler.postDelayed({ restartApplication() }, 500)
                }

                "installApk" -> {
                    val apkPath = call.argument<String>("path")
                    if (apkPath.isNullOrBlank()) {
                        result.error("APK_PATH", "Ruta APK vacía", null)
                    } else {
                        runOnUiThread {
                            runCatching { openApkInstaller(apkPath) }
                                .onSuccess { result.success(true) }
                                .onFailure { result.error("APK_INSTALL", it.message, null) }
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        hideSystemUI()
        handler.removeCallbacks(hideRunnable)
        handler.postDelayed(hideRunnable, 2_000)
    }

    override fun onPause() {
        super.onPause()
        handler.removeCallbacks(hideRunnable)
    }

    override fun onDestroy() {
        handler.removeCallbacks(hideRunnable)
        hideSyncProgress()
        super.onDestroy()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideSystemUI()
    }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()

    private fun roundedBackground(fill: Int, radiusDp: Int, strokeColor: Int? = null): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            setColor(fill)
            cornerRadius = dp(radiusDp).toFloat()
            if (strokeColor != null) {
                setStroke(dp(1), strokeColor)
            }
        }
    }

    private fun showSyncProgress(percent: Int, title: String, detail: String) {
        val decor = window.decorView as? ViewGroup ?: return

        if (gcenterOverlay == null) {
            val card = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dp(18), dp(14), dp(18), dp(14))
                elevation = dp(10).toFloat()
                background = roundedBackground(
                    Color.argb(248, 255, 255, 255),
                    18,
                    Color.rgb(214, 234, 223)
                )
            }

            val titleView = TextView(this).apply {
                setTextColor(Color.rgb(28, 48, 38))
                textSize = 14f
                setTypeface(typeface, Typeface.BOLD)
                maxLines = 1
            }

            val detailView = TextView(this).apply {
                setTextColor(Color.rgb(96, 112, 104))
                textSize = 11f
                maxLines = 1
                setPadding(0, dp(3), 0, dp(9))
            }

            val bar = ProgressBar(
                this,
                null,
                android.R.attr.progressBarStyleHorizontal
            ).apply {
                max = 100
                isIndeterminate = false
                progressTintList = ColorStateList.valueOf(Color.rgb(47, 148, 94))
                progressBackgroundTintList = ColorStateList.valueOf(Color.rgb(229, 239, 233))
            }

            card.addView(
                titleView,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            )
            card.addView(
                detailView,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            )
            card.addView(
                bar,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    dp(4)
                )
            )

            val lp = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.BOTTOM
            ).apply {
                leftMargin = dp(18)
                rightMargin = dp(18)
                bottomMargin = dp(24)
            }

            decor.addView(card, lp)

            gcenterOverlay = card
            gcenterTitle = titleView
            gcenterDetail = detailView
            gcenterProgress = bar
        }

        gcenterTitle?.text = title
        gcenterDetail?.text = detail
        gcenterProgress?.progress = percent
        gcenterOverlay?.bringToFront()
    }

    private fun hideSyncProgress() {
        val overlay = gcenterOverlay ?: return
        (overlay.parent as? ViewGroup)?.removeView(overlay)
        gcenterOverlay = null
        gcenterTitle = null
        gcenterDetail = null
        gcenterProgress = null
    }


    private fun openApkInstaller(apkPath: String) {
        val apkFile = File(apkPath)
        require(apkFile.isFile) { "APK no encontrada: $apkPath" }

        val uri: Uri = FileProvider.getUriForFile(
            this,
            "$packageName.gcenter.fileprovider",
            apkFile
        )

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun restartApplication() {
        handler.removeCallbacks(hideRunnable)
        hideSyncProgress()

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: return
        launchIntent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
        )

        val restartIntent = PendingIntent.getActivity(
            applicationContext,
            RESTART_REQUEST_CODE,
            launchIntent,
            PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.set(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + 1500,
            restartIntent
        )

        runCatching { finishAndRemoveTask() }
        handler.postDelayed({
            Process.killProcess(Process.myPid())
            exitProcess(0)
        }, 200)
    }

    private fun hideSystemUI() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let { controller ->
                controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_DEFAULT
                controller.hide(WindowInsets.Type.systemBars())
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                android.view.View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or android.view.View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or android.view.View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or android.view.View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or android.view.View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or android.view.View.SYSTEM_UI_FLAG_FULLSCREEN
                )
        }
    }
}
