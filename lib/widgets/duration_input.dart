import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class DurationInput extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;

  const DurationInput({super.key, required this.initialValue, required this.onChanged});

  @override
  _DurationInputState createState() => _DurationInputState();
}

class _DurationInputState extends State<DurationInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
    _focusNode = FocusNode();

    // When focus is lost, clamp the value
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        int value = int.tryParse(_controller.text) ?? 1;
        if (value < 1) value = 1;
        if (value > 30) value = 30;

        _controller.text = value.toString();
        widget.onChanged(value);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.green500),
          ),
        ),
        onChanged: (v) {
        },
      ),
    );
  }
}
