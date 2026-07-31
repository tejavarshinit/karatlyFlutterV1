package com.karatly.karatly.cfjsbridge

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.net.Uri
import android.util.Log
import android.webkit.JavascriptInterface
import com.karatly.karatly.MainActivity
import org.json.JSONArray
import org.json.JSONObject

class CFJsBridge(private val context: Context) {

    @JavascriptInterface
    fun getAppList(name: String?): String {
        val intent = Intent().apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse(name)
        }
        val pm: PackageManager = context.packageManager
        val resInfo: List<ResolveInfo> = pm.queryIntentActivities(intent, 0)
        val packageNames = JSONArray()
        for (info in resInfo) {
            val appInfo = JSONObject().apply {
                put("appName", context.packageManager.getApplicationLabel(info.activityInfo.applicationInfo))
                put("appPackage", info.activityInfo.packageName)
            }
            packageNames.put(appInfo)
        }
        return packageNames.toString()
    }

    @JavascriptInterface
    fun openApp(upiClientPackage: String?, upiURL: String?): Boolean {
        val intent = Intent().apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse(upiURL)
        }
        val pm: PackageManager = context.packageManager
        val resInfo = pm.queryIntentActivities(intent, 0)
        var foundPackageFlag = false
        var upiClientResolveInfo: ResolveInfo? = null
        for (info in resInfo) {
            if (info.activityInfo.packageName == upiClientPackage) {
                foundPackageFlag = true
                upiClientResolveInfo = info
                break
            }
        }
        try {
            if (foundPackageFlag && upiClientResolveInfo != null) {
                intent.setClassName(
                    upiClientResolveInfo.activityInfo.packageName,
                    upiClientResolveInfo.activityInfo.name
                )
                if (context is MainActivity) {
                    context.startActivityForResult(intent, 1000)
                }
            }
        } catch (exception: Exception) {
            Log.d("CFJsBridge", "Error opening UPI app: ${exception.message}")
        }
        return true
    }
}
