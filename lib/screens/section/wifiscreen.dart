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

    final network = widget.wifi.wifiList
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
          // Header
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

          // Known network info or password field
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
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: AppColors.themedColor(context, AppColors.gray300, AppColors.gray600),
                            ),
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
                        });
                      },
                      child: const Text('Set'),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          bottomLeft: Radius.circular(6),
                        ),
                        borderSide: BorderSide(
                          color: AppColors.themedColor(context, AppColors.gray300, AppColors.gray600),
                        ),
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

          // Connect button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue500,
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onPressed: () {},
              child: const Text('Connect'),
            ),
          ),
        ],
      ),
    );
  }
}

class WifiManager {
  List<WifiNetwork> wifiList = [];
  String? connectedSSID;
  String? selectedSSID;
  int? priority;

  void loadFakeNetworks() {
    wifiList = [
      WifiNetwork(ssid: 'Home WiFi', signal: 80, known: true, priority: 1),
      WifiNetwork(ssid: 'Office WiFi', signal: 65),
      WifiNetwork(ssid: 'CoffeeShop', signal: 45),
      WifiNetwork(ssid: 'Hidden Network', signal: 30),
      WifiNetwork(ssid: 'Neighbor WiFi', signal: 55, known: true, priority: 2),
    ];
    connectedSSID = 'Home WiFi';
  }

  @override
  String toString() {
    return 'WifiManager(connectedSSID: $connectedSSID, selectedSSID: $selectedSSID, networks: $wifiList)';
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
    final wifiList = widget.wifi.wifiList;

    if (wifiList.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No WiFi networks found.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.themedColor(context, AppColors.gray600, AppColors.gray400),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Click "Scan Networks" to refresh.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.themedColor(context, AppColors.gray500, AppColors.gray500),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
              maxCrossAxisExtent: 280,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2,
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
                    if (network.known) widget.wifi.priority = network.priority;
                  });
                },
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.themedColor(
                            context, AppColors.white, (isSelected) ? AppColors.gray900 : AppColors.gray800),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.themedColor(context, AppColors.gray200, AppColors.gray700),
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
                                    color: AppColors.themedColor(context, AppColors.gray900, AppColors.white),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.wifi,
                                color: signalColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Signal: ${network.signal}%'
                            '${network.known ? ' • Priority: ${network.priority}' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.themedColor(context, AppColors.gray500, AppColors.gray400),
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
          )),
          if (widget.wifi.selectedSSID != null)
            WifiConnectSection(
              wifi: widget.wifi,
              showPassword: false,
              passwordController: passwordController,
            ),
        ],
      ),
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
