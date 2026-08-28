import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/destination.dart';
import '../services/api_client.dart';
import '../state/app_controller.dart';

enum _AuthMode { signIn, register }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _code = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  int _registerStep = 0;
  String? _previewCode;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Profile & trips')),
      body: widget.controller.isAuthenticated
          ? _SignedInProfile(controller: widget.controller)
          : _buildAuth(context),
    ),
  );

  Widget _buildAuth(BuildContext context) => ListView(
    key: const PageStorageKey('profile-auth-scroll'),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.backpack_outlined,
                      color: Colors.white,
                      size: 38,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Keep every trip in one place',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sync saved places, confirm packages, and manage upcoming journeys.',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SegmentedButton<_AuthMode>(
                segments: const [
                  ButtonSegment(
                    value: _AuthMode.signIn,
                    icon: Icon(Icons.login),
                    label: Text('Sign in'),
                  ),
                  ButtonSegment(
                    value: _AuthMode.register,
                    icon: Icon(Icons.person_add_outlined),
                    label: Text('Create account'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) => setState(() {
                  _mode = selection.first;
                  _error = null;
                }),
              ),
              const SizedBox(height: 22),
              if (_mode == _AuthMode.signIn)
                _buildLogin(context)
              else
                _buildSignup(context),
              const SizedBox(height: 18),
              const _ImageCredit(),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _buildLogin(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome back',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          const Text('Sign in with the account used on FarReach web.'),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            enabled: !widget.controller.authBusy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            enabled: !widget.controller.authBusy,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _login(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          if (_error != null) _ErrorText(_error!),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: widget.controller.authBusy ? null : _login,
            child: widget.controller.authBusy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign in'),
          ),
        ],
      ),
    ),
  );

  Widget _buildSignup(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(switch (_registerStep) {
            0 => 'Create your account',
            1 => 'Verify your email',
            _ => 'Choose a password',
          }, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(switch (_registerStep) {
            0 => 'We will send a six-digit verification code.',
            1 => 'Enter the code sent to ${_email.text.trim()}.',
            _ => 'Use at least eight characters.',
          }),
          const SizedBox(height: 20),
          if (_registerStep == 0) ...[
            TextField(
              controller: _name,
              enabled: !widget.controller.authBusy,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _email,
              enabled: !widget.controller.authBusy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ] else if (_registerStep == 1) ...[
            TextField(
              controller: _code,
              enabled: !widget.controller.authBusy,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(letterSpacing: 8),
              decoration: const InputDecoration(
                labelText: 'Verification code',
                prefixIcon: Icon(Icons.verified_outlined),
              ),
            ),
            if (kDebugMode && _previewCode != null)
              Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text('Local development code: $_previewCode'),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.controller.authBusy ? null : _resendCode,
                icon: const Icon(Icons.refresh),
                label: const Text('Resend code'),
              ),
            ),
          ] else ...[
            TextField(
              controller: _password,
              enabled: !widget.controller.authBusy,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmPassword,
              enabled: !widget.controller.authBusy,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
            ),
          ],
          if (_error != null) _ErrorText(_error!),
          const SizedBox(height: 18),
          Row(
            children: [
              if (_registerStep > 0) ...[
                OutlinedButton(
                  onPressed: widget.controller.authBusy
                      ? null
                      : () => setState(() {
                          _registerStep--;
                          _error = null;
                        }),
                  child: const Text('Back'),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: widget.controller.authBusy
                      ? null
                      : _continueSignup,
                  child: widget.controller.authBusy
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _registerStep == 2 ? 'Create account' : 'Continue',
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!_validEmail(email) || password.isEmpty) {
      setState(() => _error = 'Enter a valid email address and password.');
      return;
    }
    setState(() => _error = null);
    try {
      await widget.controller.login(email, password);
      if (mounted) _clearSensitiveFields();
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _continueSignup() async {
    setState(() => _error = null);
    try {
      if (_registerStep == 0) {
        if (_name.text.trim().length < 2 || !_validEmail(_email.text.trim())) {
          setState(() => _error = 'Enter your name and a valid email address.');
          return;
        }
        final result = await widget.controller.startSignup(
          _name.text.trim(),
          _email.text.trim(),
        );
        if (!mounted) return;
        setState(() {
          _previewCode = result.previewCode;
          _registerStep = 1;
        });
      } else if (_registerStep == 1) {
        if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
          setState(() => _error = 'Enter the six-digit verification code.');
          return;
        }
        await widget.controller.verifySignup(
          _email.text.trim(),
          _code.text.trim(),
        );
        if (mounted) setState(() => _registerStep = 2);
      } else {
        if (_password.text.length < 8) {
          setState(
            () => _error = 'Use a password with at least eight characters.',
          );
          return;
        }
        if (_password.text != _confirmPassword.text) {
          setState(() => _error = 'The passwords do not match.');
          return;
        }
        await widget.controller.finishSignup(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
        if (mounted) _clearSensitiveFields();
      }
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _error = null);
    try {
      final result = await widget.controller.resendSignup(_email.text.trim());
      if (!mounted) return;
      setState(() {
        _previewCode = result.previewCode;
        _code.clear();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('A new code was sent.')));
    } on ApiFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  void _clearSensitiveFields() {
    _password.clear();
    _confirmPassword.clear();
    _code.clear();
    _previewCode = null;
    _error = null;
  }

  static bool _validEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    ),
  );
}

class _SignedInProfile extends StatelessWidget {
  const _SignedInProfile({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.user!;
    final initial = user.name.trim().isEmpty
        ? '?'
        : user.name.trim()[0].toUpperCase();
    return ListView(
      key: const PageStorageKey('profile-signed-in-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary,
                          foregroundColor: Theme.of(context)
                              .colorScheme
                              .onPrimary,
                          child: Text(
                            initial,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(user.email),
                              const SizedBox(height: 8),
                              const Row(
                                children: [
                                  Icon(Icons.cloud_done_outlined, size: 18),
                                  SizedBox(width: 6),
                                  Text('Account sync enabled'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.favorite_outline,
                        value: '${controller.savedDestinations.length}',
                        label: 'Saved',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.luggage_outlined,
                        value: '${controller.bookings.length}',
                        label: 'Trips',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'My bookings',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                if (controller.bookings.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(22),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_outlined),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'No trips yet. Open a destination to plan one.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...controller.bookings.map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BookingCard(
                        controller: controller,
                        booking: booking,
                      ),
                    ),
                  ),
                const SizedBox(height: 22),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.dns_outlined),
                    title: const Text('Connected API'),
                    subtitle: Text(
                      controller.api.baseUrl.isEmpty
                          ? 'Offline catalog only'
                          : controller.api.baseUrl,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _ImageCredit(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: controller.logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageCredit extends StatelessWidget {
  const _ImageCredit();

  static final _source = Uri.parse(
    'https://commons.wikimedia.org/wiki/File:Sundarban_Mangrove.jpg',
  );

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.photo_library_outlined),
      title: const Text('Image credits'),
      subtitle: const Text(
        'Sundarban Mangrove by Shohelrana1979 · CC BY-SA 4.0',
      ),
      trailing: const Icon(Icons.open_in_new),
      onTap: () => launchUrl(_source, mode: LaunchMode.externalApplication),
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              Text(label),
            ],
          ),
        ],
      ),
    ),
  );
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.controller, required this.booking});

  final AppController controller;
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final cancelled = booking.status.toLowerCase() == 'cancelled';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cancelled
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.secondaryContainer,
              child: Icon(cancelled ? Icons.event_busy : Icons.flight_takeoff),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.spotName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${booking.date} · ${booking.persons} traveler(s) · ৳${booking.price}',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.status.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cancelled
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (!cancelled)
              IconButton(
                tooltip: 'Cancel booking',
                onPressed: () => _cancel(context),
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: const Text(
          'Cancellation is allowed until 24 hours before the travel date.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await controller.cancelBooking(booking.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
      }
    } on ApiFailure catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}
