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
    return const MaterialApp(home: GetGroupMembersPage());
  }
}

class GetGroupMembersPage extends StatefulWidget {
  const GetGroupMembersPage({super.key});

  @override
  State<GetGroupMembersPage> createState() => _GetGroupMembersPageState();
}

class _GetGroupMembersPageState extends State<GetGroupMembersPage> {
  final _appKeyController = TextEditingController();
  final _tokenController = TextEditingController();
  final _groupIdController = TextEditingController();
  final _userIdsController = TextEditingController();

  String _log = 'Fill in the fields, then query group member information.';
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
    final groupId = _groupIdController.text.trim();
    final userIds = _userIdsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (appKey.isEmpty || token.isEmpty || groupId.isEmpty || userIds.isEmpty) {
      setState(() {
        _log =
            'App Key, Token, Group ID, and at least one User ID are required.';
      });
      return;
    }

    setState(() {
      _running = true;
      _log = 'Initializing SDK and connecting...\n';
    });

    try {
      await _initializeAndConnect();

      final channel = GroupChannel(groupId);
      await channel.getMembers(userIds, (members, error) {
        if (!mounted) return;
        setState(() {
          if (error != null && !error.isSuccess) {
            _log += 'getMembers failed: ${error.toJson()}\n';
            return;
          }

          _log += 'Loaded ${members?.length ?? 0} group members.\n';
          for (final member in members ?? const <GroupMemberInfo>[]) {
            _log +=
                '- ${member.userId ?? '(empty)'} / ${member.nickname ?? member.name ?? '(no name)'}\n';
          }
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
    _groupIdController.dispose();
    _userIdsController.dispose();
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
      appBar: AppBar(title: const Text('Get Group Members')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'App Key and Token are intentionally blank.\n'
                'Use your own credentials and valid group member IDs before running this sample.',
              ),
            ),
          ),
          _buildField('App Key', _appKeyController),
          _buildField('Token', _tokenController),
          _buildField('Group ID', _groupIdController),
          _buildField(
            'User IDs (comma separated)',
            _userIdsController,
            hint: 'user_a,user_b',
          ),
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
