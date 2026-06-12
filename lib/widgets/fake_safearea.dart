import 'package:flutter/material.dart';
import 'package:global_repository/global_repository.dart';
import 'package:responsive_framework/responsive_framework.dart';

class FakeSafearea extends StatefulWidget {
  const FakeSafearea({super.key, required this.child});
  final Widget child;

  @override
  State<FakeSafearea> createState() => _FakeSafeareaState();
}

class _FakeSafeareaState extends State<FakeSafearea> {
  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    return Padding(
      padding: EdgeInsets.only(
        top: isMobile ? $(48) : $(12),
      ),
      child: widget.child,
    );
  }
}
