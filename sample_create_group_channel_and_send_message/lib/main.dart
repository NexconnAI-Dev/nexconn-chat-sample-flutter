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
    return const MaterialApp(home: CreateGroupAndSendMessagePage());
  }
}

class CreateGroupAndSendMessagePage extends StatefulWidget {
  const CreateGroupAndSendMessagePage({super.key});

  @override
  State<CreateGroupAndSendMessagePage> createState() =>
      _CreateGroupAndSendMessagePageState();
}

class _CreateGroupAndSendMessagePageState
    extends State<CreateGroupAndSendMessagePage> {
  final _appKeyController = TextEditingController();
  final _tokenController = TextEditingController();
  final _groupIdController = TextEditingController();
  final _groupNameController = TextEditingController();
  final _inviteeUserIdsController = TextEditingController();
  final _textController = TextEditingController(text: 'Hello group channel.');

  String _log = 'Fill in the fields, then create the group and send a message.';
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
    final groupName = _groupNameController.text.trim();
    final text = _textController.text.trim();
    final inviteeUserIds = _inviteeUserIdsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (appKey.isEmpty ||
        token.isEmpty ||
        groupId.isEmpty ||
        groupName.isEmpty ||
        text.isEmpty) {
      setState(() {
        _log = 'App Key, Token, Group ID, Group Name, and Text are required.';
      });
      return;
    }

    setState(() {
      _running = true;
      _log = 'Initializing SDK and connecting...\n';
    });

    try {
      await _initializeAndConnect();

      await GroupChannel.createGroup(
        CreateGroupParams(
          info: GroupInfo(groupId: groupId, groupName: groupName),
          inviteeUserIds: inviteeUserIds,
        ),
        (groupInfo, error) async {
          if (!mounted) return;

          if (error != null && !error.isSuccess) {
            setState(() {
              _log += 'createGroup failed: ${error.toJson()}\n';
            });
            return;
          }

          setState(() {
            _log +=
                'createGroup succeeded: ${groupInfo?.groupId ?? '(empty)'}\n';
          });

          final channel = GroupChannel(groupId);
          await channel.sendMessage(
            SendMessageParams(messageParams: TextMessageParams(text: text)),
            callback: SendMessageCallback(
              onMessageSent: (code, message) {
                if (!mounted) return;
                setState(() {
                  _log += 'onMessageSent code: $code\n';
                  _log += 'messageId: ${message?.messageId ?? '(empty)'}\n';
                });
              },
            ),
          );
        },
      );
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
    _groupNameController.dispose();
    _inviteeUserIdsController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
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
        title: const Text('Create Group Channel And Send Message'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'App Key and Token are intentionally blank.\n'
                'Use your own credentials and valid user IDs before running this sample.',
              ),
            ),
          ),
          _buildField('App Key', _appKeyController),
          _buildField('Token', _tokenController),
          _buildField('Group ID', _groupIdController),
          _buildField('Group Name', _groupNameController),
          _buildField(
            'Invitee User IDs (comma separated)',
            _inviteeUserIdsController,
            hint: 'user_a,user_b',
          ),
          _buildField('Text', _textController, maxLines: 3),
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
