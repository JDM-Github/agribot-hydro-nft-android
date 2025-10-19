import 'package:android/classes/snackbar.dart';
import 'package:android/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';

class SprayControls extends StatefulWidget {
  final bool isRobotRunning;

  const SprayControls({
    super.key,
    required this.isRobotRunning,
  });

  Future<bool> activateSpray(int num) async => true;
  Future<bool> toggleSpray(int num, bool turnOn) async => false;

  @override
  State<SprayControls> createState() => _SprayControlsState();
}

class _SprayControlsState extends State<SprayControls> {
  bool triggerMode = false;
final List<int> allClickedTrigger = [];

  Future<void> handleActivateSpray(int num) async {
    if (allClickedTrigger.contains(num)) return;
    setState(() => allClickedTrigger.add(num));

    final String toastId = 'spray-$num';
    AppSnackBar.loading(context, 'Spraying Spray $num...', id: toastId);

    try {
      final handler = RequestHandler();
      final response = await handler.authFetch('/trigger/$num', method: 'POST');

      final success = response.isNotEmpty ? response[0] == true : false;
      final data = response.length > 1 ? response[1] : null;

      if (!success) {
        final errorMessage = data?['message'] ?? 'Unknown error';
        if (mounted) {
          AppSnackBar.error(context, 'Failed to trigger Spray $num: $errorMessage');
        }
        return;
      }

      if (data?['status'] == 'error') {
        if (mounted) {
          AppSnackBar.error(context, data?['message'] ?? 'Spray $num failed.');
        }
        return;
      }

      if (mounted) {
        AppSnackBar.success(
          context,
          data?['message'] ?? 'Successfully triggered Spray $num!',
        );
      }
    } catch (err) {
      if (mounted) {
        AppSnackBar.error(context, 'Network error: $err');
      }
      debugPrint('Error triggering Spray $num: $err');
    } finally {
      if (mounted) {
        AppSnackBar.hide(context, id: toastId);
        setState(() => allClickedTrigger.remove(num));
      }
    }
  }

  Future<void> handleToggleSpray(int num, bool turnOn) async {
    if (allClickedTrigger.contains(num)) return;
    setState(() => allClickedTrigger.add(num));

    final String state = turnOn ? 'on' : 'off';
    final String toastId = 'relay-$num';
    AppSnackBar.loading(
      context,
      'Turning $state Spray $num...',
      id: toastId,
    );

    try {
      final handler = RequestHandler();
      final response = await handler.authFetch('/relay/$num/$state', method: 'POST');

      final success = response.isNotEmpty ? response[0] == true : false;
      final data = response.length > 1 ? response[1] : null;

      if (!success) {
        final errorMessage = data?['message'] ?? 'Unknown error';
        if (mounted) {
          AppSnackBar.error(context, 'Failed to toggle Spray $num: $errorMessage');
        }
        return;
      }

      if (data?['status'] == 'error' && turnOn) {
        if (mounted) {
          AppSnackBar.error(context, data?['message'] ?? 'Spray $num error.');
        }
        return;
      }

      if (mounted) {
        AppSnackBar.success(
          context,
          'Spray $num turned ${turnOn ? 'ON' : 'OFF'} successfully!',
        );
      }
    } catch (err) {
      if (mounted) {
        AppSnackBar.error(context, 'Network error: $err');
      }
      debugPrint('Error controlling Spray $num: $err');
    } finally {
      if (mounted) {
        AppSnackBar.hide(context, id: toastId);
        setState(() => allClickedTrigger.remove(num));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray800),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPRAY CONTROLS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.themedColor(context, AppColors.gray800, AppColors.gray300),
                ),
              ),
              Column(
                children: [
                  const Text('Trigger Mode', style: TextStyle(fontSize: 12)),
                  Switch(
                    value: triggerMode,
                    onChanged: widget.isRobotRunning ? null : (val) => setState(() => triggerMode = val),
                    activeColor: Colors.green,
                    activeTrackColor: Colors.green.withAlpha(125),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final num = index + 1;
              final isDisabled = widget.isRobotRunning || allClickedTrigger.contains(num);
              final isActive = allClickedTrigger.contains(num);

              final label = triggerMode ? 'TRIGGER $num' : 'HOLD $num';
              final color = AppColors.blue500;

              return Listener(
                onPointerUp: triggerMode || isDisabled ? null : (_) => handleToggleSpray(num, false),
                onPointerCancel: triggerMode || isDisabled ? null : (_) => handleToggleSpray(num, false),
                child: GestureDetector(
                  onTapDown: isDisabled
                      ? null
                      : (_) {
                          if (triggerMode) {
                            handleActivateSpray(num);
                          } else {
                            handleToggleSpray(num, true);
                          }
                        },
                  onTapUp: triggerMode || isDisabled ? null : (_) => handleToggleSpray(num, false),
                  onTapCancel: triggerMode || isDisabled ? null : () => handleToggleSpray(num, false),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: isDisabled ? 0.6 : 1.0,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 100),
                      scale: isActive ? 1.05 : 1.0,
                      curve: Curves.easeOut,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive ? _darkenColor(color, 0.15) : color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: color.withAlpha(100),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _darkenColor(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }
}
