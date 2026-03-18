import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ── Pressable animated button ─────────────────────────────────
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool outline;
  final Color color;
  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.outline = false,
    this.color = C.g1,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.outline ? Colors.transparent : widget.color,
            borderRadius: BorderRadius.circular(16),
            border: widget.outline
                ? Border.all(color: widget.color, width: 1.5)
                : null,
            boxShadow: widget.outline
                ? null
                : [
                    BoxShadow(
                      color: widget.color.withOpacity(0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    )
                  ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.outline ? widget.color : C.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Labelled text field ───────────────────────────────────────
class AppField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Widget? suffix;
  final bool obscure;
  final TextEditingController? ctrl;
  final TextInputType keyType;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AppField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.suffix,
    this.obscure = false,
    this.ctrl,
    this.keyType = TextInputType.text,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13.5,
              color: C.dark)),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyType,
        focusNode: focusNode,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: C.hint, size: 19),
          suffixIcon: suffix,
        ),
      ),
    ]);
  }
}
