import 'package:android/classes/snackbar.dart';
import 'package:android/handle_request.dart';
import 'package:android/modals/notification_detail.dart';
import 'package:android/store/data.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';

class NotificationScreen extends StatefulWidget {
  final List<dynamic> notifications;
  final Set<void> Function() hide;

  const NotificationScreen({super.key, required this.notifications, required this.hide});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  List<dynamic> filteredNotifications = [];
  dynamic targetNotif;
  int selectedIndex = 0;
  String searchQuery = "";
  String selectedSort = "Newest";
  ValueNotifier<bool> showNotifModal = ValueNotifier(false);
  UserDataStore data = UserDataStore();
  late final AnimationController _controller;
  late final List<Animation<Offset>> _animations;

  @override
  void initState() {
    super.initState();
    filteredNotifications = List.from(widget.notifications);
    _sortNotifications("Newest");

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _animations = List.generate(filteredNotifications.length, (index) {
      final total = filteredNotifications.length;
      final start = index / total;
      final end = (start + 0.5 / total).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
    _controller.forward();
  }

  void filterNotifications(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredNotifications = widget.notifications.where((notif) {
        return notif["title"].toString().toLowerCase().contains(searchQuery) ||
            notif["message"].toString().toLowerCase().contains(searchQuery);
      }).toList();
      _sortNotifications(selectedSort);
    });
  }

  void _sortNotifications(String criteria) {
    setState(() {
      selectedSort = criteria;
      if (criteria == "Newest") {
        filteredNotifications.sort((a, b) => DateTime.parse(b["createdAt"]).compareTo(DateTime.parse(a["createdAt"])));
      } else {
        filteredNotifications.sort((a, b) => DateTime.parse(a["createdAt"]).compareTo(DateTime.parse(b["createdAt"])));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Icon _getTypeIcon(String type, bool isRead) {
    Color baseColor;
    switch (type) {
      case "success":
        baseColor = Colors.green;
        break;
      case "warning":
        baseColor = Colors.orange;
        break;
      case "error":
        baseColor = Colors.red;
        break;
      case "system":
        baseColor = Colors.blueGrey;
        break;
      default:
        baseColor = Colors.blue;
    }
    return Icon(
      Icons.circle,
      color: isRead ? baseColor.withAlpha(200) : baseColor,
      size: 14,
    );
  }

  Future<void> _markAsRead(int index) async {
    final notif = filteredNotifications[index];
    if (notif["isRead"] == true) return;
    AppSnackBar.loading(context, "Marking notification as read...", id: "notif");

    final data = UserDataStore();
    final handler = RequestHandler();
    final id = notif['id'];

    try {
      final response = await handler.handleRequest(
        "notification/mark-read",
        method: "POST",
        body: {'id': data.user.value['id'], 'notifId': id, 'deviceID': data.uuid.value},
      );

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          filteredNotifications[index]["isRead"] = true;
          final mainIndex = data.notifications.value.indexWhere((n) => n['id'] == id);
          if (mainIndex != -1) {
            data.notifications.value[mainIndex]['isRead'] = true;
          }
        });
        await data.saveNotifications(data.notifications.value);
        if (mounted) {
          AppSnackBar.hide(context, id: "notif");
          AppSnackBar.success(context, "Notification marked successfully.");
        }
      } else {
        if (mounted) {
          AppSnackBar.hide(context, id: "notif");
          AppSnackBar.error(context, response['message'] ?? "Failed to mark notification.");
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.hide(context, id: "notif");
      AppSnackBar.error(context, "An unexpected error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search Folders...",
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: AppColors.gray600)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.green500),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onChanged: filterNotifications,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (filteredNotifications.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications, size: 60, color: AppColors.gray500),
                    const SizedBox(height: 12),
                    Text(
                      "No notifications",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (filteredNotifications.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                itemCount: filteredNotifications.length,
                itemBuilder: (context, index) {
                  final notif = filteredNotifications[index];
                  final isRead = notif["isRead"] == true;

                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _controller.value >= (index * 0.05) ? 1 : 0,
                        child: SlideTransition(
                          position: _animations[index],
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(30),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          setState(() {
                            targetNotif = notif;
                            selectedIndex = index;
                          });
                          showNotifModal.value = true;
                          await _markAsRead(index);
                        },
                        child: Row(
                          children: [
                            _getTypeIcon(notif["type"] ?? "info", isRead),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif["title"] ?? "",
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                      color: AppColors.themedColor(context, AppColors.textLight, AppColors.textDark),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    notif["message"] ?? "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.themedColor(context, AppColors.gray700, AppColors.gray300),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isRead ? Icons.circle_outlined : Icons.circle,
                              size: 12,
                              color: isRead ? Colors.grey : Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      ValueListenableBuilder<bool>(
          valueListenable: showNotifModal,
          builder: (context, value, child) {
            return value
                ? NotificationDetailModal(
                    show: true,
                    onClose: () {
                      widget.hide();
                      showNotifModal.value = false;
                    },
                    notification: targetNotif,
                  )
                : const SizedBox.shrink();
          }),
    ]);
  }
}
