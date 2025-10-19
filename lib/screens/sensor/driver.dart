import 'package:android/classes/snackbar.dart';
import 'package:android/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';

class Driver extends StatefulWidget {
  final bool isRobotRunning;

  const Driver({
    super.key,
    required this.isRobotRunning,
  });

  @override
  State<Driver> createState() => _DriverState();
}

class _DriverState extends State<Driver> {
  bool isMoving = false;
  int speed = 60;
  int tempSpeed = 60;
  String currentMoving = '';

  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendCommand(String action, [int? value]) async {
    final endpoint = value != null ? '/drive/$action?speed=$value' : '/drive/$action';

    AppSnackBar.loading(
      context,
      'AGRIBOT ${action.toUpperCase()} command...',
      id: 'robot-drive',
    );

    try {
      final handler = RequestHandler();
      final response = await handler.authFetch(
        endpoint,
        method: 'POST',
      );

      final success = response[0] == true;
      final data = response[1];

      if (!success) {
        final errorMessage = data?['message'] ?? 'Unknown error';

        if (action == 'forward') {
          if (mounted) {
            AppSnackBar.error(
              context,
              'Movement blocked: $errorMessage',
            );
          }

          if (mounted) {
            setState(() {
              isMoving = false;
              currentMoving = '';
            });
            AppSnackBar.hide(context, id: 'robot-drive');
          }

          return;
        }
        if (mounted) {
          AppSnackBar.error(
            context,
            'Failed to $action robot: $errorMessage',
          );
        }
      } else {
        if (action != 'stop') {
          if (mounted) {
            AppSnackBar.success(
              context,
              'AGRIBOT $action command executed successfully!',
            );
          }
        }
      }
    } catch (err) {
      if (mounted) {
        AppSnackBar.error(
          context,
          'Network error: $err',
        );
      }
    } finally {
      if (mounted) {
        AppSnackBar.hide(context, id: 'robot-drive');
      }
    }
  }

  Future<void> _startMoving(String action) async {
    if (currentMoving == action || (isMoving && widget.isRobotRunning)) return;
    setState(() {
      isMoving = true;
      currentMoving = action;
    });
    final actionLabel = switch (action) {
      'forward' => 'Moving Forward',
      'left' => 'Turning Left',
      'right' => 'Turning Right',
      'backward' => 'Moving Backward',
      _ => 'Moving',
    };
    AppSnackBar.loading(context, '$actionLabel at $speed% speed...', id: 'robot-drive');
    await _sendCommand(action, speed);
  }

  Future<void> _stopMoving() async {
    if (!isMoving) return;
    setState(() {
      isMoving = false;
      currentMoving = '';
    });
    AppSnackBar.hide(context, id: 'robot-drive');
    await _sendCommand('stop');
  }

  void _commitSpeed() {
    if (speed == tempSpeed) return;
    speed = tempSpeed;
		AppSnackBar.info(context, "Speed set to $speed%");
  }

  Widget _buildButton(BuildContext ctx, String label, Color color, String move) {
    final bool disabled = widget.isRobotRunning || (isMoving && currentMoving != move);
    final bool isActive = currentMoving == move && isMoving;

    return Listener(
      onPointerUp: (_) => _stopMoving(),
      onPointerCancel: (_) => _stopMoving(),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => _startMoving(move),
        onTapUp: disabled ? null : (_) => _stopMoving(),
        onTapCancel: disabled ? null : _stopMoving,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: disabled ? 0.5 : 1.0,
          child: AnimatedScale(
            scale: isActive ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 100),
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
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _darkenColor(Color color, [double amount = 0.1]) {
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.themedColor(context, AppColors.gray200, AppColors.gray800);
    return Focus(
      focusNode: focusNode,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.5,
              ),
              children: [
                _buildButton(context, 'FORWARD', AppColors.green500, 'forward'),
                _buildButton(context, 'LEFT', AppColors.blue500, 'left'),
                _buildButton(context, 'RIGHT', AppColors.blue500, 'right'),
                _buildButton(context, 'BACKWARD', AppColors.red500, 'backward'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _speedDropdown(),
            )
          ],
        ),
      ),
    );
  }

  Widget _speedDropdown() {
    final disabled = widget.isRobotRunning;
    final speedOptions = List.generate(21, (i) => (i * 5).toString());

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.themedColor(context, AppColors.white, AppColors.gray700),
          border: Border.all(color: AppColors.green500),
          borderRadius: BorderRadius.circular(20),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: tempSpeed.toString(),
            isDense: true,
            icon: Icon(Icons.arrow_drop_down, size: 16, color: AppColors.green500),
            dropdownColor: AppColors.themedColor(context, AppColors.white, AppColors.gray700),
            style: TextStyle(
              color: AppColors.themedColor(context, AppColors.textLight, AppColors.textDark),
              fontSize: 13,
            ),
            items: speedOptions
                .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text("$v%"),
                    ))
                .toList(),
            onChanged: disabled
                ? null
                : (v) {
                    if (v == null) return;
                    setState(() => tempSpeed = int.parse(v));
                    _commitSpeed();
                  },
          ),
        ),
      ),
    );
  }
}
