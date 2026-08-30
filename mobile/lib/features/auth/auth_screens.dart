import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(text: AppConstants.demoOwnerEmail);
  final _password = TextEditingController(text: AppConstants.demoPassword);
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).login(_email.text.trim(), _password.text);
      if (!mounted) return;
      final s = ref.read(sessionProvider);
      if (!s.user!.emailVerified) {
        context.go('/verify-email');
      } else if (!s.permissionsPrimed) {
        context.go('/permissions');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RisingSheetScaffold(
      title: 'Log in',
      subtitle: 'Welcome back. Your email stays off public teasers.',
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 8),
            AppField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 12),
            AppField(
              controller: _password,
              label: 'Password',
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) => v != null && v.length >= 6 ? null : 'At least 6 characters',
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot'),
                child: const Text('Forgot password?'),
              ),
            ),
            AppButton(label: 'Log in', onPressed: _submit, busy: _busy),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('Need an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _display = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _password = TextEditingController();
  bool _terms = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _display.dispose();
    _email.dispose();
    _city.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_terms) {
      showError(context, 'Please accept the terms to create an account.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider.notifier).register(
            name: _name.text.trim(),
            displayName: _display.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            city: _city.text.trim(),
          );
      if (mounted) context.go('/verify-email');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RisingSheetScaffold(
      title: 'Create account',
      subtitle: 'Display name is public. Legal name stays private.',
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Use a display name you are comfortable showing on claims.'),
            const SizedBox(height: 20),
            AppField(
              controller: _name,
              label: 'Full name',
              validator: (v) => v != null && v.trim().length >= 2 ? null : 'Required',
            ),
            const SizedBox(height: 12),
            AppField(
              controller: _display,
              label: 'Display name',
              validator: (v) => v != null && v.trim().length >= 2 ? null : 'Required',
            ),
            const SizedBox(height: 12),
            AppField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
            ),
            const SizedBox(height: 12),
            AppField(controller: _city, label: 'City (optional)'),
            const SizedBox(height: 12),
            AppField(
              controller: _password,
              label: 'Password',
              obscure: true,
              validator: (v) => v != null && v.length >= 8 ? null : 'Use 8+ characters',
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _terms,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _terms = v ?? false),
              title: const Text('I agree to the Terms and Privacy Policy'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            TextButton(
              onPressed: () => context.push('/legal/terms'),
              child: const Text('Read terms'),
            ),
            AppButton(label: 'Create account', onPressed: _submit, busy: _busy),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RisingSheetScaffold(
      title: 'Forgot password',
      subtitle: 'We email a reset link if the account exists.',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('If that email is on file, we sent a reset link. In demo, continue with any token.'),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Enter reset code',
                    onPressed: () => context.push('/reset?email=${Uri.encodeComponent(_email.text)}'),
                  ),
                ],
              )
            : Column(
                children: [
                  const Text('We will email a reset link. Unverified guests cannot reset.'),
                  const SizedBox(height: 16),
                  AppField(
                    controller: _email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Send link',
                    busy: _busy,
                    onPressed: () async {
                      if (!_email.text.contains('@')) {
                        showError(context, 'Enter a valid email');
                        return;
                      }
                      setState(() => _busy = true);
                      try {
                        await ref.read(repositoryProvider).forgotPassword(_email.text.trim());
                        setState(() => _sent = true);
                      } catch (e) {
                        if (mounted) showError(context, e);
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.email});
  final String? email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _token = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RisingSheetScaffold(
      title: 'Reset password',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AppField(controller: _token, label: 'Reset code', hint: 'Demo: any 4+ characters'),
          const SizedBox(height: 12),
          AppField(controller: _password, label: 'New password', obscure: true),
          const SizedBox(height: 20),
          AppButton(
            label: 'Update password',
            busy: _busy,
            onPressed: () async {
              if (_token.text.length < 4 || _password.text.length < 8) {
                showError(context, 'Enter a code and an 8+ character password.');
                return;
              }
              setState(() => _busy = true);
              try {
                await ref.read(repositoryProvider).resetPassword(
                      email: widget.email ?? AppConstants.demoOwnerEmail,
                      token: _token.text,
                      password: _password.text,
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated. Please log in.')),
                  );
                  context.go('/login');
                }
              } catch (e) {
                if (mounted) showError(context, e);
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
          ),
        ],
      ),
    );
  }
}

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(sessionProvider).user?.email ?? 'your inbox';
    return RisingSheetScaffold(
      title: 'Verify email',
      subtitle: 'Unverified accounts can browse teasers only.',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('We sent a code to $email. Unverified accounts can browse teasers only.'),
            const SizedBox(height: 8),
            const Text('Deep link stub: reunite://verify — paste any 4+ digit code in demo.'),
            const SizedBox(height: 20),
            AppField(
              controller: _code,
              label: 'Verification code',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Verify',
              busy: _busy,
              onPressed: () async {
                setState(() => _busy = true);
                try {
                  await ref.read(repositoryProvider).verifyEmail(_code.text.trim());
                  await ref.read(sessionProvider.notifier).refreshUser();
                  if (mounted) context.go('/profile-setup');
                } catch (e) {
                  if (mounted) showError(context, e);
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
            ),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Browse teasers for now'),
            ),
          ],
        ),
      ),
    );
  }
}

