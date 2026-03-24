import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ai_nexconn_chat_plugin/ai_nexconn_chat_plugin.dart';

void main() {
  runApp(const SampleApp());
}

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SetNoDisturbPage());
  }
}

class SetNoDisturbPage extends StatefulWidget {
  const SetNoDisturbPage({super.key});

  @override
  State<SetNoDisturbPage> createState() => _SetNoDisturbPageState();
}

class _SetNoDisturbPageState extends State<SetNoDisturbPage> {
  final _appKeyController = TextEditingController();
  final _tokenController = TextEditingController();
  final _directUserIdController = TextEditingController();
  final _groupIdController = TextEditingController();

  NoDisturbLevel _selectedLevel = NoDisturbLevel.blocked;
  String _log =
      'Fill in the fields, then set do-not-disturb for both channels.';
  bool _running = false;

  Future<void> _initializeAndConnect() async {
    final completer = Completer<void>();

    await NCEngine.destroy();
    await NCEngine.initialize(
      InitParams(appKey: _appKeyController.text.trim()),
    );

    NCEngine.connect(ConnectParams(token: _tokenController.text.trim()), (
      userId,
      error,
    ) {
      if (!mounted) {
        if (!completer.isCompleted) completer.completeError('Widget disposed');
        return;
      }
      setState(() {
        if (error != null && !error.isSuccess) {
          _log += 'Connect failed: ${error.toJson()}\n';
          if (!completer.isCompleted) completer.completeError(error);
          return;
        }
        _log += 'Connected as: ${userId ?? '(empty)'}\n';
        if (!completer.isCompleted) completer.complete();
      });
    });

    return completer.future;
  }

  Future<void> _runSample() async {
    final appKey = _appKeyController.text.trim();
    final token = _tokenController.text.trim();
    final directUserId = _directUserIdController.text.trim();
    final groupId = _groupIdController.text.trim();

    if (appKey.isEmpty ||
        token.isEmpty ||
        directUserId.isEmpty ||
        groupId.isEmpty) {
      setState(() {
        _log = 'App Key, Token, Direct User ID, and Group ID are required.';
      });
      return;
    }

    setState(() {
      _running = true;
      _log = 'Initializing SDK and connecting...\n';
    });

    try {
      await _initializeAndConnect();

      final directChannel = DirectChannel(directUserId);
      await directChannel.setNoDisturbLevel(_selectedLevel, (error) {
        if (!mounted) return;
        setState(() {
          _log += 'Direct channel result: ${error?.toJson()}\n';
        });
      });

      final groupChannel = GroupChannel(groupId);
      await groupChannel.setNoDisturbLevel(_selectedLevel, (error) {
        if (!mounted) return;
        setState(() {
          _log += 'Group channel result: ${error?.toJson()}\n';
        });
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _log += 'Unexpected error: $error\n';
      });
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _appKeyController.dispose();
    _tokenController.dispose();
    _directUserIdController.dispose();
    _groupIdController.dispose();
    super.dispose();
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set No Disturb For Direct And Group Channels'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'App Key and Token are intentionally blank.\n'
                'Use your own credentials before updating do-not-disturb settings.',
              ),
            ),
          ),
          _buildField('App Key', _appKeyController),
          _buildField('Token', _tokenController),
          _buildField('Direct User ID', _directUserIdController),
          _buildField('Group ID', _groupIdController),
          const SizedBox(height: 4),
          DropdownButtonFormField<NoDisturbLevel>(
            value: _selectedLevel,
            decoration: const InputDecoration(
              labelText: 'No Disturb Level',
              border: OutlineInputBorder(),
            ),
            items: NoDisturbLevel.values
                .map(
                  (level) =>
                      DropdownMenuItem(value: level, child: Text(level.name)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedLevel = value;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _running ? null : _runSample,
            child: Text(_running ? 'Running...' : 'Run Sample'),
          ),
          const SizedBox(height: 16),
          SelectableText(_log),
        ],
      ),
    );
  }
}
