import 'dart:async';

import 'package:android/handle_request.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatefulWidget {
  final String fullName;
  final String email;

  const ProfileHeader({
    super.key,
    required this.fullName,
    required this.email,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 4, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);
    final subTextColor = AppColors.themedColor(context, Colors.grey.shade800, Colors.white70);

    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 200,
            child: ClipPath(
              clipper: CurvedBannerClipper(),
              child: Container(
                color: AppColors.themedColor(context, AppColors.gray300, AppColors.gray700).withAlpha(100),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return SizedBox(
                    height: 100,
                    child: Image.asset('assets/LOGO TEXT.webp', fit: BoxFit.contain),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                widget.fullName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 16,
                  color: subTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CurvedBannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(size.width / 2, size.height + 40, size.width, size.height - 80);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ----------------

class UserInfoSection extends StatelessWidget {
  const UserInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final containerColor = Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoColumn(context, Icons.web, "Our Email", 'https://agribothydronft@gmail.com', 'Agribot Email'),
          _buildInfoColumn(context, Icons.perm_identity, "Robot ID", 'agribot-pi4'),
          _buildInfoColumn(context, Icons.web, "Main Website", 'https://agribot-nft.netlify.app', 'Agribot Website'),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  Widget _buildInfoColumn(BuildContext context, IconData icon, String title, String value, [String? placeholder]) {
    final bool isUrl = value.startsWith("http://") || value.startsWith("https://");
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.themedColor(context, AppColors.green500, AppColors.green700),
            ),
            child: Icon(icon, size: 30, color: AppColors.white),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          isUrl
              ? GestureDetector(
                  onTap: () async => await _launchUrl(value),
                  child: Text(
                    placeholder ?? "Open Link",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.themedColor(context, AppColors.blue500, AppColors.blue500),
                    ),
                  ),
                )
              : Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: textColor.withAlpha(200)),
                ),
        ],
      ),
    );
  }
}

// -------------------

class ProfileSection extends StatefulWidget {
  const ProfileSection({super.key});

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  UserDataStore data = UserDataStore();

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.themedColor(context, AppColors.backgroundLight, AppColors.backgroundDark);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
                top: 0,
                left: 0,
                width: MediaQuery.of(context).size.width,
                height: 300,
                child: Container(
                  color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray800),
                )),
            Column(children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.themedColor(context, AppColors.gray50, AppColors.gray800),
                  borderRadius: BorderRadius.circular(70),
                ),
                child: Column(
                  children: [
                    ProfileHeader(
                      fullName: data.user.value['fullName'] ?? data.user.value['prototypeID'],
                      email: data.user.value['email'],
                    ),
                    const SizedBox(height: 5),
                    const UserInfoSection(),
                  ],
                ),
              ),
              VersionLabel(textColor: textColor),
              const SizedBox(height: 10),
            ]),
          ],
        ),
      ),
    );
  }
}

class VersionLabel extends StatefulWidget {
  final Color textColor;

  const VersionLabel({
    super.key,
    required this.textColor,
  });

  @override
  State<VersionLabel> createState() => _VersionLabelState();
}

class _VersionLabelState extends State<VersionLabel> {
  int _tapCount = 0;
  Timer? _timer;
  final String _version = '2.0.0';

  void _onTap() {
    _tapCount++;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      _tapCount = 0;
    });

    if (_tapCount >= 5) {
      _tapCount = 0;
      _showDevSwitch();
    }
  }

  Future<void> _showDevSwitch() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Developer Options",
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeInOut);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.themedColor(
                          context,
                          AppColors.white,
                          AppColors.gray800,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Developer Options",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.themedColor(
                                    context,
                                    AppColors.textLight,
                                    AppColors.textDark,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: AppColors.themedColor(
                                    context,
                                    AppColors.textLight,
                                    AppColors.textDark,
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                          Divider(
                            color: AppColors.themedColor(
                              context,
                              AppColors.gray300,
                              AppColors.gray600,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Use Live URL:",
                                style: TextStyle(
                                  color: AppColors.themedColor(
                                    context,
                                    AppColors.textLight,
                                    AppColors.textDark,
                                  ),
                                ),
                              ),
                              Switch(
                                value: RequestHandler.useLiveUrl,
                                activeColor: AppColors.green500,
                                onChanged: (val) {
                                  setModalState(() {
                                    RequestHandler.useLiveUrl = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0, right: 4.0, bottom: 12.0),
                            child: Text(
                              RequestHandler.useLiveUrl
                                  ? "Currently using the *LIVE* server:\nhttps://agribot-hydro-nft-admin.netlify.app"
                                  : "Currently using the *TEST* (subdomain) server:\nhttps://agribot-subdomain--agribot-hydro-nft-admin.netlify.live",
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: AppColors.themedColor(
                                  context,
                                  AppColors.textLight.withAlpha(200),
                                  AppColors.textDark.withAlpha(200),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: _onTap,
          child: Text(
            _version.isEmpty ? 'Version ...' : 'Version $_version',
            style: TextStyle(
              color: widget.textColor.withAlpha(180),
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
