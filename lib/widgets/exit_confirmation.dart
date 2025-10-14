import 'package:flutter/material.dart';

class DoubleBackToExitWrapper extends StatefulWidget {
  final Widget child;
  const DoubleBackToExitWrapper({super.key, required this.child});

  @override
  State<DoubleBackToExitWrapper> createState() => _DoubleBackToExitWrapperState();
}

class _DoubleBackToExitWrapperState extends State<DoubleBackToExitWrapper> {
  DateTime? lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, 
      onPopInvokedWithResult: (didPop, _) {
        final now = DateTime.now();
        if (lastBackPressTime == null || now.difference(lastBackPressTime!) > const Duration(seconds: 2)) {
          lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Press back again to exit')),
          );
        } else {
          Navigator.of(context).maybePop();
        }
      },
      child: widget.child,
    );
  }
}
