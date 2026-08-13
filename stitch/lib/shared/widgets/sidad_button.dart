/// Primary gradient CTA button matching Stitch design with interactive scale-on-touch animations.
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

class SidadButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;

  const SidadButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
  });

  @override
  State<SidadButton> createState() => _SidadButtonState();
}

class _SidadButtonState extends State<SidadButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() {
        _scale = 0.95;
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() {
        _scale = 1.0;
      });
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() {
        _scale = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buttonWidget;

    if (widget.isOutlined) {
      buttonWidget = SizedBox(
        width: widget.width ?? double.infinity,
        height: AppDimens.buttonHeight,
        child: OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          child: _buildChild(context, outlined: true),
        ),
      );
    } else {
      buttonWidget = Container(
        width: widget.width ?? double.infinity,
        height: AppDimens.buttonHeight,
        decoration: BoxDecoration(
          gradient: widget.onPressed != null && !widget.isLoading
              ? AppColors.primaryGradient
              : null,
          color: widget.onPressed == null || widget.isLoading
              ? AppColors.surfaceContainerHigh
              : null,
          borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
          boxShadow: widget.onPressed != null && !widget.isLoading
              ? [
                  BoxShadow(
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(AppDimens.radiusXxl),
            child: Center(child: _buildChild(context)),
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: buttonWidget,
      ),
    );
  }

  Widget _buildChild(BuildContext context, {bool outlined = false}) {
    if (widget.isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: outlined ? AppColors.primary : Colors.white,
        ),
      );
    }

    final color = outlined ? AppColors.primary : Colors.white;

    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
