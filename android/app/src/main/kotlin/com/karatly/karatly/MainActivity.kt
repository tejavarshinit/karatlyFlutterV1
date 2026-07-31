package com.karatly.karatly

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.karatly.karatly.cfjsbridge.WebViewFactory

class MainActivity : FlutterActivity() {

    private lateinit var webViewFactory: WebViewFactory

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        webViewFactory = WebViewFactory(this, flutterEngine.dartExecutor.binaryMessenger)
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "custom_webview", webViewFactory
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1000) {
            webViewFactory.webView?.evaluateJavascript("window.showVerifyUI()", null)
        }
    }
}
