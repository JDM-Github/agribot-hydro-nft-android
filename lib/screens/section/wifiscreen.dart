import 'package:android/classes/block.dart';
import 'package:android/classes/snackbar.dart';
import 'package:android/connection/all_states.dart';
import 'package:android/handle_request.dart';
import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class WifiNetwork {
  final String ssid;
  final int signal;
  final bool known;
  int priority;

  WifiNetwork({
    required this.ssid,
    required this.signal,
    this.known = false,
    this.priority = 0,
  });

  factory WifiNetwork.fromJson(Map<String, dynamic> json) {
    return WifiNetwork(
      ssid: json['ssid'] ?? '',
      signal: (json['signal'] ?? 0).toInt(),
      known: json['known'] ?? false,
      priority: json['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'signal': signal,
      'known': known,
      'priority': priority,
    };
  }

  @override
  String toString() {
    return 'WifiNetwork(ssid: $ssid, signal: $signal, known: $known, priority: $priority)';
  }
}


class WifiConnectSection extends StatefulWidget {
  final WifiManager wifi;
  final bool showPassword;
  final TextEditingController passwordController;

  const WifiConnectSection({
    super.key,
    required this.wifi,
    this.showPassword = false,
    required this.passwordController,
  });

  @override
  State<WifiConnectSection> createState() => _WifiConnectSectionState();
}

class _WifiConnectSectionState extends State<WifiConnectSection> {
  bool showPassword = false;

  @override
  void initState() {
    super.initState();
    showPassword = widget.showPassword;
  }

  @override
  Widget build(BuildContext context) {
    final selectedSSID = widget.wifi.selectedSSID;

    if (selectedSSID == null) return const SizedBox.shrink();

    final network = widget.wifi.wifiList.value
        .firstWhere((n) => n.ssid == selectedSSID, orElse: () => WifiNetwork(ssid: selectedSSID, signal: 0));

    final isKnown = network.known;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.themedColor(context, AppColors.white, AppColors.gray800),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray700.withAlpha(20),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Connect to',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.themedColor(context, AppColors.gray700, AppColors.gray200),
                ),
              ),
              Text(
                selectedSSID,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (isKnown)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This network is known. You can connect without entering a password.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.themedColor(context, AppColors.gray500, AppColors.gray400),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: network.priority.toString()),
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Priority (higher = preferred)',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.green500),
                          ),
                        ),
                        onChanged: (value) {
                          network.priority = int.tryParse(value) ?? 0;
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green500,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.wifi.priority = network.priority;
                          widget.wifi.setPriority(context);
                        });
                      },
                      child: const Text('Set',
                        style: TextStyle(color: AppColors.white)),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.passwordController,
                    obscureText: !showPassword,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Enter WiFi Password',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.green500),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.themedColor(context, AppColors.gray100, AppColors.gray600),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                    child: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: AppColors.themedColor(context, AppColors.gray500, AppColors.gray300),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue500,
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final wifi = widget.wifi;
                final password = widget.passwordController.text.trim();
                await wifi.connectNetwork(context, password);
                if (mounted) setState(() {});
              },
              child: const Text('Connect', style: TextStyle(color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class WifiManager {
  ValueNotifier<List<WifiNetwork>> wifiList = ValueNotifier([]);
  String? connectedSSID;
  String? selectedSSID;
  int? priority;
  bool _loading = false;

  Future<void> scanNetworks(BuildContext context) async {
    if (_loading) return;
    _loading = true;
    AppSnackBar.loading(context, "Scanning WiFi networks...", id: "wifi-scan");

    try {
      final handler = RequestHandler();
      final [success, data] = await handler.authFetch("wifi/scan", method: "GET");

      if (success && data["networks"] != null) {
        final networks =
            (data["networks"] as List).map((n) => WifiNetwork.fromJson(Map<String, dynamic>.from(n))).toList();
        wifiList.value = networks;
        connectedSSID = data["connected_ssid"] ?? "";
        AppSnackBar.hide(context, id: "wifi-scan");
        AppSnackBar.success(context, "Scan complete: ${wifiList.value.length} network(s) found.");
      } else {
        AppSnackBar.hide(context, id: "wifi-scan");
        AppSnackBar.error(context, "Failed to scan WiFi networks.");
      }
    } catch (e) {
      AppSnackBar.hide(context, id: "wifi-scan");
      AppSnackBar.error(context, "Error scanning WiFi: $e");
    } finally {
      _loading = false;
    }
  }

  Future<void> setPriority(BuildContext context) async {
    if (selectedSSID == null || selectedSSID!.isEmpty || priority == null) {
      AppSnackBar.error(context, "Select a network and priority first.");
      return;
    }

    if (_loading) return;
    _loading = true;

    final ssid = selectedSSID!;
    final toastId = "wifi-priority";

    AppSnackBar.loading(context, "Setting WiFi priority for $ssid...", id: toastId);
    try {
      final handler = RequestHandler();
      final [success, _] = await handler.authFetch(
        "wifi/set-priority/$ssid/$priority",
        method: "POST",
      );

      AppSnackBar.hide(context, id: toastId);
      if (success) {
        await scanNetworks(context);
        AppSnackBar.success(context, "Priority set to $priority for $ssid.");
      } else {
        AppSnackBar.error(context, "Failed to set priority for $ssid.");
      }
    } catch (e) {
      AppSnackBar.hide(context, id: toastId);
      AppSnackBar.error(context, "Error setting priority: $e");
    } finally {
      _loading = false;
    }
  }

  Future<void> connectNetwork(BuildContext context, String password) async {
    if (selectedSSID == null || selectedSSID!.isEmpty) {
      AppSnackBar.error(context, "Please select a network.");
      return;
    }

    if (_loading) return;
    _loading = true;

    final ssid = selectedSSID!;
    AppSnackBar.loading(context, "Connecting to $ssid...", id: "wifi-connect");

    try {
      final handler = RequestHandler();
      final [success, _] = await handler.authFetch(
        "wifi/connect",
        method: "POST",
        body: {"ssid": ssid, "password": password},
      );

      AppSnackBar.hide(context, id: "wifi-connect");

      if (success) {
        connectedSSID = ssid;
        selectedSSID = null;
        await scanNetworks(context);
        AppSnackBar.success(context, "Connected to $ssid.");
      } else {
        AppSnackBar.error(context, "Failed to connect to WiFi.");
      }
    } catch (e) {
      AppSnackBar.hide(context, id: "wifi-connect");
      AppSnackBar.error(context, "Connection request failed: $e");
    } finally {
      _loading = false;
    }
  }

  @override
  String toString() {
    return 'WifiManager(connectedSSID: $connectedSSID, selectedSSID: $selectedSSID, networks: ${wifiList.value})';
  }
}


class WifiSection extends StatefulWidget {
  final WifiManager wifi;
  const WifiSection({super.key, required this.wifi});

  @override
  State<WifiSection> createState() => _WifiSectionState();
}

class _WifiSectionState extends State<WifiSection> {
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
        valueListenable: AllStates.allState,
        builder: (context, state, __) {

          if (!state["conn"]) {
            return NotConnected();
          } else if (state["robot"] != 0) {
            return StopRobot(whatRunning: "wifi: robot");
          } else if (state["scan"]) {
            return StopRobot(whatRunning: "wifi: scanner");
          } else if (state["rscan"]) {
            return StopRobot(whatRunning: "wifi: robot scanner");
          } else if (state["robotLive"]) {
            return StopRobot(whatRunning: "wifi: robot live");
          } else if (state["live"] != 0) {
            return StopRobot(whatRunning: "wifi: live");
          }

          return ValueListenableBuilder<List<WifiNetwork>>(
            valueListenable: widget.wifi.wifiList,
            builder: (context, wifiList, _) {
              if (wifiList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No WiFi networks found.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.themedColor(
                            context,
                            AppColors.gray600,
                            AppColors.gray400,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Click "Scan Networks" to refresh.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.themedColor(
                            context,
                            AppColors.gray500,
                            AppColors.gray500,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  children: [
                    Flexible(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: wifiList.length,
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.8,
                        ),
                        itemBuilder: (context, index) {
                          final network = wifiList[index];
                          final isConnected = widget.wifi.connectedSSID == network.ssid;
                          final isSelected = widget.wifi.selectedSSID == network.ssid;

                          Color signalColor;
                          if (network.signal >= 70) {
                            signalColor = AppColors.green500;
                          } else if (network.signal >= 40) {
                            signalColor = AppColors.yellow500;
                          } else {
                            signalColor = AppColors.red500;
                          }

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                widget.wifi.selectedSSID = network.ssid;
                                if (network.known) {
                                  widget.wifi.priority = network.priority;
                                }
                              });
                            },
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.themedColor(
                                      context,
                                      isSelected ? AppColors.gray100 : AppColors.white,
                                      isSelected ? AppColors.gray900 : AppColors.gray800,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.themedColor(
                                        context,
                                        AppColors.gray200,
                                        AppColors.gray700,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gray700.withAlpha(20),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              network.ssid.isNotEmpty ? network.ssid : 'Hidden Network',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.themedColor(
                                                  context,
                                                  AppColors.gray900,
                                                  AppColors.white,
                                                ),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(Icons.wifi, color: signalColor),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Signal: ${network.signal}%'
                                        '${network.known ? ' • Priority: ${network.priority}' : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.themedColor(
                                            context,
                                            AppColors.gray500,
                                            AppColors.gray400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isConnected)
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: _StatusBadge(
                                      text: 'Connected',
                                      color: AppColors.blue500,
                                    ),
                                  )
                                else if (isSelected)
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: _StatusBadge(
                                      text: 'Selected',
                                      color: AppColors.green500,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (widget.wifi.selectedSSID != null)
                      WifiConnectSection(
                        wifi: widget.wifi,
                        showPassword: false,
                        passwordController: passwordController,
                      ),
                  ],
                ),
              );
            },
          );
        }
    );
  }
}


class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.gray700.withAlpha(20), blurRadius: 2)],
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
