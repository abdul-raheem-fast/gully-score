import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../state/app_store.dart';
import '../route_paths.dart';
import '../services/supabase_service.dart';


class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen>
    with SingleTickerProviderStateMixin {
  UserRole? _selected;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go(String route) {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a role to continue'),
          backgroundColor: C.g2,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    AppStore.of(context).setRole(_selected!);
    Navigator.pushNamed(context, route, arguments: _selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),

                          // Back
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushReplacementNamed(
                                    context, '/onboarding'),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: C.gLight,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(Icons.arrow_back_ios_new,
                                  size: 16, color: C.dark),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Title
                          RichText(
                            text: const TextSpan(children: [
                              TextSpan(
                                text: 'Who are\nyou? ',
                                style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: C.dark,
                                    height: 1.2),
                              ),
                              TextSpan(
                                  text: '🏏',
                                  style: TextStyle(fontSize: 30)),
                            ]),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Select your role to get started',
                            style: TextStyle(color: C.grey, fontSize: 15),
                          ),

                          const SizedBox(height: 40),

                          // Admin card
                          _RoleCard(
                            role: UserRole.admin,
                            selected: _selected == UserRole.admin,
                            icon: Icons.admin_panel_settings_outlined,
                            activeIcon: Icons.admin_panel_settings,
                            title: 'Admin',
                            emoji: '👑',
                            subtitle: 'Manage tournaments, teams & players',
                            color: C.adminBlue,
                            lightColor: C.adminLight,
                            onTap: () => setState(() => _selected = UserRole.admin),
                          ),

                          const SizedBox(height: 16),

                          // Player card
                          _RoleCard(
                            role: UserRole.player,
                            selected: _selected == UserRole.player,
                            icon: Icons.sports_cricket_outlined,
                            activeIcon: Icons.sports_cricket,
                            title: 'Player',
                            emoji: '🏏',
                            subtitle:
                                'Score matches, track performance & stats',
                            color: C.g2,
                            lightColor: C.gLight,
                            onTap: () => setState(() => _selected = UserRole.player),
                          ),

                          const Spacer(),

                          // Sign In
                          AppButton(
                            label: 'Sign In',
                            onTap: () => _go('/login'),
                            color: _selected == UserRole.admin
                                ? C.adminBlue
                                : C.g1,
                          ),
                          const SizedBox(height: 14),

                          if (_selected == UserRole.player) ...[
                            // Create Account
                            AppButton(
                              label: 'Create Account',
                              onTap: () => _go('/signup'),
                              outline: true,
                              color: C.g1,
                            ),
                            const SizedBox(height: 36),
                          ] else ...[
                            const SizedBox(height: 4),
                          ]
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Role card widget ────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  final UserRole role;
  final bool selected;
  final IconData icon, activeIcon;
  final String title, emoji, subtitle;
  final Color color, lightColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.emoji,
    required this.subtitle,
    required this.color,
    required this.lightColor,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.97)
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.selected ? widget.lightColor : C.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.selected
                  ? widget.color
                  : Colors.grey.shade200,
              width: widget.selected ? 2.0 : 1.0,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                        color: widget.color.withOpacity(0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 6))
                  ]
                : [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
          ),
          child: Row(
            children: [
              // Icon circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.selected
                      ? widget.color
                      : Colors.grey.shade100,
                ),
                child: Center(
                  child: Icon(
                    widget.selected ? widget.activeIcon : widget.icon,
                    color: widget.selected ? C.white : C.grey,
                    size: 30,
                  ),
                ),
              ),

              const SizedBox(width: 18),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: widget.selected ? widget.color : C.dark,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(widget.emoji,
                          style: const TextStyle(fontSize: 18)),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                          color: C.grey, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),

              // Check mark
              AnimatedScale(
                scale: widget.selected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: widget.color),
                  child:
                      const Icon(Icons.check, color: C.white, size: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  LOGIN SCREEN  — Sign in with email & password
// ════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();
  bool _obscure = true;
  bool _loading = false;
  late UserRole _role;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _role = (ModalRoute.of(context)?.settings.arguments as UserRole?) ??
        UserRole.player;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Color get _c => _role == UserRole.admin ? C.adminBlue : C.g1;
  String get _roleLabel => _role == UserRole.admin ? 'Admin' : 'Player';
  String get _roleEmoji => _role == UserRole.admin ? '👑' : '🏏';
  String get _targetAfterLogin =>
      _role == UserRole.admin ? RoutePaths.admin : RoutePaths.home;

  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(trimmed);
  }

  bool _isValidPassword(String password) {
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*[^A-Za-z0-9]).{8,}$');
    return regex.hasMatch(password);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Resets all login form fields to their initial state.
  /// NOTE: Not called anywhere — kept for future use.
  void _resetFields() {
    _emailCtrl.clear();
    _passCtrl.clear();
    setState(() {
      _obscure = true;
      _loading = false;
    });
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    if (!_isValidPassword(password)) {
      _showError(
          'Password must be at least 8 characters with 1 uppercase and 1 special character');
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await SupabaseService.signInWithEmail(
        email: email,
        password: password,
      );

      final userRole = response.user?.userMetadata?['app_role']?.toString();
      if (userRole != null && userRole != _role.name) {
        _showError('This account is registered as $userRole, not $_roleLabel.');
        setState(() => _loading = false);
        return;
      }

      final name = response.user?.userMetadata?['name']?.toString();
      if (!mounted) return;
      final store = AppStore.of(context);
      store.setRole(_role);
      store.login((name == null || name.isEmpty) ? email : name);
      setState(() => _loading = false);
      Navigator.pushReplacementNamed(context, _targetAfterLogin);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Sign in failed. Please check connection and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          color: C.gLight,
                          borderRadius: BorderRadius.circular(13)),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: C.dark),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _c.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: _c.withOpacity(0.25), width: 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_roleEmoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        'Signing in as $_roleLabel',
                        style: TextStyle(
                            color: _c,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  // Title — exactly as Figma
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                        text: 'Welcome\nBack! ',
                        style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: C.dark,
                            height: 1.2),
                      ),
                      TextSpan(
                          text: '👋',
                          style: TextStyle(fontSize: 30)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  const Text('Sign in to continue scoring',
                      style: TextStyle(color: C.grey, fontSize: 15)),

                  const SizedBox(height: 34),

                  // Email
                  AppField(
                    label: 'Email Address',
                    hint: 'player@gullyscore.co',
                    icon: Icons.email_outlined,
                    ctrl: _emailCtrl,
                    keyType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passFocus),
                  ),
                  const SizedBox(height: 20),

                  // Password
                  AppField(
                    label: 'Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    ctrl: _passCtrl,
                    focusNode: _passFocus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _signIn(),
                    suffix: GestureDetector(
                      onTap: () =>
                          setState(() => _obscure = !_obscure),
                      child: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: C.hint,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                            color: _c,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Sign In button
                  _loading
                      ? Center(
                          child: CircularProgressIndicator(color: _c))
                      : AppButton(
                          label: 'Sign In',
                          onTap: _signIn,
                          color: _c,
                        ),

                  const SizedBox(height: 28),

                  // Divider
                  Row(children: [
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('Or continue with',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade200)),
                  ]),

                  const SizedBox(height: 20),

                  // Social buttons — exactly as Figma
                  Row(children: [
                    Expanded(
                      child: _SocialBtn(
                        label: 'Google',
                        icon: const Text('G',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4285F4))),
                        onTap: _signIn,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SocialBtn(
                        label: 'Apple',
                        icon: const Icon(Icons.apple,
                            size: 22, color: C.dark),
                        onTap: _signIn,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // Sign Up link
                  if (_role != UserRole.admin)
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(
                            context, '/signup',
                            arguments: _role),
                        child: RichText(
                          text: TextSpan(children: [
                            const TextSpan(
                              text: "Don't have an account? ",
                              style:
                                  TextStyle(color: C.grey, fontSize: 14),
                            ),
                            TextSpan(
                              text: 'Sign Up',
                              style: TextStyle(
                                  color: _c,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ]),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  SIGNUP SCREEN  — exact Figma design
// ════════════════════════════════════════════════════════
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  String _playRole = 'Batsman';
  bool _loading = false;
  late UserRole _role;
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fade = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _role = (ModalRoute.of(context)?.settings.arguments as UserRole?) ??
        UserRole.player;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _orgCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Color get _c => _role == UserRole.admin ? C.adminBlue : C.g1;
  String get _roleLabel => _role == UserRole.admin ? 'Admin' : 'Player';
  String get _roleEmoji => _role == UserRole.admin ? '👑' : '🏏';
  String get _targetAfterSignup =>
      _role == UserRole.admin ? RoutePaths.admin : RoutePaths.home;

  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(trimmed);
  }

  bool _isValidPassword(String password) {
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*[^A-Za-z0-9]).{8,}$');
    return regex.hasMatch(password);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Validates a Pakistani mobile number (e.g. 03001234567).
  /// NOTE: Not called anywhere — kept for future use.
  bool _hasValidPhone(String phone) {
    final trimmed = phone.trim();
    final regex = RegExp(r'^03[0-9]{9}$');
    return regex.hasMatch(trimmed);
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final organization = _orgCtrl.text.trim();
    final password = _passCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Name, email and password are required');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    if (!_isValidPassword(password)) {
      _showError(
          'Password must be at least 8 characters with 1 uppercase and 1 special character');
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await SupabaseService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        appRole: _role.name,
      );
      final userId = response.user?.id;
      if (userId != null) {
        await SupabaseService.upsertUserProfile(
          userId: userId,
          email: email,
          name: name,
          role: _role.name,
          phone: phone.isEmpty ? null : phone,
          playingRole: _role == UserRole.player ? _playRole : null,
          organization: _role == UserRole.admin
              ? (organization.isEmpty ? null : organization)
              : null,
        );
      }

      if (!mounted) return;
      final requiresConfirmation = response.session == null;
      if (requiresConfirmation) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Account created. Please verify your email, then sign in.',
            ),
            backgroundColor: C.g2,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pushReplacementNamed(context, RoutePaths.login, arguments: _role);
        return;
      }

      final store = AppStore.of(context);
      store.setRole(_role);
      store.login(name);
      setState(() => _loading = false);
      Navigator.pushReplacementNamed(context, _targetAfterSignup);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Sign up failed. Please check connection and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          color: C.gLight,
                          borderRadius: BorderRadius.circular(13)),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 16, color: C.dark),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: _c.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: _c.withOpacity(0.25), width: 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_roleEmoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        'Registering as $_roleLabel',
                        style: TextStyle(
                            color: _c,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 20),

                  // Title — exactly as Figma
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                        text: 'Create\nAccount ',
                        style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: C.dark,
                            height: 1.2),
                      ),
                      TextSpan(
                          text: '✨',
                          style: TextStyle(fontSize: 28)),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  const Text('Join the cricket community',
                      style: TextStyle(color: C.grey, fontSize: 15)),

                  const SizedBox(height: 28),

                  AppField(
                      label: 'Full Name',
                      hint: 'Muhammad Ahmed',
                      icon: Icons.person_outline,
                      ctrl: _nameCtrl),
                  const SizedBox(height: 18),
                  AppField(
                      label: 'Email Address',
                      hint: 'ahmed@gmail.com',
                      icon: Icons.email_outlined,
                      ctrl: _emailCtrl,
                      keyType: TextInputType.emailAddress),
                  const SizedBox(height: 18),
                  AppField(
                      label: 'Phone Number',
                      hint: '+92 300 1234567',
                      icon: Icons.phone_outlined,
                      ctrl: _phoneCtrl,
                      keyType: TextInputType.phone),
                  const SizedBox(height: 18),
                  AppField(
                      label: 'Password',
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      obscure: true,
                      ctrl: _passCtrl),

                  const SizedBox(height: 22),

                  // Playing role — only for players, exactly as Figma
                  if (_role == UserRole.player) ...[
                    const Text('Playing Role',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13.5,
                            color: C.dark)),
                    const SizedBox(height: 10),
                    Row(
                      children: ['Batsman', 'Bowler', 'All-Rounder']
                          .map((r) {
                        final sel = r == _playRole;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _playRole = r),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 13),
                                decoration: BoxDecoration(
                                  color: sel ? C.gLight : C.white,
                                  borderRadius:
                                      BorderRadius.circular(13),
                                  border: Border.all(
                                    color: sel
                                        ? C.g2
                                        : Colors.grey.shade300,
                                    width: sel ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    r,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: sel ? C.g2 : C.grey,
                                      fontWeight: sel
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Admin: org field
                  if (_role == UserRole.admin) ...[
                    AppField(
                        label: 'Organisation / Club Name',
                        hint: 'e.g. City Cricket Club',
                        icon: Icons.business_outlined,
                        ctrl: _orgCtrl),
                    const SizedBox(height: 4),
                  ],

                  const SizedBox(height: 24),

                  if (_role == UserRole.admin)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: C.gLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Admin account creation is not available. Please sign in instead.',
                        style: TextStyle(
                          color: C.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    _loading
                        ? Center(
                            child: CircularProgressIndicator(color: _c))
                        : AppButton(
                            label: 'Create Account',
                            onTap: _create,
                            color: _c,
                          ),

                  const SizedBox(height: 20),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                          context, '/login',
                          arguments: _role),
                      child: RichText(
                        text: TextSpan(children: [
                          const TextSpan(
                            text: 'Already have an account? ',
                            style:
                                TextStyle(color: C.grey, fontSize: 14),
                          ),
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                                color: _c,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ]),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _SocialBtn extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  const _SocialBtn(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03), blurRadius: 8)
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          icon,
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: C.dark)),
        ]),
      ),
    );
  }
}
