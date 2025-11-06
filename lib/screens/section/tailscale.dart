import 'package:android/classes/default.dart';
import 'package:android/classes/snackbar.dart';
import 'package:android/handle_request.dart';
import 'package:android/modals/manualregister.dart';
import 'package:android/modals/registerdevice.dart';
import 'package:android/modals/renamedevice.dart';
import 'package:android/modals/requesttailscale.dart';
import 'package:android/modals/tutorialmodal.dart';
import 'package:android/requests/update.dart';
import 'package:android/store/data.dart';
import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class TailscaleSection extends StatefulWidget {
  final Map<String, dynamic> user;
  final Set<void> Function() show;
  final Set<void> Function() hide;
  const TailscaleSection({super.key, required this.user, required this.show, required this.hide});

  @override
  State<TailscaleSection> createState() => TailscaleSectionState();
}

class TailscaleSectionState extends State<TailscaleSection> {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _registerIpController = TextEditingController();
  final TextEditingController _registerHostController = TextEditingController();

  late List<dynamic> _tsDevices = [];
  Map<String, dynamic>? _selectedDevice;
  ValueNotifier<bool> showRequest = ValueNotifier(false);
  ValueNotifier<bool> showRegister = ValueNotifier(false);
  ValueNotifier<bool> showManualReg = ValueNotifier(false);
  ValueNotifier<bool> renameModal = ValueNotifier(false);
  ValueNotifier<bool> showTutorial = ValueNotifier(false);

  UserDataStore data = UserDataStore();
  String oldName = "";

  @override
  void initState() {
    super.initState();
    setState(() {
      _tsDevices = data.tailscales.value;
    });
  }

  Future<void> forceSync() async {
    AppSnackBar.loading(context, "Force syncing tailscale devices...", id: "force-sync");
    // await CustomUpdater.checkCustomUpdate(
    //   state: this,
    //   deviceID: data.uuid.value,
    //   willUpdateTailscale: true,
    // );
    await fetchDevices();
    if (mounted) {
      AppSnackBar.hide(context, id: "force-sync");
      AppSnackBar.success(context, "Force sync of tailscale devices is successful!");
    }
    updateTailscale();
  }

  void updateTailscale() {
    _tsDevices = data.tailscales.value;
  }

