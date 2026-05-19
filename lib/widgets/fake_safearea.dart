import 'package:aurora_recovery/widgets/view_metric.dart';
import 'package:flutter/material.dart';

class FakeSafearea extends StatefulWidget {
  const FakeSafearea({super.key, required this.child, this.top = true});
  final Widget child;
  final bool top;

  @override
  State<FakeSafearea> createState() => _FakeSafeareaState();
}

class _FakeSafeareaState extends State<FakeSafearea> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: widget.top ? $(48) : $(12),
      ),
      child: widget.child,
    );
  }
}
