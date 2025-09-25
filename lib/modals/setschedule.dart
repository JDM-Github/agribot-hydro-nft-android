import 'package:android/classes/snackbar.dart';
import 'package:android/utils/struct.dart';
import 'package:flutter/material.dart';
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
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

  List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  late Schedule _tempSchedule;
  late Schedule _trackerSchedule;
  List<String> selectedDays = [];
  List<String> errors = [];

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
    if (widget.show) {
      _tempSchedule = widget.schedule.copy();
      selectedDays = List<String>.from(_tempSchedule.days);
      _controller.forward(from: 0);
    } else {
      _controller.reverse();
    }
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
    final runs = List<Map<String, String>>.from(_tempSchedule.runs);
    runs.removeAt(index);
    _tempSchedule.runs = runs;
    setState(() {});
  }

  void addRun() {
    final runs = List<Map<String, String>>.from(_tempSchedule.runs);
    runs.add({'time': '03:00', 'upto': '04:00'});
    _tempSchedule.runs = runs;
    setState(() {});
  }

  void validateAndSave() {
    if (errors.isNotEmpty && _trackerSchedule.sameAs(_tempSchedule)) {
      return;
    }

    errors = [];
    final runs = List<Map<String, String>>.from(_tempSchedule.runs);

    if (runs.isEmpty) errors.add('Add at least one run.');

    int toMinutes(String t) {
      final parts = t.split(':').map(int.parse).toList();
      return parts[0] * 60 + parts[1];
    }

    for (var i = 0; i < runs.length; i++) {
      final s = toMinutes(runs[i]['time']!);
      final e = toMinutes(runs[i]['upto']!);
      if (s < 180 || s > 1320) errors.add('Run ${i + 1}: Start must be 03:00–22:00');
      if (e < 180 || e > 1320) errors.add('Run ${i + 1}: End must be 03:00–22:00');
      if (e <= s) errors.add('Run ${i + 1}: End must be after start');
    }

    final sorted = runs
        .asMap()
        .entries
        .map((e) => {'i': e.key, 'start': toMinutes(e.value['time']!), 'end': toMinutes(e.value['upto']!)})
        .toList()
      ..sort((a, b) => a['start']!.compareTo(b['start']!));

    for (var i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final curr = sorted[i];
      if (curr['start'] == prev['start']) {
        errors.add('Runs ${prev['i']! + 1} & ${curr['i']! + 1} have same start');
      }
      if (curr['start']! < prev['end']!) {
        errors.add('Runs ${prev['i']! + 1} & ${curr['i']! + 1} overlap');
      }
    }

    setState(() {});

    if (errors.isEmpty) {
      widget.schedule.days = List<String>.from(_tempSchedule.days);
      widget.schedule.frequency = _tempSchedule.frequency;
      widget.schedule.runs = List<Map<String, String>>.from(_tempSchedule.runs);

      _trackerSchedule = _tempSchedule.copy();
      AppSnackBar.success(context, "Schedule saved successfully!");
    } else {
      _trackerSchedule = _tempSchedule.copy();
      AppSnackBar.error(context, errors.first);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (!widget.show && _controller.status == AnimationStatus.dismissed) return const SizedBox.shrink();
    final theme = Theme.of(context).brightness;
    final bgColor = AppColors.themedColor(context, AppColors.white, AppColors.gray900);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);
    final borderColor = AppColors.themedColor(context, AppColors.gray300, AppColors.gray700);

    return FadeTransition(
      opacity: _opacity,
      child: Stack(
        children: [
          GestureDetector(
              onTap: widget.onClose,
              child: Container(color: Colors.black.withAlpha(200), width: double.infinity, height: double.infinity)),
          Center(
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Set Schedule',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        IconButton(icon: Icon(Icons.close, color: textColor), onPressed: widget.onClose),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: days.map((d) {
                        final selected = selectedDays.contains(d);
                        return GestureDetector(
                          onTap: () => toggleDay(d),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.green700 : AppColors.green500,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(d, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Frequency
                    DropdownButtonFormField<String>(
                      value: _tempSchedule.frequency,
                      decoration: InputDecoration(
                        labelText: 'Frequency',
                        labelStyle: TextStyle(color: textColor),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                        filled: true,
                        fillColor: theme == Brightness.light ? AppColors.gray100 : AppColors.gray800,
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
                      ].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (v) => setState(() => _tempSchedule.frequency = v!),
                    ),

                    if (errors.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(8),
                        color: Colors.red,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: errors
                              .map((e) => Text(e, style: const TextStyle(fontSize: 10, color: Colors.white)))
                              .toList(),
                        ),
                      ),

                    const SizedBox(height: 8),
                    Column(
                      children: List.generate(
                        _tempSchedule.runs.length,
                        (i) {
                          final run = _tempSchedule.runs[i];
                          return Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: run['time'],
                                  decoration: const InputDecoration(isDense: true),
                                  onChanged: (v) => run['time'] = v,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextFormField(
                                  initialValue: run['upto'],
                                  decoration: const InputDecoration(isDense: true),
                                  onChanged: (v) => run['upto'] = v,
                                ),
                              ),
                              IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                  onPressed: () => removeRun(i)),
                            ],
                          );
                        },
                      ),
                    ),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(onPressed: addRun, child: const Text('+ Add Run'))),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: validateAndSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green500,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: Text('Save', style: TextStyle(color: AppColors.white)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onClose,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.gray500),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