class PhoneOtpScreen extends ConsumerStatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RisingSheetScaffold(
      title: 'Phone verification',
      subtitle: 'A step-up factor. We will not show it on teasers.',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const TrustBanner(text: 'Phone is a step-up factor. We will not show it on teasers.'),
            const SizedBox(height: 16),
            AppField(
              controller: _phone,
              label: 'Phone',
              keyboardType: TextInputType.phone,
            ),
            if (_sent) ...[
              const SizedBox(height: 12),
              AppField(
                controller: _code,
                label: 'OTP code',
                hint: 'Demo: 123456',
                keyboardType: TextInputType.number,
              ),
            ],
            const Spacer(),
            AppButton(
              label: _sent ? 'Confirm' : 'Send code',
              busy: _busy,
              onPressed: () async {
                setState(() => _busy = true);
                try {
                  if (!_sent) {
                    await ref.read(repositoryProvider).sendOtp(_phone.text.trim());
                    setState(() => _sent = true);
                  } else {
                    await ref
                        .read(repositoryProvider)
                        .confirmOtp(_phone.text.trim(), _code.text.trim());
                    await ref.read(sessionProvider.notifier).refreshUser();
                    if (mounted) context.pop();
                  }
                } catch (e) {
                  if (mounted) showError(context, e);
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late final TextEditingController _name;
  late final TextEditingController _city;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = ref.read(sessionProvider).user;
    _name = TextEditingController(text: u?.displayName ?? '');
    _city = TextEditingController(text: u?.city ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RisingSheetScaffold(
      title: 'Your public profile',
      subtitle: 'Finders and hubs see this — not your legal name or phone.',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('This is what finders and hubs see — not your legal name or phone.'),
          const SizedBox(height: 20),
          AppField(controller: _name, label: 'Display name'),
          const SizedBox(height: 12),
          AppField(controller: _city, label: 'City / area'),
          const SizedBox(height: 24),
          AppButton(
            label: 'Save and continue',
            busy: _busy,
            onPressed: () async {
              setState(() => _busy = true);
              try {
                await ref.read(repositoryProvider).updateMe(
                      displayName: _name.text.trim(),
                      city: _city.text.trim(),
                    );
                await ref.read(sessionProvider.notifier).refreshUser();
                await ref.read(sessionProvider.notifier).markProfileSetupDone();
                if (mounted) context.go('/permissions');
              } catch (e) {
                if (mounted) showError(context, e);
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
          ),
        ],
      ),
    );
  }
}
