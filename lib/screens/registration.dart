import 'package:android/classes/snackbar.dart';
import 'package:android/handle_request.dart';
import 'package:android/modals/verification.dart';
import 'package:android/screens/spray.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/colors.dart';
import 'package:android/utils/struct.dart';
import 'package:android/widgets/particle.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final dynamic user;
  final Function(dynamic newUser) updateUser;
  const AuthScreen({super.key, required this.toggleTheme, required this.user, required this.updateUser});

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

  void showTermsModal() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Terms & Conditions"),
        content: SingleChildScrollView(
          child: Text(
            "Here you can put the full terms and conditions text for AGRIBOT. "
            "Users must read and accept these before registering.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
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
    AppSnackBar.loading(context, "Trying to login...", id: "login");
    final handler = RequestHandler();

    try {
      final response = await handler.handleRequest(
        'user/login',
        body: {
          'type': 'login',
          'email': emailController.text,
          'password': passwordController.text,
        },
      );

      if (response['success'] == true) {
        final modelsResponse = await handler.handleRequest('get-model-studio', method: "GET");
        final plantsResponse = await handler.handleRequest('plant/get-plant-display', method: "GET");
        final notifications = await handler.handleRequest("notification/user/${response['user']['id']}", method: "GET");
        final foldersResponse = await handler.handleRequest('folders', method: "POST", body: {'email': response['user']['email']});

        final now = DateTime.now();
        final currentDaySlug =
            '${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.year}';

        final models = modelsResponse['success'] == true
            ? {
                'yoloObjectDetection': modelsResponse['data']['yoloObjectDetection'],
                'yoloStageClassification': modelsResponse['data']['yoloStageClassification'],
                'maskRCNNSegmentation': modelsResponse['data']['maskRCNNSegmentation'],
              }
            : {
                'yoloObjectDetection': [],
                'yoloStageClassification': [],
                'maskRCNNSegmentation': [],
              };

        final plantsJson = plantsResponse['success'] == true ? plantsResponse['plantData'] : [];
        final List<Plant> allPlants = plantsJson.map<Plant>((p) => Plant.fromJson(p)).toList();
        final Map<String, Plant> transformedPlants = {for (var plant in allPlants) plant.name: plant};

        final store = UserDataStore();
        store.user.value = response['user'];
        store.models.value = models;
        store.notifications.value = notifications['success'] == true ? notifications['notifications'] : [];
        store.allPlants.value = allPlants;
        store.transformedPlants.value = transformedPlants;
        store.folderLastFetch.value = currentDaySlug;
        if (foldersResponse['success'] == true) {
          final List<dynamic> foldersJson = foldersResponse['folders'];
          final List<FolderRecord> foldersList = foldersJson.map((f) => FolderRecord.fromJson(f)).toList();
          store.folders.value = foldersList;
        } else {
          store.folders.value = [];
        }
        await store.saveData();

        if (mounted) {
          AppSnackBar.hide(context, id: "login");
          AppSnackBar.success(context, "Login successful!");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ScannedPlantsScreen(
                toggleTheme: widget.toggleTheme,
                user: store.user.value,
                models: store.models.value,
                folders: store.folders.value,
                notifications: store.notifications.value,
                allPlants: store.allPlants.value,
                transformedPlants: store.transformedPlants.value,
                updateUser: widget.updateUser,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          AppSnackBar.hide(context, id: "login");
          AppSnackBar.error(context, response['message'] ?? "Invalid email or password.");
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.hide(context, id: "login");
        AppSnackBar.error(context, "An unexpected error occurred: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.themedColor(context, AppColors.backgroundLight, AppColors.backgroundDark);
    final cardColor = AppColors.themedColor(context, AppColors.white, AppColors.gray800);
    final textColor = AppColors.themedColor(context, AppColors.textLight, AppColors.textDark);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(children: [
        const ParticleBackground(),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 400),
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
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.green500),
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
                                    labelStyle: TextStyle(color: textColor),
                                  ),
                                  style: TextStyle(color: textColor),
                                  validator: (v) => v!.isEmpty ? "Enter your full name" : null,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: prototypeIPController,
                                  decoration: InputDecoration(
                                    labelText: "Prototype IP",
                                    labelStyle: TextStyle(color: textColor),
                                  ),
                                  style: TextStyle(color: textColor),
                                  validator: (v) => v!.isEmpty ? "Enter prototype IP" : null,
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                            crossFadeState: isRegister ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: "Email",
                              labelStyle: TextStyle(color: textColor),
                            ),
                            style: TextStyle(color: textColor),
                            validator: (v) => v!.isEmpty ? "Enter your email" : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: passwordController,
                            obscureText: !showPassword,
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: TextStyle(color: textColor),
                              suffixIcon: IconButton(
                                icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, color: textColor),
                                onPressed: () => setState(() => showPassword = !showPassword),
                              ),
                            ),
                            style: TextStyle(color: textColor),
                            validator: (v) => v!.isEmpty ? "Enter your password" : null,
                          ),
                          const SizedBox(height: 10),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              children: [
                                TextFormField(
                                  controller: confirmPasswordController,
                                  obscureText: !showConfirmPassword,
                                  decoration: InputDecoration(
                                    labelText: "Confirm Password",
                                    labelStyle: TextStyle(color: textColor),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                        color: textColor,
                                      ),
                                      onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                                    ),
                                  ),
                                  style: TextStyle(color: textColor),
                                  validator: (v) => v!.isEmpty ? "Confirm your password" : null,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Checkbox(
                                        value: acceptedTerms, onChanged: (v) => setState(() => acceptedTerms = v!)),
                                    GestureDetector(
                                      onTap: showTermsModal,
                                      child: const Text(
                                        "I agree to the Terms & Conditions",
                                        style: TextStyle(color: AppColors.green500),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            crossFadeState: isRegister ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isRegister ? sendVerificationCode : loginSubmit,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green500, minimumSize: const Size.fromHeight(45)),
                            child: Text(
                              isRegister ? "Register" : "Log In",
                              style: const TextStyle(color: AppColors.white),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (verificationCode.isNotEmpty)
                          ElevatedButton(
                              onPressed: () => showVerifyModal.value = true,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.blue500, minimumSize: const Size.fromHeight(45)),
                              child: Text("Verify Account",
                                style: const TextStyle(color: AppColors.white),
                              ),
                            ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: toggleForm,
                            child: Text(
                              isRegister
                                  ? "Already have an account? Log in here"
                                  : "Don't have an account? Register here",
                              style: const TextStyle(color: AppColors.green500),
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
