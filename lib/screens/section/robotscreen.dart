import 'dart:typed_data';

import 'package:android/classes/block.dart';
import 'package:android/classes/snackbar.dart';
import 'package:android/connection/all_states.dart';
import 'package:android/connection/connect.dart';
import 'package:android/handle_request.dart';
import 'package:android/screens/sensor/driver.dart';
import 'package:android/screens/sensor/head.dart';
import 'package:android/screens/sensor/relay.dart';
import 'package:android/screens/sensor/rgbsensor.dart';
import 'package:android/screens/sensor/tcrt5000.dart';
import 'package:android/screens/sensor/ultrasonic.dart';
import 'package:android/screens/sensor/watersensor.dart';
import 'package:android/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';

class RobotScreen extends StatefulWidget {
  final dynamic data;
  const RobotScreen({super.key, this.data});

  @override
  State<RobotScreen> createState() => _RobotScreenState();
}

class _RobotScreenState extends State<RobotScreen> {

  Future<void> controlRobot(BuildContext context, String move) async {
    AppSnackBar.loading(
      context,
      "AGRIBOT $move command...",
      id: "robot-control",
    );

    try {
      final handler = RequestHandler();
      final response = await handler.authFetch(
        "${move.toLowerCase()}_robot_loop",
        method: 'POST',
      );

      if (response[0] == true) {
        if (context.mounted) {
          AppSnackBar.success(
            context,
            'AGRIBOT command "$move" run successfully!',
          );
        }
      } else {
        if (context.mounted) {
          AppSnackBar.error(
            context,
            'AGRIBOT command failed: ${response[1]?['message'] ?? 'Unknown error'}',
          );
        }
      }
    } catch (err) {
      if (context.mounted) {
        AppSnackBar.error(
          context,
          '⚠️ Network error: $err',
        );
      }
    } finally {
      if (context.mounted) {
        AppSnackBar.hide(context, id: "robot-control");
      }
    }
  }
  static Future<void> controlRobotLivestream(State state, RobotLiveStreamAction action) async {
    AppSnackBar.loading(
      state.context,
      "AGRIBOT ${action.name} livestream command...",
      id: "robot-livestream",
    );

    try {
      final handler = RequestHandler();
      final response = await handler.authFetch(
        "${action.name.toLowerCase()}_robot_livestream",
        method: 'POST',
      );

      if (response[0] == true) {
        if (state.mounted) {
          AppSnackBar.success(
            state.context,
            'AGRIBOT livestream command "${action.name}" run successfully!',
          );
        }
      } else {
        if (state.mounted) {
          AppSnackBar.error(
            state.context,
            'AGRIBOT livestream command failed: ${response[1]?['message'] ?? 'Unknown error'}',
          );
        }
      }
    } catch (err) {
      if (state.mounted) {
        AppSnackBar.error(
          state.context,
          'Network error: $err',
        );
      }
    } finally {
      if (state.mounted) {
        AppSnackBar.hide(state.context, id: "robot-livestream");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: AllStates.allState,
      builder: (_, state, __) {
        final isConnected = state["conn"] as bool;
        final robotState = state["robot"] as int;
        final liveState = state["live"] as int;
        final scannerState = state["scan"] as bool;
        final robotScanState = state["rscan"] as bool;
        final performing = state["performing"] as bool;
        final robotLive = state["robotLive"] as bool;
        final stopCapture = state["stopCapture"] as bool;

        final isRobotBusy = scannerState ||
            liveState != 0 ||
            !isConnected ||
            robotScanState ||
            performing ||
            stopCapture;

        if (!isConnected) return const NotConnected();
        if (liveState != 0) return const StopRobot(whatRunning: "livestream");
        if (performing) return const StopRobot(whatRunning: "perform scan");
        if (scannerState) return const StopRobot(whatRunning: "scanner");

        return Scaffold(
          backgroundColor: AppColors.themedColor(
            context,
            AppColors.backgroundLight,
            AppColors.backgroundDark,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray800),
                  child: Column(
                    children: [
                      Card(
                        color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray700),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              const Text("ROBOT STATUS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              _actionButton("RUN", AppColors.green500, isRobotBusy || robotState == 1, () => controlRobot(context, "run")),
                              const SizedBox(width: 4),
                              _actionButton("PAUSE", AppColors.yellow500, isRobotBusy || robotState != 1, () => controlRobot(context, "pause")),
                              const SizedBox(width: 4),
                              _actionButton("STOP", AppColors.red500, isRobotBusy || robotState == 0, () => controlRobot(context, "stop")),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray950),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ValueListenableBuilder<Uint8List?>(
                                valueListenable: Connection.robotLiveFrame,
                                builder: (context, frame, _) {
                                  if (frame == null || frame.isEmpty) {
                                    return Text(
                                      "Robot Livestream",
                                      style: TextStyle(
                                        color: AppColors.themedColor(
                                          context,
                                          AppColors.gray900,
                                          AppColors.gray600,
                                        ),
                                        fontSize: 16,
                                      ),
                                    );
                                  }
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      frame,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      gaplessPlayback: true,
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Row(
                                  children: [
                                    _actionButton(
                                      "RUN LIVESTREAM",
                                      AppColors.green500,
                                      isRobotBusy || robotLive,
                                      () => controlRobotLivestream(
                                        this,
                                        RobotLiveStreamAction.run,
                                      ),
                                      fontSize: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    _actionButton(
                                      "STOP LIVESTREAM",
                                      AppColors.red500,
                                      isRobotBusy || !robotLive,
                                      () => controlRobotLivestream(
                                        this,
                                        RobotLiveStreamAction.stop,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ControlCardSwitcher(isRobotBusy: isRobotBusy || robotState != 0),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: AppColors.themedColor(context, AppColors.white, AppColors.gray900),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SprayControls(isRobotRunning: isRobotBusy || robotState != 0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton(String label, Color color, bool disabled, VoidCallback onTap, {double fontSize = 12}) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: fontSize)),
        ),
      ),
    );
  }
}

typedef OnWidgetSizeChange = void Function(Size size);

class MeasureSize extends StatefulWidget {
  final Widget child;
  final OnWidgetSizeChange onChange;

  const MeasureSize({super.key, required this.onChange, required this.child});

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) widget.onChange(renderBox.size);
    });
    return widget.child;
  }
}

class ControlCardSwitcher extends StatefulWidget {
  final bool isRobotBusy;

  const ControlCardSwitcher({super.key, required this.isRobotBusy});

  @override
  State<ControlCardSwitcher> createState() => _ControlCardSwitcherState();
}

class _ControlCardSwitcherState extends State<ControlCardSwitcher> with SingleTickerProviderStateMixin {
  bool showManual = true;
  double cardHeight = 0;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  void toggleMode(bool manual) {
    if (manual == showManual) return;
    setState(() {
      showManual = manual;
      if (showManual) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.themedColor(context, AppColors.white, AppColors.gray900),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => toggleMode(true),
                    child: Text(
                      "Manual Control",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: showManual ? AppColors.green500 : AppColors.gray500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => toggleMode(false),
                    child: Text(
                      "Goto Sensors",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: showManual ? AppColors.gray500 : AppColors.green500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: Offset(showManual ? 1 : -1, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(position: offsetAnimation, child: child);
                },
                child: showManual
                    ? Column(
                        key: const ValueKey('manual'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Manual Robot Control", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Driver(isRobotRunning: widget.isRobotBusy),
                          const SizedBox(height: 8),
                          ServoControl(isRobotRunning: widget.isRobotBusy),
                        ],
                      )
                    : Column(
                        key: const ValueKey('sensor'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Sensor Feedback", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Tcrt5000(isActive: true),
                              RgbSensor(isActive: true),
                              WaterSensors(isActive: true),
                              UltrasonicSensor(isActive: true),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
