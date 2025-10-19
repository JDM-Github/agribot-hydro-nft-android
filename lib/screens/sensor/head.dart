import 'package:android/classes/snackbar.dart';
import 'package:android/handle_request.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';

class ServoControl extends StatefulWidget {
  final bool isRobotRunning;

  const ServoControl({super.key, required this.isRobotRunning});

  @override
  State<ServoControl> createState() => _ServoControlState();
}

class _ServoControlState extends State<ServoControl> {
  int servoHorizontal = 90;
  int servoVertical = 165;
  bool _isServoBusy = false;

  Future<void> _adjustServo(String axis, int angle) async {
    if (_isServoBusy) return;
    setState(() => _isServoBusy = true);

    setState(() {
      if (axis == 'horizontal') {
        servoHorizontal = angle;
      } else {
        servoVertical = angle;
      }
    });

    final target = axis == 'horizontal' ? 'lr' : 'td';
    final endpoint = '/servo/$target/$angle';

    AppSnackBar.loading(
      context,
      'Adjusting ${axis.toUpperCase()} servo to $angle°...',
      id: 'servo-adjust',
    );

    try {
      final handler = RequestHandler();
      final response = await handler.authFetch(
        endpoint,
        method: 'POST',
      );

      final success = response.isNotEmpty ? response[0] == true : false;
      final data = response.length > 1 ? response[1] : null;

      if (!success) {
        final errorMessage = data?['message'] ?? 'Unknown error';
        if (mounted) {
          AppSnackBar.error(
            context,
            'Failed to adjust servo: $errorMessage',
          );
        }
        debugPrint('Failed to adjust servo: $errorMessage');
      } else {
        if (mounted) {
          AppSnackBar.success(
            context,
            'Servo (${axis.toUpperCase()}) adjusted successfully!',
          );
        }
      }
    } catch (err) {
      if (mounted) {
        AppSnackBar.error(
          context,
          'Network error: $err',
        );
      }
      debugPrint('Servo request error: $err');
    } finally {
      if (mounted) {
        AppSnackBar.hide(context, id: 'servo-adjust');
        setState(() => _isServoBusy = false); 
      }
    }
  }

  Widget _angleDropdown(String label, String axis, int min, int max, int value) {
    final disabled = widget.isRobotRunning || _isServoBusy; // ✅ disable while busy
    final options = List.generate((max - min) ~/ 5 + 1, (i) => (min + i * 5).toString());

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.themedColor(context, AppColors.white, AppColors.gray700),
                border: Border.all(color: AppColors.blue500),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value.toString(),
                  isDense: true,
                  icon: Icon(Icons.arrow_drop_down, size: 16, color: AppColors.blue500),
                  dropdownColor: AppColors.themedColor(context, AppColors.white, AppColors.gray700),
                  style: TextStyle(
                    color: AppColors.themedColor(context, AppColors.textLight, AppColors.textDark),
                    fontSize: 13,
                  ),
                  items: options
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text("$v°"),
                          ))
                      .toList(),
                  onChanged: disabled
                      ? null
                      : (v) {
                          if (v == null) return;
                          _adjustServo(axis, int.parse(v));
                        },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServoButton(String label, Color color, VoidCallback onPressed) {
    final disabled = widget.isRobotRunning || _isServoBusy;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => onPressed(),
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.themedColor(context, AppColors.gray200, AppColors.gray800);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _angleDropdown('Horizontal', 'horizontal', 0, 180, servoHorizontal),
          _angleDropdown('Vertical', 'vertical', 100, 180, servoVertical),
          const SizedBox(height: 12),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.5,
            ),
            children: [
              _buildServoButton('LOOK UP', AppColors.blue500, () => _adjustServo('vertical', 180)),
              _buildServoButton('LOOK DOWN', AppColors.blue500, () => _adjustServo('vertical', 100)),
              _buildServoButton('LOOK LEFT', AppColors.blue500, () => _adjustServo('horizontal', 45)),
              _buildServoButton('LOOK RIGHT', AppColors.blue500, () => _adjustServo('horizontal', 135)),
              _buildServoButton('CENTER', AppColors.green500, () async {
                await _adjustServo('horizontal', 90);
                await _adjustServo('vertical', 165);
              }),
            ],
          )
        ],
      ),
    );
  }
}
