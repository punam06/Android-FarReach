import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../state/app_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _phone, _address;
  final _current = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final user = widget.controller.user!;
    _name = TextEditingController(text: user.name);
    _phone = TextEditingController(text: user.phone);
    _address = TextEditingController(text: user.address);
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _current, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.updateProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        password: _password.text,
        currentPassword: _current.text,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit profile')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _name,
            enabled: !_busy,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) =>
                v?.trim().isEmpty != false ? 'Enter your name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            enabled: !_busy,
            maxLength: 20,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _address,
            enabled: !_busy,
            maxLength: 1000,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Address'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Change password (optional). Other signed in sessions will be ended.',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _current,
            enabled: !_busy,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
            validator: (v) => _password.text.isNotEmpty && v?.isNotEmpty != true
                ? 'Enter your current password'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
            validator: (v) => v != null && v.isNotEmpty && v.length < 8
                ? 'Use at least eight characters'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirm,
            enabled: !_busy,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
            ),
            validator: (v) =>
                v != _password.text ? 'Passwords do not match' : null,
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving…' : 'Save changes'),
          ),
        ],
      ),
    ),
  );
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(),
      _code = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  bool _sent = false, _busy = false;
  String? _error, _preview;
  @override
  void dispose() {
    for (final c in [_email, _code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit({bool resend = false}) async {
    if (!resend && !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_sent || resend) {
        final data = await widget.api.requestJson(
          '/api/auth/password-reset/start',
          method: 'POST',
          body: {'email': _email.text.trim()},
        );
        if (mounted) {
          setState(() {
            _sent = true;
            _preview = data['previewCode']?.toString();
          });
        }
      } else {
        await widget.api.requestJson(
          '/api/auth/password-reset/complete',
          method: 'POST',
          body: {
            'email': _email.text.trim(),
            'code': _code.text.trim(),
            'password': _password.text,
          },
        );
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Password updated. Sign in with your new password.',
              ),
            ),
          );
        }
      }
    } on ApiFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reset password')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'We will email a six-digit code if an account exists. Codes expire after 10 minutes.',
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _email,
            enabled: !_busy && !_sent,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) =>
                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v?.trim() ?? '')
                ? null
                : 'Enter a valid email',
          ),
          if (_sent) ...[
            const SizedBox(height: 14),
            if (_preview != null) Text('Development preview code: $_preview'),
            TextFormField(
              controller: _code,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Verification code'),
              validator: (v) => RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '')
                  ? null
                  : 'Enter six digits',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              enabled: !_busy,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
              validator: (v) => (v?.length ?? 0) >= 8
                  ? null
                  : 'Use at least eight characters',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirm,
              enabled: !_busy,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm password'),
              validator: (v) =>
                  v == _password.text ? null : 'Passwords do not match',
            ),
            TextButton(
              onPressed: _busy ? null : () => _submit(resend: true),
              child: const Text('Resend code'),
            ),
          ],
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(
              _busy
                  ? 'Please wait…'
                  : (_sent ? 'Reset password' : 'Send reset code'),
            ),
          ),
        ],
      ),
    ),
  );
}
