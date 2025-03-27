import 'package:android/utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class ProfileHeader extends StatefulWidget {
  const ProfileHeader({super.key});

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
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 1,
            height: 180,
            child: ClipPath(
              clipper: CurvedBannerClipper(),
              child: Container(color: AppColors.gray900),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(100),
                          blurRadius: _glowAnimation.value,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage('assets/images/profile.jpg'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                "John Doe",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "johndoe@email.com",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
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
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height + 20, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ----------------

class UserInfoSection extends StatelessWidget {
  final String accountId;
  final String modelVersion;
  final String joinedDate;

  const UserInfoSection({
    super.key,
    required this.accountId,
    required this.modelVersion,
    required this.joinedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoColumn(Icons.perm_identity, "Account ID", accountId),
          _buildInfoColumn(Icons.memory, "Model", modelVersion),
          _buildInfoColumn(Icons.calendar_today, "Joined", joinedDate),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String title, String value) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
            child: Icon(icon, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray700,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.gray800,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Column(
                children: [
                  ProfileHeader(),
                  const SizedBox(height: 5),
                  const UserInfoSection(
                    accountId: '12324',
                    modelVersion: '23.4',
                    joinedDate: 'June 16 2004',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 100,
                      child: Image.asset('assets/LOGO TEXT.webp', fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Need Help?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHelpLink(Icons.email, "Our Email", "mailto:support@example.com"),
                        const SizedBox(width: 12),
                        _buildHelpLink(Icons.book, "Documentation", "https://docs.example.com"),
                        const SizedBox(width: 12),
                        _buildHelpLink(Icons.public, "Main Website", "https://www.example.com"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  Widget _buildHelpLink(IconData icon, String title, String url) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.themedColor(context, AppColors.green500, AppColors.green500),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => _launchUrl(url),
          style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
          child: Text(
            title,
          ),
        ),
      ],
    );
  }
}
