import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pagepilot/models/data_model.dart';
import 'package:pagepilot/models/step_model.dart';
import 'package:pagepilot/models/styles_model.dart';
import 'package:pagepilot/utils/utils.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TourUtil {
  static Styles styles = Styles(
    shadowColor: Colors.red,
    shadowOpacity: 0.5,
    textSkip: "SKIP",
    imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
  );
  static late TutorialCoachMark tutorialCoachMark;

  static void initStyles(Styles? s) {
    var brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    Util.isDarkMode = brightness == Brightness.dark;
    if (s != null) {
      styles = Styles(
        shadowColor: s.shadowColor,
        shadowOpacity: s.shadowOpacity,
        textSkip: s.textSkip,
        imageFilter: s.imageFilter,
      );
    }
    // else {
    //   styles = Styles(
    //     shadowColor: Colors.red,
    //     shadowOpacity: 0.5,
    //     textSkip: "SKIP",
    //     imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
    //   );
    // }
  }

  static void initTutorialCoachMark(List<TargetFocus> targets) {
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: styles.shadowColor ?? Colors.red,
      textSkip: styles.textSkip ?? "SKIP",
      alignSkip: Alignment.bottomRight,
      paddingFocus: 5,
      opacityShadow: styles.shadowOpacity ?? 0.5,
      imageFilter: styles.imageFilter ?? ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onFinish: () {
        print("finish");
      },
      onClickTarget: (target) {
        print('onClickTarget: $target');
      },
      onClickTargetWithTapPosition: (target, tapDetails) {
        print("target: $target");
        print(
            "clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
      },
      onClickOverlay: (target) {
        print('onClickOverlay: $target');
      },
      onSkip: () {
        print("skip");
        return true;
      },
    );
  }

  static CustomTargetContentPosition getCustomPosition(
    String position,
    GlobalKey keyTarget,
  ) {
    const double verticalOffset = 220;
    const double horizontalOffset = 50;

    final context = keyTarget.currentContext;
    if (context == null) {
      return CustomTargetContentPosition(
        top: 0,
      );
    }
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset widgetPos = renderBox.localToGlobal(Offset.zero);
    // final Size widgetSize = renderBox.size;

    switch (position) {
      case "center":
        return CustomTargetContentPosition(
          top: widgetPos.dy - (verticalOffset - 100),
        );
      case "topLeft":
        return CustomTargetContentPosition(
          top: widgetPos.dy - verticalOffset,
          right: widgetPos.dx - horizontalOffset,
        );
      case "topRight":
        return CustomTargetContentPosition(
          top: widgetPos.dy - verticalOffset,
          left: widgetPos.dx - horizontalOffset,
        );
      case "bottomLeft":
        return CustomTargetContentPosition(
          bottom: widgetPos.dy - verticalOffset,
          right: widgetPos.dx - horizontalOffset,
        );
      case "bottomRight":
        return CustomTargetContentPosition(
          bottom: widgetPos.dy - verticalOffset,
          left: widgetPos.dx - horizontalOffset,
        );
      default:
        return CustomTargetContentPosition(
          top: 0,
        );
    }
  }

  static void show(
    BuildContext context, {
    required List<Widget> widgets,
    required List<GlobalKey> keys,
    required DataModel data,
    required String targetIdentifier,
  }) {
    List<StepModel> steps = data.steps;

    List<TargetFocus> targets = [];
    for (int i = 0; i < keys.length; i++) {
      if (keys[i].currentContext == null) continue;

      String position = steps[i].position.toString();

      targets.add(
        TargetFocus(
          shape: steps[i].shape.toString().toLowerCase() == "circle"
              ? ShapeLightFocus.Circle
              : ShapeLightFocus.RRect,
          identify: targetIdentifier + i.toString(),
          keyTarget: keys[i],
          alignSkip: position.toString() == "bottom" ||
                  position.toString() == "bottom-right" ||
                  position.toString() == "bottom-left"
              ? Alignment.bottomRight
              : position.toString() == "top" ||
                      position.toString() == "top-right" ||
                      position.toString() == "top-left"
                  ? Alignment.topRight
                  : position.toString() == "left"
                      ? Alignment.topRight
                      : position.toString() == "right"
                          ? Alignment.topLeft
                          : Alignment.topRight,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              padding: EdgeInsets.zero,
              customPosition: getCustomPosition(position.toString(), keys[i]),
              align: position.toString() == "bottom" ||
                      position.toString() == "bottom-right" ||
                      position.toString() == "bottom-left"
                  ? ContentAlign.bottom
                  : position.toString() == "top" ||
                          position.toString() == "top-right" ||
                          position.toString() == "top-left"
                      ? ContentAlign.top
                      : position.toString() == "left"
                          ? ContentAlign.left
                          : position.toString() == "right"
                              ? ContentAlign.right
                              : ContentAlign.custom,
              builder: (context, coachMarkController) {
                return widgets[i];
              },
            ),
          ],
        ),
      );
    }

    initTutorialCoachMark(targets);
    tutorialCoachMark.show(context: context);

    // switch (data.type) {
    //   case "material":
    //     break;
    //   case "fancy":
    //     break;
    // }
  }

  static void finish() {
    tutorialCoachMark.finish();
  }

  static void next() {
    tutorialCoachMark.next();
  }

  static void previous() {
    tutorialCoachMark.previous();
  }
}
