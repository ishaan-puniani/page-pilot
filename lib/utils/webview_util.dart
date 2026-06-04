import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pagepilot/utils/tour_util.dart';
import 'package:pagepilot/utils/utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/step_model.dart';
import '../widgets/pointer_widget.dart';

class WebviewUtil {
  static WebViewController? controller;
  static ValueNotifier<Map<String, double>> sizeNotifier =
      ValueNotifier<Map<String, double>>({"height": 200, "width": 200});

  static const String bodyStartsWithHtmlString = "\u003C!DOCTYPE html";

  static String calculateHtmlDocDimensions = '''
(function() {
  try {
    const body = document.body;
    const html = document.documentElement;

    // Remove scrolling and set proper styles for both platforms
    html.style.margin = '0';
    html.style.padding = '0';
    html.style.overflow = 'hidden';
    html.style.height = '100%';
    
    body.style.margin = '0';
    body.style.padding = '0';
    body.style.overflow = 'hidden';
    body.style.height = '100%';

    // Ensure all images are loaded
    const imgs = document.images;
    for (let i = 0; i < imgs.length; i++) {
      if (!imgs[i].complete) return -1;
    }

    // Compute dimensions
    let height = Math.max(
      body.scrollHeight, body.offsetHeight,
      html.clientHeight, html.scrollHeight, html.offsetHeight
    );
    let width = Math.max(
      body.scrollWidth, body.offsetWidth,
      html.clientWidth, html.scrollWidth, html.offsetWidth
    );

    return JSON.stringify({ 
      height: height.toString(), 
      width: width.toString() 
    });
  } catch (e) {
    return JSON.stringify({ height: "400", width: "400" });
  }
})();
''';

