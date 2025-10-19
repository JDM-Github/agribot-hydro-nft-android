import 'package:android/api/auth.dart';
import 'package:android/classes/default.dart';
import 'package:android/classes/snackbar.dart';
import 'package:android/handle_request.dart';
import 'package:android/modals/verification.dart';
import 'package:android/screens/spray.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/colors.dart';
import 'package:android/utils/struct.dart';
import 'package:android/widgets/particle.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const AuthScreen({super.key, required this.toggleTheme});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool isRegister = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool acceptedTerms = false;
  ValueNotifier<bool> showVerifyModal = ValueNotifier(false);
  String verificationCode = "";

  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController prototypeIPController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  void toggleForm() => setState(() => isRegister = !isRegister);

  Future<void> showTermsModal(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Terms & Conditions",
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
                color: AppColors.themedColor(context, AppColors.white, AppColors.gray800),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Terms & Conditions",
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
                      const SizedBox(height: 12),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: SingleChildScrollView(
                          child: Text(
                            "Here you can put the full Terms and Conditions text for AGRIBOT.\n\n"
                            "Users must read and accept these before registering.\n\n"
                            "1. Data collected through the app will be stored securely.\n"
                            "2. Users are responsible for maintaining the confidentiality of their credentials.\n"
                            "3. AGRIBOT reserves the right to modify terms at any time.\n"
                            "4. Continued use of the app implies acceptance of updated terms.\n\n"
                            "Please read carefully before proceeding.",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.themedColor(
                                context,
                                AppColors.textLight,
                                AppColors.textDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.green500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Close"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }


  Future<void> sendVerificationCode() async {
    if (fullNameController.text.isEmpty) {
      AppSnackBar.error(context, "Full name is required.");
      return;
    }
    if (prototypeIPController.text.isEmpty) {
      AppSnackBar.error(context, "Prototype IP is required.");
      return;
    }
    if (emailController.text.isEmpty) {
      AppSnackBar.error(context, "Email is required.");
      return;
    }
    if (passwordController.text.isEmpty) {
      AppSnackBar.error(context, "Password is required.");
      return;
    }
    if (!acceptedTerms) {
      AppSnackBar.error(context, "You must accept the Terms & Conditions.");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      AppSnackBar.error(context, "Passwords do not match.");
      return;
    }

    AppSnackBar.loading(context, "Sending verification code...", id: "verify");
    final handler = RequestHandler();
    try {
      final String email = emailController.text;
      final response = await handler.handleRequest(
        'user/send-code',
        body: {'email': email.trim(), 'fullName': fullNameController.text, 'prototypeID': prototypeIPController.text},
      );
      if (response['success'] == true) {
        setState(() {
          showVerifyModal.value = true;
          verificationCode = response['code'];
        });
        if (mounted) {
          AppSnackBar.hide(context, id: "verify");
          AppSnackBar.success(context, "Verification code sent to $email.");
        }
      } else {
        if (mounted) {
          AppSnackBar.hide(context, id: "verify");
          AppSnackBar.error(
            context,
            response['message'] ?? "Failed to send verification code.",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.hide(context, id: "verify");
        AppSnackBar.error(context, "An unexpected error occurred: $e");
      }
    }
  }

  Future<void> registerSubmit() async {
    AppSnackBar.loading(context, "Trying to register...", id: "register");
    final handler = RequestHandler();
    setState(() {
      verificationCode = "";
    });

    try {
      final response = await handler.handleRequest(
        'user/create',
        body: {
          'prototypeID': prototypeIPController.text.trim(),
          'fullName': fullNameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
        },
      );

      if (response['success'] == true) {
        if (mounted) {
          AppSnackBar.hide(context, id: "register");
          AppSnackBar.success(context, "Registration successful! Please log in.");
        }
        prototypeIPController.clear();
        fullNameController.clear();
        emailController.clear();
        passwordController.clear();
        confirmPasswordController.clear();
        toggleForm();
      } else {
        if (mounted) {
          AppSnackBar.hide(context, id: "register");
          AppSnackBar.error(
            context,
            response['message'] ?? "Registration failed. Please try again.",
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.hide(context, id: "register");
        AppSnackBar.error(context, "An unexpected error occurred: $e");
      }
    }
  }

  Future<void> loginSubmit() async {
    UserDataStore data = UserDataStore();
    final auth = AuthService();
    final uuid = data.uuid.value != "" ? data.uuid.value : Uuid().v4();
    final res =
        await auth.login(this, {'email': emailController.text, 'password': passwordController.text, 'deviceID': uuid});
    if (res['success'] == true) {
      DefaultConfig newConfig = res['data'];
      final Map<String, Plant> transformedPlants = {for (var plant in newConfig.plants) plant.name: plant};

      final now = DateTime.now();
      final currentDaySlug = '${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.year}';

      data.userData.value = newConfig;
      data.user.value = newConfig.user;
      data.models.value = newConfig.models;
      data.notifications.value = newConfig.notifications;
      data.allPlants.value = newConfig.plants;
      data.transformedPlants.value = transformedPlants;
      data.folderLastFetch.value = currentDaySlug;
      data.folders.value = newConfig.folders;
      data.tailscales.value = newConfig.tailscaleDevices;
      data.uuid.value = uuid;
      await data.saveData();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ScannedPlantsScreen(
              toggleTheme: widget.toggleTheme,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.themedColor(context, AppColors.backgroundLight, AppColors.backgroundDark);
    final cardColor = AppColors.themedColor(context, AppColors.white, AppColors.gray800);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(children: [
        const ParticleBackground(),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(28),
                constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black12, spreadRadius: 2)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/LOGO TEXT.webp', width: 200, height: 60, fit: BoxFit.cover),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        isRegister ? "Create Your Account" : "Login to Your Account",
                        key: ValueKey(isRegister),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.green500),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              children: [
                                TextFormField(
                                  controller: fullNameController,
                                  decoration: InputDecoration(
                                    labelText: "Full Name",
                                    labelStyle: TextStyle(color: textColor, fontSize: 14),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(color: AppColors.green500, width: 1.5),
                                    ),
                                  ),
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  validator: (v) => v!.isEmpty ? "Enter your full name" : null,
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: prototypeIPController,
                                  decoration: InputDecoration(
                                    labelText: "Prototype IP",
                                    labelStyle: TextStyle(color: textColor, fontSize: 14),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(color: AppColors.green500, width: 1.5),
                                    ),
                                  ),
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  validator: (v) => v!.isEmpty ? "Enter prototype IP" : null,
                                ),
                                const SizedBox(height: 5),
                              ],
                            ),
                            crossFadeState: isRegister ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: "Email",
                              labelStyle: TextStyle(color: textColor, fontSize: 14),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: AppColors.green500, width: 1.5),
                              ),
                            ),
                            style: TextStyle(color: textColor, fontSize: 14),
                            validator: (v) => v!.isEmpty ? "Enter your email" : null,
                          ),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: passwordController,
                            obscureText: !showPassword,
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: TextStyle(color: textColor, fontSize: 14),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: AppColors.green500, width: 1.5),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showPassword ? Icons.visibility_off : Icons.visibility,
                                  color: textColor,
                                  size: 18,
                                ),
                                onPressed: () => setState(() => showPassword = !showPassword),
                              ),
                            ),
                            style: TextStyle(color: textColor, fontSize: 14),
                            validator: (v) => v!.isEmpty ? "Enter your password" : null,
                          ),
                          const SizedBox(height: 5),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              children: [
                                TextFormField(
                                  controller: confirmPasswordController,
                                  obscureText: !showConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: "Confirm Password",
                                    labelStyle: TextStyle(color: textColor, fontSize: 14),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(color: AppColors.green500, width: 1.5),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                        color: textColor,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                                    ),
                                  ),
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  validator: (v) => v!.isEmpty ? "Confirm your password" : null,
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Checkbox(
                                        activeColor: AppColors.green500,
                                        checkColor: Colors.white,
                                        value: acceptedTerms,
                                        onChanged: (v) => setState(() => acceptedTerms = v!)),
                                    GestureDetector(
                                      onTap: () => showTermsModal(context),
                                      child: const Text(
                                        "I agree to the Terms & Conditions",
                                        style: TextStyle(color: AppColors.green500, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            crossFadeState: isRegister ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: isRegister ? sendVerificationCode : loginSubmit,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green500,
                                minimumSize: const Size.fromHeight(36),
                                maximumSize: const Size.fromHeight(36)),
                            child: Text(
                              isRegister ? "Register" : "Log In",
                              style: const TextStyle(color: AppColors.white),
                            ),
                          ),
                          if (verificationCode.isNotEmpty) const SizedBox(height: 5),
                          if (verificationCode.isNotEmpty)
                            ElevatedButton(
                              onPressed: () => showVerifyModal.value = true,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.blue500,
                                  minimumSize: const Size.fromHeight(36),
                                  maximumSize: const Size.fromHeight(36)),
                              child: Text(
                                "Verify Account",
                                style: const TextStyle(color: AppColors.white),
                              ),
                            ),
                          const SizedBox(height: 5),
                          TextButton(
                            onPressed: toggleForm,
                            child: Text(
                              isRegister
                                  ? "Already have an account? Log in here"
                                  : "Don't have an account? Register here",
                              style: const TextStyle(color: AppColors.green500, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ValueListenableBuilder<bool>(
            valueListenable: showVerifyModal,
            builder: (context, value, child) {
              return value
                  ? VerificationCodeModal(
                      show: showVerifyModal.value,
                      email: emailController.text,
                      onVerify: (code) async {
                        if (code == verificationCode) {
                          showVerifyModal.value = false;
                          await registerSubmit();
                        }
                      },
                      onClose: () => setState(() => showVerifyModal.value = false),
                    )
                  : const SizedBox.shrink();
            }),
      ]),
    );
  }
}