  Future<void> fetchDevices() async {
    final handler = RequestHandler();
    AppSnackBar.loading(context, "Fetching devices...", id: "tailscale-fetch");
    try {
      final response = await handler.handleRequest('tailscale/auth-key/${widget.user['id']}', method: "GET");
      if (mounted) {
        AppSnackBar.hide(context, id: "tailscale-fetch");
      }
      if (response['success'] == true) {
        final List<dynamic> devices = response['devices'] ?? [];
        setState(() {
          _tsDevices = devices.map((d) => Map<String, dynamic>.from(d)).toList();
        });
        await data.saveTailscale(devices);
        if (mounted) {
          AppSnackBar.success(context, "Devices updated.");
        }
      } else {
        if (mounted) {
          AppSnackBar.error(context, response['message'] ?? "Failed to fetch devices");
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.hide(context, id: "tailscale-fetch");
        AppSnackBar.error(context, "Error fetching devices: $e");
      }
    }
  }

  Future<void> requestAuthKey(String deviceName) async {
    if (deviceName.isEmpty) {
      AppSnackBar.error(context, "Device name is required.");
      return;
    }

    final handler = RequestHandler();
    AppSnackBar.loading(context, "Requesting auth key...", id: "tailscale-request");
    try {
      final response = await handler.handleRequest(
        'tailscale/auth-key',
        method: "POST",
        body: {'id': widget.user['id'], 'deviceName': deviceName},
      );
      if (mounted) {
        AppSnackBar.hide(context, id: "tailscale-request");
      }

      if (response['success'] == true) {
        if (mounted) {
          AppSnackBar.success(context, "Auth key created!");
        }
        await fetchDevices();
      } else {
        if (mounted) {
          AppSnackBar.error(context, response['message'] ?? "Failed to create auth key");
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.hide(context, id: "tailscale-request");
        AppSnackBar.error(context, "Error creating auth key: $e");
      }
    }
  }

  Future<void> _setRegister(String ip, String hostName) async {
    final handler = RequestHandler();
    AppSnackBar.loading(context, "Registering ${_selectedDevice?['device-name']}...", id: "tailscale-register");
    UserDataStore data = UserDataStore();
    try {
      final response = await handler.handleRequest(
        'tailscale/register',
        method: 'POST',
        body: {
          'id': data.user.value['id'],
          'ip': ip.trim(),
          'deviceName': _selectedDevice?['device-name'],
          'hostName': hostName,
        },
      );
      if (mounted) {
        AppSnackBar.hide(context, id: "tailscale-register");
      }

      if (response['success'] == true) {
        if (mounted) {
          AppSnackBar.success(context, "Device registered successfully!");
        }
        await fetchDevices();
        setState(() {
          _selectedDevice = null;
        });
      } else {
        if (mounted) {
          AppSnackBar.error(context, response['message'] ?? "Failed to register device");
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.hide(context, id: "tailscale-register");
        AppSnackBar.error(context, "Error registering device: $e");
      }
    }
  }

  Future<void> _manuallyRegister(String ip, String hostName, String deviceName) async {
    final handler = RequestHandler();
    AppSnackBar.loading(context, "Registering ${_selectedDevice?['device-name']}...",
        id: "tailscale-manually-register");
    UserDataStore data = UserDataStore();
    try {
      final response = await handler.handleRequest(
        'tailscale/manual-register',
        method: 'POST',
        body: {
          'id': data.user.value['id'],
          'hostName': hostName,
          'ip': ip.trim(),
          'deviceName': deviceName,
        },
      );
      if (mounted) {
        AppSnackBar.hide(context, id: "tailscale-manually-register");
      }

      if (response['success'] == true) {
        if (mounted) {
          AppSnackBar.success(context, "Device registered successfully!");
        }
        await fetchDevices();
        setState(() {
          _selectedDevice = null;
        });
      } else {
        if (mounted) {
          AppSnackBar.error(context, response['message'] ?? "Failed to register device");
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.hide(context, id: "tailscale-manually-register");
        AppSnackBar.error(context, "Error registering device: $e");
      }
    }
  }

  Future<void> _renameDevice(String deviceName, String oldName) async {
    final handler = RequestHandler();
    AppSnackBar.loading(context, "Renaming $oldName Device...",
        id: "tailscale-rename");
    UserDataStore data = UserDataStore();
    try {
      final response = await handler.handleRequest(
        'tailscale/rename',
        method: 'POST',
        body: {
          'id': data.user.value['id'],
          'oldName': oldName,
          'newName': deviceName,
        },
      );
      if (mounted) {
        AppSnackBar.hide(context, id: "tailscale-rename");
      }

      if (response['success'] == true) {
        if (mounted) {
          AppSnackBar.success(context, "Device renamed successfully!");
        }
        await fetchDevices();
        setState(() {
          _selectedDevice = null;
        });
      } else {
        if (mounted) {
          AppSnackBar.error(context, response['message'] ?? "Failed to rename device");
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.hide(context, id: "tailscale-rename");
        AppSnackBar.error(context, "Error renaming device: $e");
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppSnackBar.success(context, "Copied to clipboard!");
  }

  Future<void> openTutorial(String type) async {
    final pcUrl = Uri.parse('https://www.youtube.com/watch?v=YOUR_PC_VIDEO_ID');
    final androidUrl = Uri.parse('https://www.youtube.com/watch?v=YOUR_ANDROID_VIDEO_ID');

    final url = type == 'pc' ? pcUrl : androidUrl;
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppSnackBar.error(context, "Could not open tutorial link.");
      }
    }
  }

  Widget _buildDeviceTile(Map<String, dynamic> device) {
    final bool isRegistered = device['isRegistered'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.themedColor(context, AppColors.white, AppColors.gray800),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Expanded(
              child: Text(
                device['device-name'] ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.themedColor(context, AppColors.gray900, AppColors.gray100),
                ),
              ),
            ),
            if (!isRegistered)
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.show();
                    _selectedDevice = device;
                    showRegister.value = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blue500,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'REGISTER',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isRegistered ? AppColors.green500 : AppColors.orange500,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isRegistered ? 'Registered' : 'Pending',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (!isRegistered) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: AppColors.themedColor(
                    context,
                    AppColors.gray100.withAlpha(200),
                    AppColors.gray700.withAlpha(140),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        device['authkey'] ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.themedColor(context, AppColors.gray800, AppColors.gray200),
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _copyToClipboard(device['authkey'] ?? ''),
                      child: const Text(
                        "Copy",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
            Row(children: [
              Expanded(
                  child: Text(
                'IP: ${device['ip'] ?? '-'}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.themedColor(context, AppColors.gray600, AppColors.gray400),
                ),
              )),
              GestureDetector(
                onTap: () {
                  widget.show();
                  oldName = device['device-name'] ?? 'Unknown';
                  renameModal.value = true;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purple500,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'RENAME',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int deviceCount = _tsDevices.length;

    return Scaffold(
      backgroundColor: AppColors.themedColor(context, AppColors.backgroundLight, AppColors.backgroundDark),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.themedColor(context, AppColors.white, AppColors.gray900),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '🌐 Connected Tailscale Devices',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final url = Uri.parse('https://tailscale.com/download');
                                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                  if (mounted) {
                                    AppSnackBar.error(context, "Can't open Tailscale download page");
                                  }
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.blue500,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Download',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$deviceCount/5 unregistered devices in use',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.themedColor(
                              context,
                              AppColors.gray700,
                              AppColors.gray400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _tsDevices.isEmpty
                        ? Center(
                            child: Text(
                              'No devices connected yet.',
                              style: TextStyle(
                                color: AppColors.themedColor(context, AppColors.gray600, AppColors.gray400),
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _tsDevices.length,
                            padding: const EdgeInsets.only(top: 5, bottom: 20),
                            separatorBuilder: (_, __) => Divider(
                              color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final device = _tsDevices[index];
                              return _buildDeviceTile(device);
                            },
                          ),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: showRequest,
              builder: (context, value, child) {
                return value
                    ? RequestAuthKeyModal(
                        show: true,
                        onClose: () {
                          showRequest.value = false;
                          widget.hide();
                        },
                        onRequest: (String deviceName) {
                          showRequest.value = false;
                          requestAuthKey(deviceName);
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: showRegister,
              builder: (context, value, child) {
                return value
                    ? RegisterDeviceModal(
                        show: true,
                        onClose: () {
                          showRegister.value = false;
                          widget.hide();
                        },
                        onConfirm: (String ip, String hostName) {
                          _setRegister(ip, hostName);
                        },
                        deviceName: _selectedDevice?['device-name'],
                      )
                    : const SizedBox.shrink();
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: showManualReg,
              builder: (context, value, child) {
                return value
                    ? ManualRegisterModal(
                        show: true,
                        onClose: () {
                          showManualReg.value = false;
                          widget.hide();
                        },
                        onConfirm: (String ip, String hostName, String deviceName) {
                          _manuallyRegister(ip, hostName, deviceName);
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: renameModal,
              builder: (context, value, child) {
                return value
                    ? RenameDeviceModal(
                        show: true,
                        oldName: oldName,
                        onClose: () {
                          renameModal.value = false;
                          widget.hide();
                          oldName = '';
                        },
                        onRequest: (String deviceName) {
                          _renameDevice(deviceName, oldName);
                        },
                      )
                    : const SizedBox.shrink();
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: showTutorial,
              builder: (context, value, child) {
                return value
                    ? TutorialModal(
                        show: value,
                        onClose: () {
                          widget.hide();
                          showTutorial.value = false;
                        },
                        tutorials: [
                          {
                            "title": "Android Tutorial",
                            "url": "https://www.youtube.com/watch?v=1ukSR1GRtMU",
                            "desc": "Learn the basics of how to use this system effectively."
                          },
                          {
                            "title": "PC Tutorial",
                            "url": "https://www.youtube.com/watch?v=5VbAwhBBKGA",
                            "desc": "Understand how to configure and schedule your sprays properly."
                          },
                        ],
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _registerIpController.dispose();
    _registerHostController.dispose();
    super.dispose();
  }
}