  /// ✅ Initialize WebView with full auto-size and click-channel support
  static WebViewController init({required bool isTour}) {
    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(false);

    c.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (_) {},
        onPageStarted: (_) {},
        onPageFinished: (String url) async {
          try {
            print("✅ onPageFinished: $url");
            await Future.delayed(const Duration(milliseconds: 400));

            // 1️⃣ Remove scrollbars everywhere
            await c.runJavaScript('''
      document.documentElement.style.setProperty('margin','0','important');
      document.documentElement.style.setProperty('padding','0','important');
      document.documentElement.style.setProperty('overflow','hidden','important');
      document.body.style.setProperty('margin','0','important');
      document.body.style.setProperty('padding','0','important');
      document.body.style.setProperty('overflow','hidden','important');
      Array.from(document.querySelectorAll('*')).forEach(el=>{
        el.style.setProperty('overflow','hidden','important');
      });
    ''');

            // 2️⃣ Flutter JS Channel Setup (Android + iOS)
            await c.runJavaScript('''
      if (typeof window.FlutterChannel === 'undefined') {
        window.FlutterChannel = {
          postMessage: function(message) {
            try {
              if (window.MyFlutterApp) {
                window.MyFlutterApp.postMessage(message);
              }
              if (window.webkit?.messageHandlers?.FlutterChannel) {
                window.webkit.messageHandlers.FlutterChannel.postMessage(message);
              }
              console.log("FlutterChannel message:", message);
            } catch(e) {
              console.error("[Channel error]", e);
            }
          }
        };
      }
    ''');

            // 3️⃣ Universal Safe Button Handler (Android FIX)
            await c.runJavaScript(Platform.isAndroid
                ? '''
(function() {
  function send(action, url) {
    const payload = JSON.stringify({ action: action, url: url || null });

    // iOS
    try {
      if (window.webkit?.messageHandlers?.FlutterChannel) {
        window.webkit.messageHandlers.FlutterChannel.postMessage(payload);
      }
    } catch(e){}

    // Android (REQUIRES MyFlutterApp)
    try {
      if (window.MyFlutterApp) {
        window.MyFlutterApp.postMessage(payload);
      }
    } catch(e){}

    // Fallback
    try {
      if (window.FlutterChannel) {
        window.FlutterChannel.postMessage(payload);
      }
    } catch(e){}
  }

  function attach() {
    const buttons = document.querySelectorAll("button[data-action]");
    buttons.forEach(btn => {
      if (btn.__added) return;
      btn.__added = true;

      const handler = function(e) {
        e.preventDefault();
        e.stopImmediatePropagation();

        const action = btn.getAttribute("data-action");
        const anchor = btn.closest("a");
        send(action, anchor?.href || null);
      };

      btn.addEventListener("click", handler, true);
      btn.addEventListener("touchend", handler, true);
    });
  }

  attach();
  new MutationObserver(attach).observe(document.body, { childList: true, subtree: true });
})();
'''
                : '''
(function() {
  console.log("[JS] Attaching persistent tour button listeners");

  function sendToFlutter(action, url) {
    const payload = JSON.stringify({
      action: action,
      url: url || null
    });

    try {
      if (window.FlutterChannel) window.FlutterChannel.postMessage(payload);
      if (window.MyFlutterApp) window.MyFlutterApp.postMessage(payload);
      if (window.webkit?.messageHandlers?.FlutterChannel) {
        window.webkit.messageHandlers.FlutterChannel.postMessage(payload);
      }
    } catch(e) {
      console.error("[JS] Send error:", e);
    }
  }

  function attachListeners() {
    const buttons = document.querySelectorAll("button[data-action]");
    console.log("[JS] Found " + buttons.length + " buttons");

    buttons.forEach(btn => {
      if (btn._listenerAttached) return;
      btn._listenerAttached = true;

      const action = btn.getAttribute("data-action");

      const handler = function(event) {
        event.preventDefault();
        event.stopImmediatePropagation();

        const anchor = btn.closest("a");
        sendToFlutter(action, anchor?.href || null);
      };

      btn.addEventListener("click", handler, true);
      btn.addEventListener("touchend", handler, true);

      btn.style.cursor = "pointer";
    });
  }

  // Initial attach
  attachListeners();

  // Re-attach when DOM changes (SPA, animations)
  new MutationObserver(attachListeners)
    .observe(document.body, { childList: true, subtree: true });

  // Android safety fallback
  setInterval(attachListeners, 600);
})();
''');

            // 4️⃣ (Optional) Debug verification
            final result = await c.runJavaScriptReturningResult('''
      (function() {
        return JSON.stringify({
          buttons: document.querySelectorAll("button[data-action]").length,
          hasChannel: typeof window.FlutterChannel !== "undefined"
        });
      })();
    ''');

            print("🔧 JS Setup Result: $result");
          } catch (e, st) {
            print("❌ Error in onPageFinished: $e\n$st");
          }
        },
        onHttpError: (error) => print("HTTP Error: $error"),
        onWebResourceError: (error) => print("Web Resource Error: $error"),
        onNavigationRequest: (NavigationRequest request) {
          return NavigationDecision.navigate;
        },
      ),
    );
    c.addJavaScriptChannel(
      'MyFlutterApp', // REQUIRED FOR ANDROID
      onMessageReceived: (JavaScriptMessage message) {
        handleJsMessage(message.message);
      },
    );
    c.addJavaScriptChannel(
      'FlutterChannel',
      onMessageReceived: (JavaScriptMessage message) {
        final data = jsonDecode(message.message);
        switch (data['action']) {
          case 'onNextStep':
            print("NEXTTTT");
            TourUtil.next();
            break;
          case 'onPrevStep':
            TourUtil.previous();
            break;
          case 'openLink':
            final url = data['url'] as String;
            Util.launchInBrowser(url);
            break;
          case 'onCloseStep':
            TourUtil.finish();
            break;
        }
      },
    );
    if (!isTour) controller = c;
    return c;
  }

  static Widget getWebView() {
    return WebViewWidget(controller: controller!);
  }

  static void handleJsMessage(String msg) {
    final data = jsonDecode(msg);

    switch (data['action']) {
      case 'onNextStep':
        TourUtil.next();
        break;
      case 'onPrevStep':
        TourUtil.previous();
        break;
      case 'openLink':
        Util.launchInBrowser(data['url']);
        break;
      case 'onCloseStep':
        TourUtil.finish();
        break;
    }
  }

  static Widget getWebViewWidget(String? body, String? textColor,
      {WebViewController? tourWebViewController,
      String? contentHeight,
      String? contentwidth,
      StepModel? step,
      GlobalKey? targetKey}) {
    return body.toString().startsWith(WebviewUtil.bodyStartsWithHtmlString)
        ? contentHeight == null || contentHeight == "0"
            ? ValueListenableBuilder<Map<String, double>>(
                valueListenable: sizeNotifier,
                builder: (context, size, child) {
                  return TooltipWithFlushArrow(
                    borderRadius: (step?.borderRadius ?? 0).toDouble(),
                    arrowSize: 60,
                    showArrow: step?.isCaret == true,
                    targetKey: targetKey ?? GlobalKey(),
                    pointerPosition: step?.position.toString() == "bottom"
                        ? PointerPosition.top
                        : step?.position.toString() == "bottom-left"
                            ? PointerPosition.topRight
                            : step?.position.toString() == "bottom-right"
                                ? PointerPosition.topLeft
                                : step?.position.toString() == "top"
                                    ? PointerPosition.bottom
                                    : step?.position.toString() == "top-left"
                                        ? PointerPosition.bottomLeft
                                        : step?.position.toString() ==
                                                "top-right"
                                            ? PointerPosition.bottomRight
                                            : step?.position.toString() ==
                                                    "left"
                                                ? PointerPosition.right
                                                : step?.position.toString() ==
                                                        "right"
                                                    ? PointerPosition.left
                                                    : PointerPosition.bottom,
                    color: Util.hexToColor(step?.backgroundColor ?? "#000000"),
                    height: size["height"] ?? 0,
                    width: size["width"] ?? 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            Util.hexToColor(step?.backgroundColor ?? "#000000"),
                        borderRadius: BorderRadius.circular(
                            (step?.borderRadius ?? 0).toDouble()),
                      ),
                      height: size["height"],
                      // width: size["width"],
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: WebViewWidget(
                          gestureRecognizers: Platform.isIOS
                              ? <Factory<OneSequenceGestureRecognizer>>{
                                  Factory<VerticalDragGestureRecognizer>(
                                    () => VerticalDragGestureRecognizer(),
                                  ),
                                }.toSet()
                              : <Factory<OneSequenceGestureRecognizer>>{
                                  Factory<VerticalDragGestureRecognizer>(
                                    () => VerticalDragGestureRecognizer(),
                                  ),
                                }.toSet(),
                          controller: tourWebViewController ?? controller!),
                    ),
                  );
                },
              )
            : TooltipWithFlushArrow(
                borderRadius: (step?.borderRadius ?? 0).toDouble(),
                arrowSize: 60,
                showArrow: step?.isCaret == true,
                targetKey: targetKey ?? GlobalKey(),
                pointerPosition: step?.position.toString() == "bottom"
                    ? PointerPosition.top
                    : step?.position.toString() == "bottom-left"
                        ? PointerPosition.topRight
                        : step?.position.toString() == "bottom-right"
                            ? PointerPosition.topLeft
                            : step?.position.toString() == "top"
                                ? PointerPosition.bottom
                                : step?.position.toString() == "top-left"
                                    ? PointerPosition.bottomLeft
                                    : step?.position.toString() == "top-right"
                                        ? PointerPosition.bottomRight
                                        : step?.position.toString() == "left"
                                            ? PointerPosition.right
                                            : step?.position.toString() ==
                                                    "right"
                                                ? PointerPosition.left
                                                : PointerPosition.bottom,
                color: Util.hexToColor(step?.backgroundColor ?? "#000000"),
                height: double.tryParse(
                        contentHeight.toString().replaceAll("px", "")) ??
                    200,
                width: double.tryParse(
                        contentwidth.toString().replaceAll("px", "")) ??
                    200,
                child: Container(
                  height: double.tryParse(
                          contentHeight.toString().replaceAll("px", "")) ??
                      200,
                  width: double.tryParse(
                          contentwidth.toString().replaceAll("px", "")) ??
                      200,
                  decoration: BoxDecoration(
                    color: Util.hexToColor(step?.backgroundColor ?? "#000000"),
                    borderRadius: BorderRadius.circular(
                        (step?.borderRadius ?? 0).toDouble()),
                  ),
                  child: WebViewWidget(
                      gestureRecognizers: Platform.isIOS
                          ? <Factory<OneSequenceGestureRecognizer>>{
                              Factory<VerticalDragGestureRecognizer>(
                                () => VerticalDragGestureRecognizer(),
                              ),
                            }.toSet()
                          : <Factory<OneSequenceGestureRecognizer>>{
                              Factory<VerticalDragGestureRecognizer>(
                                () => VerticalDragGestureRecognizer(),
                              ),
                            }.toSet(),
                      controller: tourWebViewController ?? controller!),
                ),
              )
        : Text(
            body.toString(),
            overflow: TextOverflow.clip,
            style: TextStyle(
              color: textColor != null && textColor != "null"
                  ? Util.hexToColor(textColor)
                  : null,
            ),
          );
  }

  static void clearCache() {
    controller!.clearCache();
  }

  static load(String? url, String? body,
      {WebViewController? tourWebViewController}) {
    if (url != null) {
      WebviewUtil.loadUrl(url);
    }
    if (body.toString().startsWith(bodyStartsWithHtmlString)) {
      WebviewUtil.loadHtml(body, tourWebViewController: tourWebViewController);
    }
  }

  static void loadUrl(String url) {
    controller!.loadRequest(Uri.parse(url));
  }

  static void loadHtml(String? body,
      {WebViewController? tourWebViewController}) {
    WebViewController? c;
    if (tourWebViewController != null) {
      c = tourWebViewController;
    } else {
      c = controller;
    }
    c!.loadHtmlString(body.toString());
  }

  static void adjustWebviewZoom({int scale = 4}) {
    controller!.setNavigationDelegate(NavigationDelegate(
      onPageFinished: (String url) async {
//document.body.style.zoom = 5; NOT SUPPORTED
        await controller!.runJavaScript("""
              document.body.style.transform = "scale(${scale.toString()})";
              document.body.style.transformOrigin = "0 0";
            """);
      },
    ));
  }
}
