package com.karatly.karatly.cfjsbridge

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.util.Log
import android.view.View
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class WebViewFactory(
    private val context: Context,
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    var webView: WebView? = null
    private val cfJsBridge: CFJsBridge by lazy { CFJsBridge(context) }
    private val methodChannel = MethodChannel(messenger, "custom_webview_channel")

    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        webView = initAndGetWebView(context, args)
        return CustomWebViewPlatform(webView)
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun initAndGetWebView(context: Context?, args: Any?): WebView {
        val webView = WebView(context!!)
        webView.settings.javaScriptEnabled = true
        webView.settings.domStorageEnabled = true
        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                val current = request?.url?.toString() ?: return false
                Log.d("PAYMENT", "shouldOverrideUrlLoading: $current | isReturn=${isReturnUrl(current)}")
                if (isReturnUrl(current)) {
                    Log.d("PAYMENT", "BLOCKING return URL + sending onReturn")
                    methodChannel.invokeMethod("onReturn", current)
                    return true
                }
                return false
            }

            @Deprecated("Deprecated in Java")
            override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean {
                val current = url ?: return false
                Log.d("PAYMENT", "shouldOverrideUrlLoading(legacy): $current | isReturn=${isReturnUrl(current)}")
                if (isReturnUrl(current)) {
                    Log.d("PAYMENT", "BLOCKING return URL + sending onReturn")
                    methodChannel.invokeMethod("onReturn", current)
                    return true
                }
                return false
            }

            override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                super.onPageStarted(view, url, favicon)
                val current = url ?: return
                Log.d("PAYMENT", "onPageStarted: $current | isReturn=${isReturnUrl(current)}")
                if (isReturnUrl(current)) {
                    Log.d("PAYMENT", "onPageStarted detected return URL - sending onReturn")
                    methodChannel.invokeMethod("onReturn", current)
                }
            }
        }
        webView.addJavascriptInterface(cfJsBridge, "Android")
        val params = args as Map<*, *>
        val webUrl = params["webUrl"]
        if (webUrl != null) {
            Log.d("PAYMENT", "WebView loading URL: $webUrl")
            webView.loadUrl(webUrl.toString())
        }
        return webView
    }

    private fun isReturnUrl(url: String): Boolean {
        val uri = Uri.parse(url)
        val path = uri.path ?: ""
        return url.contains("return") ||
            url.contains("thankyou") ||
            path.contains("payment/return") ||
            url.contains("payment/result")
    }
}

class CustomWebViewPlatform(private val webView: WebView?) : PlatformView {
    override fun getView(): View? = webView
    override fun dispose() {
        webView?.destroy()
    }
}
