import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../utils/colors.dart';

class TutorialModal extends StatefulWidget {
  final bool show;
  final VoidCallback onClose;
  final List<Map<String, String>> tutorials;
  const TutorialModal({
    super.key,
    required this.show,
    required this.onClose,
    required this.tutorials
  });

  @override
  State<TutorialModal> createState() => _TutorialModalState();
}

class _TutorialModalState extends State<TutorialModal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  late YoutubePlayerController _ytController;
  int _selectedIndex = 0;

  void _initializePlayer() {
    _ytController = YoutubePlayerController.fromVideoId(
      videoId: YoutubePlayerController.convertUrlToId(widget.tutorials[_selectedIndex]['url']!) ?? '',
      params: const YoutubePlayerParams(
          showFullscreenButton: true, loop: true, enableCaption: true, mute: false, showControls: false),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.show) _controller.forward();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant TutorialModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.show ? _controller.forward(from: 0) : _controller.reverse();
  }

  @override
  void dispose() {
    _ytController.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show && _controller.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    final bgColor = AppColors.themedColor(context, AppColors.gray100, AppColors.gray800);
    final cardColor = AppColors.themedColor(context, AppColors.white, AppColors.gray700);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);

    return FadeTransition(
      opacity: _opacity,
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onClose,
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
              child: SafeArea(
                top: false,
                child: Material(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  elevation: 16,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Tutorial Center",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: textColor),
                              onPressed: widget.onClose,
                            ),
                          ],
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.5 * 0.7,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: YoutubePlayerScaffold(
                              controller: _ytController,
                              aspectRatio: 16 / 9,
                              builder: (context, player) {
                                return Container(
                                  color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
                                  child: player,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (int i = 0; i < widget.tutorials.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(widget.tutorials[i]['title']!),
                                    selected: _selectedIndex == i,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedIndex = i;
                                        _ytController.loadVideoById(
                                          videoId: YoutubePlayerController.convertUrlToId(widget.tutorials[i]['url']!) ?? '',
                                        );
                                      });
                                    },
                                    selectedColor: AppColors.green500,
                                    backgroundColor: cardColor,
                                    labelStyle: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: _selectedIndex == i ? Colors.white : textColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              widget.tutorials[_selectedIndex]['desc']!,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: textColor.withAlpha(230),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: widget.onClose,
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.red500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Close",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
