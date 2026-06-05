import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:pagepilot/models/config_model.dart';
import 'package:pagepilot/models/data_model.dart';
import 'package:pagepilot/models/step_model.dart';
import 'package:pagepilot/models/styles_model.dart';
import 'package:pagepilot/utils/pref_util.dart';
import 'package:pagepilot/utils/tour_util.dart';
import 'package:pagepilot/utils/utils.dart';
import 'package:pagepilot/utils/webview_util.dart';
import 'package:pagepilot/widgets/pulse_animation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PagePilot {
  static OverlayEntry? _overlayEntry;

  static double borderRadius = 20;
  static double padding = 16;
  static bool showConfetti = false;
  static late ConfettiController _confettiController;

  static String htmlBodyStart =
      "<!DOCTYPE html> <html lang=\"en\"> <head> <meta name=\"viewport\" content=\"width=device-width, height=device-height, initial-scale=1.0, user-scalable=no\" /> <style> html, body { background:#ffffff00;margin: 0; padding: 0; width: 100%; height: 100%; display: flex; justify-content: center; align-items: center; overflow: hidden; } img, iframe, video { max-width: 100%; max-height: 100%; object-fit: contain; } </style> </head> <body>";

  // static String htmlBodyStart =
  //     "<body style=\"margin: 0;padding: 0;width: 100vw;height: 100vh;overflow: hidden;display: flex;justify-content: center;align-items: center;\"><style>body img,body iframe,body video {max-width: 100%;max-height: 100%;object-fit: contain;}</style>";
  static String htmlBodyEnd = "</body></html>";
  // static double webViewHeight = 200;
  // static double webViewWidth = 200;

  static Future<void> scrollToTarget(
      GlobalKey key, ScrollController scrollController) async {
    final context = key.currentContext;
    if (context != null) {
      final box = context.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      final scrollableBox = scrollController.position.context.storageContext
          .findRenderObject() as RenderBox;
      final offset = position.dy - scrollableBox.localToGlobal(Offset.zero).dy;
      await scrollController.animateTo(
        scrollController.offset + offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  static void init({Styles? tourStyles}) {
    TourUtil.initStyles(tourStyles);
    WebviewUtil.init(isTour: false);
  }

  static void showSnackbar(
    BuildContext context, {
    String? title,
    String? body,
    String? background,
    String? textColor,
    String? url,
    int duration = 3000,
    int? scale,
  }) {
    final overlay = Overlay.of(context);

    // Prevent multiple snackbars from appearing at the same time
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 40,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: Container(
            // height: 80,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: background != null
                  ? Util.hexToColor(background)
                  : Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                body != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title != null
                              ? ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 340,
                                  ),
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textColor != null
                                          ? Util.hexToColor(textColor)
                                          : Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                          WebviewUtil.isHtml(body.toString())
                              ? SizedBox(
                                  height: 50,
                                  width: 340,
                                  child: WebviewUtil.getWebView(),
                                )
                              : ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 300),
                                  child: Text(
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    body,
                                    style: TextStyle(
                                      color: textColor != null
                                          ? Util.hexToColor(textColor)
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                        ],
                      )
                    : SizedBox(
                        height: 80,
                        width: 340,
                        child: WebviewUtil.getWebView(),
                      ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    _overlayEntry?.remove();
                    _overlayEntry = null;

                    WebviewUtil.clearCache();
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Insert the overlay entry after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      overlay.insert(_overlayEntry!);
    });
    // Automatically remove the snackbar after a delay
    Future.delayed(Duration(milliseconds: duration), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
      WebviewUtil.clearCache();
    });

    WebviewUtil.load(url, body);
  }

  static void showBottomSheet(
    BuildContext context, {
    String? title,
    required String? body,
    String? background,
    String? textColor,
    String? url,
    int? scale,
    required Function() onOkPressed,
  }) {
    // var isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      // isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
                top: padding,
                bottom: padding * 2,
                left: padding,
                right: padding),
            decoration: BoxDecoration(
              color: background != null
                  ? Util.hexToColor(background)
                  : Util.isDarkMode
                      ? Colors.black
                      : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title != null
                    ? Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor != null
                              ? Util.hexToColor(textColor)
                              : null,
                        ),
                      )
                    : const SizedBox(),
                const SizedBox(height: 16),
                body != null
                    ? WebviewUtil.isHtml(body.toString())
                        ? Container(
                            height: 200,
                            constraints: const BoxConstraints(
                              minHeight: 200, // Minimum height
                              maxHeight: 500, // Maximum height
                            ),
                            // width: double.infinity,
                            child: WebviewUtil.getWebView(),
                          )
                        : Text(
                            body,
                            style: TextStyle(
                              color: textColor != null
                                  ? Util.hexToColor(textColor)
                                  : null,
                            ),
                          )
                    : SizedBox(
                        height: 200,
                        width: 200,
                        child: WebviewUtil.getWebView(),
                      ),
                Row(
                  children: [
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onOkPressed();
                      },
                      child: const Text("OK"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );

    WebviewUtil.load(url, body);
  }

  static void showOkDialog(
    BuildContext context, {
    required String shape,
    String? title,
    String? body,
    String? background,
    String? textColor,
    String? url,
    int? scale,
    Function()? onOkPressed,
  }) {
    // var isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    if (showConfetti) {
      _confettiController =
          ConfettiController(duration: const Duration(seconds: 10));
      _confettiController.play();
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: background != null
                ? Util.hexToColor(background)
                : Util.isDarkMode
                    ? Colors.black
                    : Colors.white,
            title: title != null
                ? Text(
                    title,
                    style: TextStyle(
                      color:
                          textColor != null ? Util.hexToColor(textColor) : null,
                    ),
                  )
                : null,
            content: SingleChildScrollView(
              child: Stack(
                children: [
                  body != null
                      ? WebviewUtil.isHtml(body.toString())
                          ? SizedBox(
                              height: 200,
                              width: 200,
                              child: WebviewUtil.getWebView(),
                            )
                          : Text(
                              body,
                              style: TextStyle(
                                color: textColor != null
                                    ? Util.hexToColor(textColor)
                                    : null,
                              ),
                            )
                      : SizedBox(
                          height: 200,
                          width: 200,
                          child: WebviewUtil.getWebView(),
                        ),
                  showConfetti
                      ? SizedBox(
                          height: 250,
                          width: 250,
                          child: ConfettiWidget(
                            confettiController: _confettiController,
                            blastDirectionality: BlastDirectionality.explosive,
                            // don't specify a direction, blast randomly
                            shouldLoop: true,
                            // start again as soon as the animation is finished
                            colors: const [
                              Colors.green,
                              Colors.blue,
                              Colors.pink,
                              Colors.orange,
                              Colors.purple
                            ],
                            // manually specify the colors to be used
                            createParticlePath: drawStar,
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: onOkPressed == null
                    ? () {
                        Navigator.pop(context);
                        if (showConfetti) {
                          _confettiController.stop();
                        }
                      }
                    : () {
                        Navigator.pop(context);
                        WebviewUtil.clearCache();
                        if (showConfetti) {
                          _confettiController.stop();
                        }
                        onOkPressed();
                      },
                child: const Text(
                  'OK',
                ),
              ),
            ],
          );
        });
    WebviewUtil.load(url, body);
  }

  static void showInfoDialog(BuildContext context,
      {required GlobalKey key,
      required DataModel data,
      Function()? onOkPressed}) {
    var isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    StepModel step = data.steps[0];
    Widget widget = AlertDialog(
      backgroundColor: isDarkTheme ? Colors.black : Colors.white,
      title: Text(
        step.title.toString(),
      ),
      // backgroundColor: AppTheme.backgroundColor,
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
              step.content.toString(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        // TextButton(
        //   onPressed: () => Navigator.pop(context),
        //   child: const Text(
        //     'Cancel',
        //   ),
        // ),
        TextButton(
          onPressed: onOkPressed == null
              ? () {
                  TourUtil.finish();
                }
              : () {
                  TourUtil.finish();
                  onOkPressed();
                },
          child: const Text(
            'OK',
          ),
        ),
      ],
    );

    TourUtil.show(
      context,
      widgets: [widget],
      keys: [key],
      data: data,
      targetIdentifier: "keyInfoDialog",
    );
  }

  static void showTooltip(
    BuildContext context, {
    required GlobalKey key,
    required DataModel data,
  }) {
    StepModel step = data.steps[0];
    Widget widget = SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: WebviewUtil.getWebViewWidget(
          step.content,
          step.textColor,
          contentHeight: step.height,
          contentwidth: step.width,
        ),
      ),
    );
    TourUtil.show(
      context,
      widgets: [widget],
      keys: [key],
      data: data,
      targetIdentifier: "keyTooltip",
    );

    WebviewUtil.load(null, step.content);
  }

  static OverlayEntry? _entry;

  static void showFloatingWidget(
    BuildContext context, {
    String? title,
    String? body,
    String? background,
    String? textColor,
    String? url,
    String? position,
    int? scale,
    bool isDraggable = false,
    Widget? customWidget,
    void Function()? onTap,
    bool? isVisible = false,
  }) {
    // Remove existing widget if any
    _entry?.remove();
    _entry = null;

    if (!(isVisible ?? false)) return;

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    const double margin = 30;

    Offset currentOffset;

    switch (position?.toLowerCase()) {
      case "topleft":
        currentOffset = const Offset(margin, margin);
        break;
      case "topcenter":
      case "top":
        currentOffset = Offset((screenSize.width - margin * 6) / 2, margin);
        break;
      case "topright":
        currentOffset = Offset(screenSize.width - margin * 6, margin);
        break;
      case "bottomleft":
        currentOffset = Offset(margin, screenSize.height - margin * 6);
        break;
      case "bottomcenter":
      case "bottom":
        currentOffset = Offset((screenSize.width - margin * 6) / 2,
            screenSize.height - margin * 6);
        break;
      case "bottomright":
        currentOffset = Offset(
            screenSize.width - margin * 6, screenSize.height - margin * 6);
        break;
      case "center":
        currentOffset = Offset((screenSize.width - margin * 6) / 2,
            (screenSize.height - margin * 5) / 2);
        break;
      case "leftcenter":
      case "left":
        currentOffset = Offset(margin, (screenSize.height - margin * 5) / 2);
        break;
      case "rightcenter":
      case "right":
        currentOffset = Offset(screenSize.width - margin * 6,
            (screenSize.height - margin * 5) / 2);
        break;
      default:
        currentOffset = Offset((screenSize.width - margin * 6) / 2,
            screenSize.height - margin * 6);
    }

    _entry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Positioned(
              top: currentOffset.dy,
              left: currentOffset.dx,
              child: SafeArea(
                child: Material(
                  elevation: 0,
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: onTap,
                    onPanUpdate: (details) {
                      if (isDraggable) {
                        setState(() {
                          currentOffset += details.delta;
                        });
                      }
                    },
                    child: customWidget ??
                        Container(
                          width: screenSize.width * 0.4,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: background != null
                                ? Util.hexToColor(background)
                                : Util.isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (title != null)
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor != null
                                        ? Util.hexToColor(textColor)
                                        : null,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (WebviewUtil.controller != null)
                                WebviewUtil.getWebViewWidget(
                                  body,
                                  textColor,
                                )
                            ],
                          ),
                        ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(_entry!);

    if (WebviewUtil.controller != null) {
      WebviewUtil.load(
        url,
        htmlBodyStart + body.toString() + htmlBodyEnd,
      );
    }
  }

  static void hideFloatingWidget() {
    _entry?.remove();
    _entry = null;
  }

  static void showBeacon(
    BuildContext context, {
    required GlobalKey key,
    required String beaconPosition,
    required Color color,
    required DataModel data,
    required Function() onBeaconClicked,
  }) {
    // Get the render box for the target widget
    final context = key.currentContext;
    if (context == null) return;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    Offset beaconOffset =
        calculateBeaconPosition(beaconPosition, position, size);
    // Use an OverlayEntry to display the pulse animation
    final overlay = Overlay.of(context);
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: beaconOffset.dy, // Calculated top position
        left: beaconOffset.dx, // Calculated left position
        child: GestureDetector(
          child: PulseAnimation(
            color: color,
          ),
          onTap: () {
            entry!.remove();
            showTooltip(
              context,
              key: key,
              data: data,
            );
            onBeaconClicked();
          },
        ),
      ),
    );

    overlay.insert(entry);

    // Remove the overlay after a delay
    // Future.delayed(Duration(seconds: 3), () {
    //   entry.remove();
    // });
  }

  static Future<void> showTour(
    BuildContext context,
    Config config, {
    required DataModel data,
    ScrollController? scrollController,
    bool showNextAndPreviousButtons = false,
    required Map<dynamic, dynamic> gkeys,
  }) async {
    List<Widget> widgets = [];
    List<GlobalKey> keys = [];
    List<StepModel> tours = data.steps;
    for (int i = 0; i < tours.length; i++) {
      // final tooltip = SuperTooltipController();
      WebViewController tourWebViewController = WebviewUtil.init(isTour: true);
      String body = tours[i].content.toString();
      String textColor = tours[i].textColor.toString();
      String? contentHeight = tours[i].height;
      String? contentwidth = tours[i].width;
      final key = gkeys[tours[i].selector.toString()];
      if (key == null) continue;
      keys.add(key);
      if (scrollController != null) {
        await scrollToTarget(key, scrollController);
      }

      widgets.add(
        SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                WebviewUtil.getWebViewWidget(
                  targetKey: key,
                  body,
                  textColor,
                  contentHeight: contentHeight,
                  contentwidth: contentwidth,
                  tourWebViewController: tourWebViewController,
                  step: tours[i],
                ),
                if (showNextAndPreviousButtons) ...{
                  const SizedBox(height: 20),
                  previousAndNextButtons(
                    i,
                    tours.length - 1,
                  ),
                }
              ],
            ),
          ),
        ),
      );

      WebviewUtil.load(
        null,
        body,
        tourWebViewController: tourWebViewController,
      );
    }
    //TODO: fix this temporary hack
    Future.delayed(Duration(milliseconds: 500), () async {
      bool? isDisposed = await Pref.readBool('disposed');
      if (isDisposed != true) {
        TourUtil.show(
          context,
          widgets: widgets,
          keys: keys,
          data: data,
          targetIdentifier: "keyTour",
        );
      }
    });
  }

  static Offset calculateBeaconPosition(
      String position, Offset widgetPosition, Size widgetSize) {
    double val = 15; //30 should be half of raius of circle
    switch (position) {
      case "topleft":
        return widgetPosition - Offset(val, val); // Adjusted for padding
      case "topright":
        return Offset(widgetPosition.dx + widgetSize.width - val,
            widgetPosition.dy - val);
      case "bottomleft":
        return Offset(widgetPosition.dx - val,
            widgetPosition.dy + widgetSize.height - val);
      case "bottomright":
        return Offset(widgetPosition.dx + widgetSize.width - val,
            widgetPosition.dy + widgetSize.height - val);
      case "center":
        return Offset(widgetPosition.dx + widgetSize.width / 2 - val,
            widgetPosition.dy + widgetSize.height / 2 - val);
      case "topcenter":
      case "top":
        return Offset(widgetPosition.dx + widgetSize.width / 2 - val,
            widgetPosition.dy - val);
      case "bottomcenter":
      case "bottom":
        return Offset(widgetPosition.dx + widgetSize.width / 2 - val,
            widgetPosition.dy + widgetSize.height - val);
      case "leftcenter":
      case "left":
        return Offset(widgetPosition.dx - val,
            widgetPosition.dy + widgetSize.height / 2 - val);
      case "rightcenter":
      case "right":
        return Offset(widgetPosition.dx + widgetSize.width - val,
            widgetPosition.dy + widgetSize.height / 2 - val);
      default:
        return widgetPosition;
    }
  }

  static Widget previousAndNextButtons(int index, lastIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: index == 0 ? null : () => TourUtil.previous(),
            child: Text(index == 0 ? '' : 'Previous'),
          ),
          GestureDetector(
            onTap: index == lastIndex ? null : () => TourUtil.next(),
            child: Text(index == lastIndex ? '' : 'Next'),
          ),
        ],
      ),
    );
  }

  static Widget previousAndNextButtonsWithScroll(
    int index,
    int lastIndex,
    List<dynamic> tours,
    Config config,
    ScrollController? scrollController,
    Map<dynamic, dynamic> gkeys,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: index == 0
              ? null
              : () async {
                  if (scrollController != null) {
                    final prevKey =
                        gkeys[tours[index - 1]["selector"].toString()];
                    await scrollToTarget(prevKey, scrollController);
                  }
                  TourUtil.previous();
                },
          child: Text(index == 0 ? '' : 'Previous'),
        ),
        GestureDetector(
          onTap: index == lastIndex
              ? null
              : () async {
                  if (scrollController != null) {
                    final nextKey =
                        gkeys[tours[index + 1]["selector"].toString()];
                    await scrollToTarget(nextKey, scrollController);
                  }
                  TourUtil.next();
                },
          child: Text(index == lastIndex ? '' : 'Next'),
        ),
      ],
    );
  }

  /// A custom Path to paint stars.
  static Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }
}
