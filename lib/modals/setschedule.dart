import 'package:android/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:android/classes/snackbar.dart';
import 'package:android/utils/struct.dart';
import '../utils/colors.dart';

class SetScheduleModal extends StatefulWidget {
  final bool show;
  final VoidCallback onClose;
  final Schedule schedule;

  const SetScheduleModal({
    super.key,
    required this.show,
    required this.onClose,
    required this.schedule,
  });

  @override
  State<SetScheduleModal> createState() => _SetScheduleModalState();
}

class _SetScheduleModalState extends State<SetScheduleModal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  late Schedule _tempSchedule;
  List<String> selectedDays = [];
  List<String> errors = [];
  final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _tempSchedule = widget.schedule.copy();
    selectedDays = List<String>.from(_tempSchedule.days);
    if (widget.show) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant SetScheduleModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tempSchedule = widget.schedule.copy();
    selectedDays = List<String>.from(_tempSchedule.days);
    widget.show ? _controller.forward(from: 0) : _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggleDay(String day) {
    setState(() {
      if (selectedDays.contains(day)) {
        selectedDays.remove(day);
      } else {
        selectedDays.add(day);
      }
      _tempSchedule.days = selectedDays;
    });
  }

  void removeRun(int index) {
    _tempSchedule.runs.removeAt(index);
    setState(() {});
  }

  void addRun() {
    _tempSchedule.runs.add({'time': '03:00', 'upto': '04:00'});
    setState(() {});
  }

  void validateAndSave() {
    errors = [];
    final runs = List<Map<String, String>>.from(_tempSchedule.runs);

    if (runs.isEmpty) errors.add('Add at least one run.');

    int toMinutes(String t) {
      final parts = t.split(':').map(int.parse).toList();
      return parts[0] * 60 + parts[1];
    }

    int? prevEnd;
    for (var i = 0; i < runs.length; i++) {
      final timeStr = runs[i]['time'];
      final uptoStr = runs[i]['upto'];

      if (timeStr == null || uptoStr == null) {
        errors.add('Run ${i + 1}: Missing time or end time.');
        continue;
      }

      final s = toMinutes(timeStr);
      final e = toMinutes(uptoStr);

      if (s < 180 || s > 1320) errors.add('Run ${i + 1}: Start must be 03:00–22:00');
      if (e < 180 || e > 1320) errors.add('Run ${i + 1}: End must be 03:00–22:00');
      if (e <= s) errors.add('Run ${i + 1}: End must be after start');

      if (prevEnd != null && s < prevEnd + 5) {
        errors.add('Run ${i + 1}: Must start at least 5 minutes after previous run ends.');
      }

      prevEnd = e;
    }

    final sorted = runs
        .asMap()
        .entries
        .map((e) => {'i': e.key, 'start': toMinutes(e.value['time']!), 'end': toMinutes(e.value['upto']!)})
        .toList()
      ..sort((a, b) => (a['start'] as int).compareTo(b['start'] as int));

    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1], curr = sorted[i];
      final prevStart = prev['start'] as int;
      final prevEndSorted = prev['end'] as int;
      final currStart = curr['start'] as int;

      if (currStart == prevStart) {
        errors.add('Runs ${prev['i']! + 1} & ${curr['i']! + 1} have same start');
      }

      if (currStart < prevEndSorted + 5) {
        errors.add('Runs ${prev['i']! + 1} & ${curr['i']! + 1} overlap or have less than 5 minutes gap');
      }
    }

    setState(() {});

    if (errors.isEmpty) {
      widget.onClose();
      widget.schedule.days = List.from(_tempSchedule.days);
      widget.schedule.frequency = _tempSchedule.frequency;
      widget.schedule.runs = List.from(_tempSchedule.runs);
      AppSnackBar.success(context, "Schedule saved successfully!");
    } else {
      AppSnackBar.error(context, errors.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show && _controller.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    final bgColor = AppColors.themedColor(context, AppColors.gray200, AppColors.gray800);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);
    final borderColor = AppColors.themedColor(context, AppColors.gray200, AppColors.gray700);

    return FadeTransition(
      opacity: _opacity,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              color: Colors.black.withAlpha(150),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          SlideTransition(
            position: _slide,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                elevation: 16,
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.8,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Set Schedule',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: textColor),
                            onPressed: widget.onClose,
                            splashRadius: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: days.map((d) {
                          final selected = selectedDays.contains(d);
                          return GestureDetector(
                            onTap: () => toggleDay(d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.green700 : AppColors.green500,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: selected
                                    ? [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                                    : [],
                              ),
                              child: Text(
                                d,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: _tempSchedule.frequency,
                        dropdownColor: AppColors.themedColor(context, AppColors.white, AppColors.gray700),
                        style: TextStyle(
                          color: AppColors.themedColor(context, AppColors.textLight, AppColors.textDark),
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Frequency',
                          labelStyle: TextStyle(color: textColor, fontSize: 13),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.green500, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          'weekly',
                          'bi-weekly',
                          'tri-weekly',
                          'monthly',
                          'bi-monthly',
                          'tri-monthly',
                          'semi-annual',
                          'yearly'
                        ]
                            .map(
                              (f) => DropdownMenuItem(
                                value: f,
                                child: Text(f, style: const TextStyle(fontSize: 13)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _tempSchedule.frequency = v!),
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView.separated(
                            itemCount: _tempSchedule.runs.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final run = _tempSchedule.runs[i];
                              return Card(
                                elevation: 3,
                                color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray700),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () async {
                                            TimeOfDay initialTime = TimeOfDay.now();
                                            if (run['time'] != null && run['time']!.isNotEmpty) {
                                              final parsed = _parseTime(run['time']!);
                                              if (parsed != null) {
                                                initialTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
                                              }
                                            }

                                            final TimeOfDay? picked = await showThemedTimePicker(
                                              context: context,
                                              initialTime: initialTime,
                                            );

                                            if (picked != null) {
                                              int hour = picked.hour;
                                              int minute = picked.minute;

                                              if (hour < 3) {
                                                hour = 3;
                                                minute = 0;
                                              }

                                              if (hour > 22 || (hour == 22 && minute > 0)) {
                                                hour = 22;
                                                minute = 0;
                                              }

                                              final formatted =
                                                  '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                                              if (run['upto'] != null && run['upto']!.isNotEmpty) {
                                                final uptoTime = _parseTime(run['upto']!);
                                                final pickedDateTime = DateTime(0, 1, 1, hour, minute);
                                                if (uptoTime != null && pickedDateTime.isAfter(uptoTime)) {
                                                  run['time'] = run['upto']!;
                                                } else {
                                                  run['time'] = formatted;
                                                }
                                              } else {
                                                run['time'] = formatted;
                                              }

                                              setState(() {});
                                            }

                                          },
                                          child: AbsorbPointer(
                                            child: TextFormField(
                                              controller: TextEditingController(text: run['time']),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                prefixIcon: const Icon(Icons.access_time, size: 20),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(color: borderColor),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: const BorderSide(color: AppColors.green500),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () async {
                                            TimeOfDay initialTime = TimeOfDay.now();
                                            if (run['upto'] != null && run['upto']!.isNotEmpty) {
                                              final parsed = _parseTime(run['upto']!);
                                              if (parsed != null) {
                                                initialTime = TimeOfDay(hour: parsed.hour, minute: parsed.minute);
                                              }
                                            }

                                            final TimeOfDay? picked = await showThemedTimePicker(
                                              context: context,
                                              initialTime: initialTime,
                                            );

                                            if (picked != null) {
                                              int hour = picked.hour;
                                              int minute = picked.minute;

                                              if (hour < 3) {
                                                hour = 3;
                                                minute = 0;
                                              }

                                              if (hour > 22 || (hour == 22 && minute > 0)) {
                                                hour = 22;
                                                minute = 0;
                                              }

                                              final formatted =
                                                  '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                                              if (run['time'] != null && run['time']!.isNotEmpty) {
                                                final time = _parseTime(run['time']!);
                                                final uptoTime = DateTime(0, 1, 1, hour, minute);
                                                if (time != null && time.isAfter(uptoTime)) {
                                                  run['time'] = formatted;
                                                }
                                              }

                                              run['upto'] = formatted;
                                              setState(() {});
                                            }
                                          },
                                          child: AbsorbPointer(
                                            child: TextFormField(
                                              controller: TextEditingController(text: run['upto']),
                                              decoration: InputDecoration(
                                                isDense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                prefixIcon: const Icon(Icons.access_time, size: 20),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: BorderSide(color: borderColor),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                  borderSide: const BorderSide(color: AppColors.green500),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.clear, size: 20, color: AppColors.red500),
                                        onPressed: () => removeRun(i),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: addRun,
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.purple500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('+ Add Run', style: TextStyle(fontSize: 14)),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: widget.onClose,
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.red500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: validateAndSave,
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.green500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Save', style: TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseTime(String input) {
    try {
      final parts = input.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return DateTime(0, 1, 1, hour, minute);
        }
      }
    } catch (_) {}
    return null;
  }
}
