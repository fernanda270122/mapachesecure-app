package com.mapachesecure.mapachesecure_app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import org.json.JSONArray
import java.util.Calendar

class BloqueoAccessibilityService : AccessibilityService() {

    private val zonaSegura = setOf(
        "com.mapachesecure.mapachesecure_app",
        "com.android.systemui",
        "com.android.launcher", "com.android.launcher2",
        "com.android.launcher3", "com.android.launcher4",
        "com.miui.home", "com.miui.msa.global",
        "com.sec.android.app.launcher", "com.samsung.android.app.spage",
        "com.google.android.apps.nexuslauncher", "com.google.android.launcher",
        "com.bbk.launcher2", "com.vivo.launcher",
        "com.huawei.android.launcher", "com.honor.android.launcher",
        "com.motorola.launcher3",
        "com.coloros.launcher", "com.realme.launcher", "com.oneplus.launcher",
        "com.lge.launcher3", "com.zte.launcher", "com.nuvia.launcher"
    )

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val packageName = event.packageName?.toString() ?: return
        if (zonaSegura.contains(packageName)) return

        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)

        // 1. Bloqueos instantáneos (sin restricción de hora)
        val instanteJson = prefs.getString("flutter.apps_bloqueadas_instante", "[]") ?: "[]"
        try {
            val instante = JSONArray(instanteJson)
            for (i in 0 until instante.length()) {
                if (instante.getString(i) == packageName) {
                    bloquear(packageName, prefs)
                    return
                }
            }
        } catch (e: Exception) { e.printStackTrace() }

        // 2. Bloqueos de horario
        val bloqueosJson = prefs.getString("flutter.bloqueos_horario", "[]") ?: "[]"
        try {
            val bloqueos = JSONArray(bloqueosJson)
            if (estaEnHorarioProhibido(bloqueos, packageName)) {
                bloquear(packageName, prefs)
            }
        } catch (e: Exception) { e.printStackTrace() }
    }

    private fun bloquear(packageName: String, prefs: android.content.SharedPreferences) {
        prefs.edit().putString("flutter.app_bloqueada_actual", packageName).apply()
        performGlobalAction(GLOBAL_ACTION_HOME)
        val intent = packageManager.getLaunchIntentForPackage("com.mapachesecure.mapachesecure_app")
        intent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        startActivity(intent)
    }

    private fun estaEnHorarioProhibido(bloqueos: JSONArray, packageName: String): Boolean {
        val cal = Calendar.getInstance()
        // Java Calendar: Dom=1, Lun=2...Sab=7 → Supabase: Lun=0...Dom=6
        val diaActual = (cal.get(Calendar.DAY_OF_WEEK) + 5) % 7
        val minActual = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)

        for (i in 0 until bloqueos.length()) {
            val b = bloqueos.getJSONObject(i)

            val packagesStr = b.optString("package_names", "")
            val packages = packagesStr.split(",").map { it.trim() }.filter { it.isNotEmpty() }
            if (!packages.contains(packageName)) continue

            val diasRaw = b.opt("dias_semana")
            val diasArray: JSONArray = when (diasRaw) {
                is JSONArray -> diasRaw
                is String -> try { JSONArray(diasRaw) } catch (e: Exception) { JSONArray() }
                else -> JSONArray()
            }
            var diaCoincide = false
            for (j in 0 until diasArray.length()) {
                if (diasArray.getInt(j) == diaActual) { diaCoincide = true; break }
            }
            if (!diaCoincide) continue

            val ini = b.getString("hora_inicio").split(":")
            val fin = b.getString("hora_fin").split(":")
            val iniMin = ini[0].toInt() * 60 + ini[1].toInt()
            val finMin = fin[0].toInt() * 60 + fin[1].toInt()
            if (minActual >= iniMin && minActual < finMin) return true
        }
        return false
    }

    override fun onInterrupt() {}
}
