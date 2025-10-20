import 'dart:io';

import 'package:android/classes/block.dart';
import 'package:android/classes/snackbar.dart';
import 'package:android/connection/connect.dart';
import 'package:android/connection/socketio.dart';
import 'package:android/utils/colors.dart';
import 'package:android/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedLevel = 'ALL';
  String searchQuery = '';
  bool liveUpdates = true;
  TimeOfDay startTime = TimeOfDay(hour: 0, minute: 0);
  TimeOfDay endTime = TimeOfDay(hour: 23, minute: 59);
  bool isAlreadyLoaded = false;

  List<String> allLogs = [];
  List<String> filteredLogs = [];
  Map<String, bool> collapsedGroups = {};
  Map<String, int> stats = {};
  final ScrollController _scrollController = ScrollController();

  final List<String> logLevels = [
    'ALL',
    'INFO',
    'SUCCESS',
    'WARNING',
    'ERROR',
    'DEBUG',
    'ROUTE',
    'INITIALIZE',
    'EVENT'
  ];

  late VoidCallback _logsListener;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _logsListener = () {
      allLogs = List<String>.from(Connection.logs.value);
      _filterLogs();
      _scrollToBottom();
    };
    Connection.logs.addListener(_logsListener);
  }

  @override
  void dispose() {
    Connection.logs.removeListener(_logsListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final level = prefs.getString('logs_selectedLevel');
      final q = prefs.getString('logs_searchQuery');
      final live = prefs.getBool('logs_liveUpdates');
      final sT = prefs.getString('logs_startTime');
      final eT = prefs.getString('logs_endTime');

      if (level != null) selectedLevel = level;
      if (q != null) searchQuery = q;
      if (live != null) liveUpdates = live;
      if (sT != null) startTime = _parseTimeOfDay(sT);
      if (eT != null) endTime = _parseTimeOfDay(eT);
      isAlreadyLoaded = true;
    });
  }

  Future<void> _saveSettings() async {
    if (!isAlreadyLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logs_selectedLevel', selectedLevel);
    await prefs.setString('logs_searchQuery', searchQuery);
    await prefs.setString('logs_startTime', _formatTimeOfDay(startTime));
    await prefs.setString('logs_endTime', _formatTimeOfDay(endTime));
    await prefs.setBool('logs_liveUpdates', liveUpdates);
  }

  TimeOfDay _parseTimeOfDay(String v) {
    final parts = v.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void _onDateChange(DateTime d) {
    setState(() {
      selectedDate = d;
      allLogs = [];
      filteredLogs = [];
    });
    SocketService.emit("set_log_date", {"date": DateFormat('yyyy-MM-dd').format(selectedDate)});
  }

  bool _matchesTimeRange(String line) {
    final reg = RegExp(r'\b(\d{2}:\d{2}):\d{2}\b');
    final m = reg.firstMatch(line);
    if (m == null) return true;
    final logTime = m.group(1)!; 
    final logT = _parseTimeOfDay(logTime);
    final s = startTime.hour * 60 + startTime.minute;
    final e = endTime.hour * 60 + endTime.minute;
    final L = logT.hour * 60 + logT.minute;
    return L >= s && L <= e;
  }

  void _filterLogs() {
    filteredLogs = allLogs.where((line) {
      final matchesLevel = selectedLevel == 'ALL' || line.contains(selectedLevel);
      final matchesSearch = searchQuery.trim().isEmpty ? true : line.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesTime = _matchesTimeRange(line);
      return matchesLevel && matchesSearch && matchesTime;
    }).toList();
    _computeStats();
    _saveSettings();
    setState(() {});
  }

  void _computeStats() {
    final Map<String, int> s = {
      'INFO': 0,
      'SUCCESS': 0,
      'WARNING': 0,
      'ERROR': 0,
      'DEBUG': 0,
      'ROUTE': 0,
      'INITIALIZE': 0,
      'EVENT': 0,
      'TOTAL': 0
    };
    for (final line in filteredLogs) {
      if (line.contains('INFO')) s['INFO'] = s['INFO']! + 1;
      if (line.contains('SUCCESS')) s['SUCCESS'] = s['SUCCESS']! + 1;
      if (line.contains('WARNING')) s['WARNING'] = s['WARNING']! + 1;
      if (line.contains('ERROR')) s['ERROR'] = s['ERROR']! + 1;
      if (line.contains('DEBUG')) s['DEBUG'] = s['DEBUG']! + 1;
      if (line.contains('ROUTE')) s['ROUTE'] = s['ROUTE']! + 1;
      if (line.contains('INITIALIZE')) s['INITIALIZE'] = s['INITIALIZE']! + 1;
      if (line.contains('EVENT')) s['EVENT'] = s['EVENT']! + 1;
      s['TOTAL'] = s['TOTAL']! + 1;
    }
    stats = s;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Map<String, List<String>> _groupLogs() {
    final Map<String, List<String>> groups = {};
    final reg = RegExp(r'(\d{4}-\d{2}-\d{2}\s\d{2})');
    for (final line in filteredLogs) {
      final m = reg.firstMatch(line);
      final key = m != null ? m.group(1)! : 'Other';
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(line);
    }
    return groups;
  }

  Color _backgroundColorForLine(String line, BuildContext ctx) {
    if (line.contains('ERROR')) {
      return AppColors.themedColor(ctx, AppColors.red500.withAlpha(20), AppColors.red700.withAlpha(40));
    }
    if (line.contains('WARNING')) {
      return AppColors.themedColor(ctx, AppColors.yellow500.withAlpha(30), AppColors.yellow700.withAlpha(60));
    }
    if (line.contains('SUCCESS')) {
      return AppColors.themedColor(ctx, AppColors.green500.withAlpha(20), AppColors.green700.withAlpha(40));
    }
    if (line.contains('INFO')) {
      return AppColors.themedColor(ctx, AppColors.blue500.withAlpha(20), AppColors.blue700.withAlpha(40));
    }
    if (line.contains('DEBUG')) {
      return AppColors.themedColor(ctx, AppColors.purple500.withAlpha(20), AppColors.purple700.withAlpha(40));
    }
    if (line.contains('ROUTE')) {
      return AppColors.themedColor(ctx, AppColors.teal500.withAlpha(20), AppColors.teal700.withAlpha(40));
    }
    if (line.contains('INITIALIZE')) {
      return AppColors.themedColor(ctx, AppColors.orange500.withAlpha(20), AppColors.orange700.withAlpha(40));
    }
    if (line.contains('EVENT')) {
      return AppColors.themedColor(ctx, AppColors.purple500.withAlpha(20), AppColors.purple700.withAlpha(40));
    }

    return AppColors.themedColor(ctx, AppColors.gray100, AppColors.gray800);
  }



  Future<void> _downloadLogs() async {
    try {
      AppSnackBar.loading(context, "Downloading logs...", id: "logDownload");

      final content = filteredLogs.map((l) => l.replaceAll(RegExp(r'<[^>]*>'), '')).join('\n');

      final dir = await getTemporaryDirectory();
      final fileName = 'logs_${DateFormat('yyyy-MM-dd').format(selectedDate)}.txt';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(content);

      final params = SaveFileDialogParams(
        sourceFilePath: file.path,
        fileName: fileName,
      );

      final savedPath = await FlutterFileDialog.saveFile(params: params);

      if (mounted) {
        AppSnackBar.hide(context, id: "logDownload");
        if (savedPath != null) {
          AppSnackBar.success(context, "Logs downloaded successfully.");
        } else {
          AppSnackBar.info(context, "Download cancelled.");
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.hide(context, id: "logDownload");
        AppSnackBar.error(context, "Download error: $e");
      }
    }
  }

  Future<void> _selectStartTime() async {
    final t = await showThemedTimePicker(
      context: context,
      initialTime: startTime,
    );

    if (t != null) {
      setState(() => startTime = t);
      _filterLogs();
    }
  }

  Future<void> _selectEndTime() async {
    final t = await showThemedTimePicker(
      context: context,
      initialTime: endTime,
    );

    if (t != null) {
      setState(() => endTime = t);
      _filterLogs();
    }
  }

  Future<void> _selectDate() async {
    final d = await showThemedDatePicker(
      context: context,
      initialDate: selectedDate,
    );

    if (d != null) _onDateChange(d);
  }

  @override
  Widget build(BuildContext context) {
    if (!Connection.isConnected.value) {
      return const Scaffold(body: NotConnected());
    }

    final groups = _groupLogs();
    return Scaffold(
      backgroundColor: AppColors.themedColor(context, AppColors.backgroundLight, AppColors.backgroundDark),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 40,
              color: AppColors.green500,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Logs",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download_rounded, color: Colors.white),
                        onPressed: _downloadLogs,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward_rounded, color: Colors.white),
                        onPressed: _scrollToBottom,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              color: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(context, Icons.calendar_today, DateFormat('MM/dd').format(selectedDate), _selectDate),
                    _filterChip(context, Icons.schedule, _formatTimeOfDay(startTime), _selectStartTime),
                    _filterChip(context, Icons.timelapse, _formatTimeOfDay(endTime), _selectEndTime),
                    _dropdownChip(context, Icons.filter_alt, selectedLevel, logLevels, (v) {
                      if (v == null) return;
                      setState(() => selectedLevel = v);
                      _filterLogs();
                    }),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray900),
                ),
                child: filteredLogs.isEmpty
                    ? const Center(child: Text("No logs"))
                    : ListView(
                        controller: _scrollController,
                        children: [
                          for (final entry in groups.entries)
                            ExpansionTile(
                              initiallyExpanded: true,
                              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                              childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
                              title: Text(
                                "${entry.key} (${entry.value.length})",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.green500,
                                ),
                              ),
                              children: [
                                for (final line in entry.value)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.symmetric(vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _backgroundColorForLine(line, context),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.green500.withAlpha(80)),
                                    ),
                                    child: Html(
                                      data: line,
                                      style: {
                                        "body": Style(
                                          margin: Margins.zero,
                                          padding: HtmlPaddings.zero,
                                          fontSize: FontSize(11),
                                          fontFamily: 'monospace',
                                          backgroundColor: Colors.transparent,
                                          whiteSpace: WhiteSpace.pre,
                                        ),
                                      },
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              color: AppColors.themedColor(context, AppColors.gray100, AppColors.gray700),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _stat("INFO", stats["INFO"], AppColors.green500),
                    const SizedBox(width: 8),
                    _stat("OK", stats["SUCCESS"], AppColors.teal500),
                    const SizedBox(width: 8),
                    _stat("WARN", stats["WARNING"], AppColors.yellow700),
                    const SizedBox(width: 8),
                    _stat("ERR", stats["ERROR"], AppColors.red500),
                    const SizedBox(width: 8),
                    _stat("DBG", stats["DEBUG"], AppColors.blue500),
                    const SizedBox(width: 8),
                    _stat("EVT", stats["EVENT"], AppColors.purple500),
                  ],
                ),
              ),
            )

          ],
        ),
      ),
    );
  }

  Widget _filterChip(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.themedColor(ctx, AppColors.white, AppColors.gray700),
            border: Border.all(color: AppColors.themedColor(context, AppColors.green500, AppColors.gray600) ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.green500),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownChip(
    BuildContext ctx,
    IconData icon,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.themedColor(ctx, AppColors.white, AppColors.gray700),
          border: Border.all(color: AppColors.green500),
          borderRadius: BorderRadius.circular(20),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            icon: Icon(Icons.arrow_drop_down, size: 16, color: AppColors.green500),
            dropdownColor: AppColors.themedColor(ctx, AppColors.white, AppColors.gray700),
            style: TextStyle(
              color: AppColors.themedColor(ctx, AppColors.textLight, AppColors.textDark),
              fontSize: 13,
            ),
            items: items
                .map((l) => DropdownMenuItem(
                      value: l,
                      child: Text(l),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, dynamic count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(125)),
      ),
      child: Text(
        "$label: ${count ?? 0}",
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
