import 'package:android/classes/snackbar.dart';
import 'package:android/handle_request.dart';
import 'package:android/store/data.dart';
import 'package:flutter/material.dart';
import 'package:android/utils/colors.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  final List<dynamic> notifications;

  const NotificationScreen({super.key, required this.notifications});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> filteredNotifications = [];
  String searchQuery = "";
  String selectedSort = "Newest";

  @override
  void initState() {
    super.initState();
    filteredNotifications = List.from(widget.notifications);
    _sortNotifications("Newest");
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

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat("MMM d, HH:mm").format(dt);
    } catch (_) {
      return timestamp;
    }
  }

  Future<void> _markAsRead(int index) async {
    final notif = filteredNotifications[index];
    if (notif["isRead"] == true) return;

    final store = UserDataStore();
    AppSnackBar.loading(context, "Marking notification as read...", id: "notif");

    final handler = RequestHandler();
    final id = notif['id'];

    try {
      final response = await handler.handleRequest(
        "notification/mark-read/$id",
        method: "PUT",
        body: {},
      );

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          filteredNotifications[index]["isRead"] = true;
          final mainIndex = store.notifications.value.indexWhere((n) => n['id'] == id);
          if (mainIndex != -1) {
            store.notifications.value[mainIndex]['isRead'] = true;
          }
        });
        await store.saveNotifications(store.notifications.value);

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

  void _showNotificationDetail(int index) {
    final notif = filteredNotifications[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _getTypeIcon(notif["type"] ?? "info", notif["isRead"] == true),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notif["title"] ?? "",
                style: TextStyle(fontWeight: notif["isRead"] == true ? FontWeight.normal : FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(notif["message"] ?? ""),
        ),
        actions: [
          Text(
            _formatTime(notif["createdAt"] ?? ""),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );

    // Mark as read if not already
    if (notif["isRead"] != true) _markAsRead(index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray800),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: TextStyle(
                      color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray50),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search notifications...",
                      hintStyle: TextStyle(
                        color: AppColors.themedColor(context, AppColors.gray600, AppColors.gray400),
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.themedColor(context, AppColors.gray700, AppColors.gray400),
                        size: 18,
                      ),
                      filled: true,
                      fillColor: AppColors.themedColor(context, AppColors.gray50, AppColors.gray900),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.themedColor(context, AppColors.gray500, AppColors.gray700),
                          width: 1,
                        ),
                      ),
                    ),
                    onChanged: filterNotifications,
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray900),
                  onSelected: _sortNotifications,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: "Newest",
                      child: Text(
                        "Sort by Newest",
                        style: TextStyle(
                            fontSize: 12, color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray50)),
                      ),
                    ),
                    PopupMenuItem(
                      value: "Oldest",
                      child: Text(
                        "Sort by Oldest",
                        style: TextStyle(
                            fontSize: 12, color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray50)),
                      ),
                    ),
                  ],
                  icon: Icon(Icons.sort,
                      color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray50), size: 18),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: filteredNotifications.length,
            itemBuilder: (context, index) {
              var notif = filteredNotifications[index];
              final isRead = notif["isRead"] == true;

              return Card(
                color: AppColors.themedColor(context, AppColors.gray100, AppColors.gray800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  onTap: () => _showNotificationDetail(index),
                  leading: _getTypeIcon(notif["type"] ?? "info", isRead),
                  title: Text(
                    notif["title"] ?? "",
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: AppColors.themedColor(context, AppColors.textLight, AppColors.textDark),
                    ),
                  ),
                  subtitle: Text(
                    notif["message"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.themedColor(context, AppColors.gray700, AppColors.gray300),
                    ),
                  ),
                  trailing: Icon(
                    isRead ? Icons.circle_outlined : Icons.circle,
                    size: 12,
                    color: isRead ? Colors.grey : Colors.blue,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
