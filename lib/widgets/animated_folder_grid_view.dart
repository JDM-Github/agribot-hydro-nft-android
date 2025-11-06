import 'package:android/classes/snackbar.dart';
import 'package:android/handle_request.dart';
import 'package:android/screens/section/folderdetail.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/colors.dart';
import 'package:android/utils/struct.dart';
import 'package:flutter/material.dart';

class AnimatedGridView extends StatefulWidget {
  final List<FolderRecord> records;
  final String email;

  const AnimatedGridView({
    super.key,
    required this.records,
    required this.email,
  });

  @override
  State<AnimatedGridView> createState() => _AnimatedGridViewState();
}

class _AnimatedGridViewState extends State<AnimatedGridView> {
  Future<void> _openFolder(String slug) async {
    final folder = widget.records.firstWhere((f) => f.slug == slug);
    UserDataStore store = UserDataStore();

    final now = DateTime.now();
    final currentDaySlug = '${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.year}';

    List<Map<String, dynamic>>? images;
    if (slug != currentDaySlug && store.folderImages.value.containsKey(slug)) {
      images = store.folderImages.value[slug];
    }

    final handler = RequestHandler();
    if (images == null) {
      AppSnackBar.loading(context, "Loading folder images...", id: "folder");
      try {
        final email = widget.email;
        if (email.isEmpty) {
          AppSnackBar.hide(context, id: "folder");
          AppSnackBar.error(context, "User email is missing");
          return;
        }

        final response = await handler.handleRequest(
          "folder-images/$slug",
          method: "POST",
          body: {'email': email},
        );

        if (mounted) AppSnackBar.hide(context, id: "folder");

        if (response['success'] == true) {
          final imagesJson = response['images'] as List<dynamic>;
          images = imagesJson.map((img) => img as Map<String, dynamic>).toList();
          final cached = store.folderImages.value;
          store.folderImages.value = {...cached, slug: images};
          await store.saveData();
        } else {
          if (mounted) {
            AppSnackBar.error(context, response['message'] ?? "Failed to load folder images");
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          AppSnackBar.hide(context, id: "folder");
          AppSnackBar.error(context, "An error occurred: $e");
        }
        return;
      }
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FolderDetailPage(
            slug: slug,
            folderName: folder.name,
            images: images!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: widget.records.length,
      itemBuilder: (context, index) {
        final record = widget.records[index];

        return GestureDetector(
          onTap: () => _openFolder(record.slug),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.themedColor(
                      context,
                      AppColors.gray100,
                      AppColors.gray800.withAlpha(100),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: record.imageUrl.isNotEmpty
                        ? Image.network(record.imageUrl, fit: BoxFit.fill)
                        : Icon(
                            Icons.folder,
                            size: 80,
                            color: AppColors.themedColor(
                              context,
                              AppColors.green500,
                              AppColors.gray300,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record.date,
                style: TextStyle(
                  color: AppColors.themedColor(
                    context,
                    AppColors.gray600,
                    AppColors.gray400,
                  ),
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
