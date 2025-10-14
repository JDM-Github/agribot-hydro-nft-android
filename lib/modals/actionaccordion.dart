import 'package:android/classes/config.dart';
import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class ActionAccordion extends StatefulWidget {
  final ValueNotifier<bool> showSprayModal;
  final ValueNotifier<bool> showScheduleModal;
  final ValueNotifier<bool> showAddPlantModal;
  final ValueNotifier<bool> compareModal;
  final Config config;
  final Function() onExportConfig;
  final Function() onUploadConfig;
  final Function() saveConfig;
  final Function(String target) onOpenConfidence;
  final Function(String target) onOpenVersion;

  const ActionAccordion(
      {super.key,
      required this.showSprayModal,
      required this.showScheduleModal,
      required this.showAddPlantModal,
      required this.compareModal,
      required this.config,
      required this.onExportConfig,
      required this.onUploadConfig,
      required this.onOpenConfidence,
      required this.onOpenVersion,
      required this.saveConfig});

  @override
  State<ActionAccordion> createState() => _ActionAccordionState();
}

class _ActionAccordionState extends State<ActionAccordion> with SingleTickerProviderStateMixin {
  String? openSection;
  final Map<String, GlobalKey> _buttonKeys = {};
  OverlayEntry? _overlayEntry;

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _removeOverlay({bool animated = true}) {
    if (_overlayEntry != null) {
      if (animated) {
        _controller.reverse().then((_) {
          _overlayEntry?.remove();
          _overlayEntry = null;
          openSection = null;
        });
      } else {
        _overlayEntry?.remove();
        _overlayEntry = null;
        openSection = null;
      }
    } else {
      openSection = null;
    }
  }

  void _showOverlay(Widget content, GlobalKey key) {
    _removeOverlay(animated: false);

    if (key.currentContext == null) return;
    final box = key.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;

        return Material(
          color: Colors.black26,
          child: Stack(
            children: [
              // Tap outside to dismiss
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => _removeOverlay(),
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
              // Centered overlay
              Positioned(
                top: offset.dy - 10 - 80,
                left: 16,
                right: 16,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) => Opacity(
                      opacity: _opacity.value,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: child,
                      ),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: screenWidth * 0.95,
                        maxHeight: 180,
                      ),
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.themedColor(
                          context,
                          AppColors.gray100,
                          AppColors.gray900,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.center,
                                  children: (content as Wrap).children,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward(from: 0);
  }


  @override
  Widget build(BuildContext context) {
    final sections = [
      {
        'title': 'Model Actions',
        'content': Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _mediumButton(context, 'Compare Models', backgroundColor: AppColors.blue500, onPressed: () {
              _removeOverlay(animated: false);
              widget.compareModal.value = true;
            }),
            _mediumButton(context, 'ObjectDetectionModel', backgroundColor: AppColors.orange500, onPressed: () {
              _removeOverlay(animated: false);
              widget.onOpenVersion("obj");
            }),
            _mediumButton(context, 'ClassificationModel', backgroundColor: AppColors.purple500, onPressed: () {
              _removeOverlay(animated: false);
              widget.onOpenVersion("cls");
            }),
            _mediumButton(context, 'SegmentationModel', backgroundColor: AppColors.teal500, onPressed: () {
              _removeOverlay(animated: false);
              widget.onOpenVersion("seg");
            }),
          ],
        ),
      },
      {
        'title': 'Model Confidence',
        'content': Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _mediumButton(context, 'Object Detection Model (${widget.config.objectDetectionConfidence.value})',
                backgroundColor: AppColors.orange500, onPressed: () {
              _removeOverlay(animated: false);
              widget.onOpenConfidence("obj");
            }),
            _mediumButton(context, 'Classification Model (${widget.config.stageClassificationConfidence.value})',
                backgroundColor: AppColors.purple500, onPressed: () {
              _removeOverlay(animated: false);
              widget.onOpenConfidence("cls");
            }),
            _mediumButton(context, 'Segmentation Model (${widget.config.diseaseSegmentationConfidence.value})',
                backgroundColor: AppColors.teal500, onPressed: () {
              _removeOverlay(animated: false);
              widget.onOpenConfidence("seg");
            }),
          ],
        ),
      },
      // {
      //   'title': 'Configuration Actions',
      //   'content': Wrap(
      //     spacing: 6,
      //     runSpacing: 6,
      //     children: [
      //       _mediumButton(context, 'Save Configuration', backgroundColor: AppColors.green700, onPressed: () {
      //         _removeOverlay(animated: false);
      //         widget.saveConfig();
      //       }),
      //       _mediumButton(context, 'Download Configuration', backgroundColor: AppColors.yellow500, onPressed: () {
      //         _removeOverlay(animated: false);
      //         widget.onExportConfig();
      //       }),
      //       _mediumButton(context, 'Upload Configuration', backgroundColor: AppColors.red500, onPressed: () {
      //         _removeOverlay(animated: false);
      //         widget.onUploadConfig();
      //       }),
      //     ],
      //   ),
      // },
      // {
      //   'title': 'Setup Actions',
      //   'content': Wrap(
      //     spacing: 6,
      //     runSpacing: 6,
      //     children: [
      //       _mediumButton(context, 'Setup Spray', backgroundColor: AppColors.blue700, onPressed: () {
      //         setState(() {
      //           _removeOverlay(animated: true);
      //           widget.showSprayModal.value = true;
      //         });
      //       }),
      //       _mediumButton(context, 'Set Schedule', backgroundColor: AppColors.orange700, onPressed: () {
      //         setState(() {
      //           _removeOverlay(animated: false);
      //           widget.showScheduleModal.value = true;
      //         });
      //       }),
      //       _mediumButton(context, 'Add Plant', backgroundColor: AppColors.purple700, onPressed: () {
      //         setState(() {
      //           _removeOverlay(animated: false);
      //           widget.showAddPlantModal.value = true;
      //         });
      //       }),
      //     ],
      //   ),
      // },
    ];

    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: sections.map((section) {
            final keyName = section['title'] as String;
            _buttonKeys.putIfAbsent(keyName, () => GlobalKey());

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: () {
                  if (openSection == keyName) {
                    _removeOverlay();
                  } else {
                    setState(() => openSection = keyName);
                    _showOverlay(section['content'] as Widget, _buttonKeys[keyName]!);
                  }
                },
                child: _accordionButton(
                  key: _buttonKeys[keyName],
                  context: context,
                  title: keyName,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _accordionButton({
    Key? key,
    required BuildContext context,
    required String title,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray800),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.themedColor(context, AppColors.gray300, AppColors.gray700),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.themedColor(context, AppColors.textLight, AppColors.textDark),
        ),
      ),
    );
  }

  Widget _mediumButton(
    BuildContext context,
    String label, {
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final bgColor = backgroundColor ?? AppColors.green500;
    final fgColor = foregroundColor ?? AppColors.white;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        minimumSize: const Size(0, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}
