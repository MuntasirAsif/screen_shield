import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:screen_shield/screen_shield.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ShieldPage());
  }
}

class ShieldPage extends StatefulWidget {
  const ShieldPage({super.key});

  @override
  State<ShieldPage> createState() => _ShieldPageState();
}

class _ShieldPageState extends State<ShieldPage> {
  bool _enabled = false;
  bool _suspended = false;
  CaptureState _state = CaptureState.none;
  String? _pickerResult;
  late final StreamSubscription<CaptureState> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ScreenShield.captureState.listen((state) {
      if (mounted) setState(() => _state = state);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _setEnabled(bool value) async {
    if (value) {
      await ScreenShield.enable();
    } else {
      await ScreenShield.disable();
    }
    if (mounted) {
      setState(() {
        _enabled = value;
        if (!value) _suspended = false;
      });
    }
  }

  Future<void> _toggleSuspend() async {
    final next = !_suspended;
    if (next) {
      await ScreenShield.suspend();
    } else {
      await ScreenShield.resume();
    }
    if (mounted) setState(() => _suspended = next);
  }

  Future<void> _pickFile() async {
    String text;
    try {
      final files = await FilePicker.pickFiles();
      text = files.isEmpty
          ? 'Picker cancelled — app is still responsive.'
          : 'Picked "${files.first.name}" — app is still responsive.';
    } catch (error) {
      text = 'Picker error: $error';
    }
    if (mounted) setState(() => _pickerResult = text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('screen_shield example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Block screenshots & recording'),
            subtitle: const Text('App-wide FLAG_SECURE / secure-field layer'),
            value: _enabled,
            onChanged: _setEnabled,
          ),
          ListTile(
            title: const Text('Suspend / resume'),
            subtitle: Text(
              _suspended ? 'Protection suspended' : 'Protection active',
            ),
            trailing: FilledButton(
              onPressed: _enabled ? _toggleSuspend : null,
              child: Text(_suspended ? 'Resume' : 'Suspend'),
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              _state == CaptureState.none
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
            title: const Text('Capture state'),
            subtitle: Text(_state.name),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Open the file picker'),
            subtitle: Text(
              _pickerResult ?? 'Prove that native modals do not freeze the app.',
            ),
            onTap: _pickFile,
          ),
        ],
      ),
    );
  }
}
