import 'package:flutter/material.dart';
import 'package:ai_nexconn_chat_plugin/ai_nexconn_chat_plugin.dart';

void main() {
  runApp(const SampleApp());
}

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: SendTextMessagePage());
  }
}

class SendTextMessagePage extends StatefulWidget {
  const SendTextMessagePage({super.key});

  @override
  State<SendTextMessagePage> createState() => _SendTextMessagePageState();
}

class _SendTextMessagePageState extends State<SendTextMessagePage> {
  final _appKeyController = TextEditingController();
  final _tokenController = TextEditingController();
  final _targetUserIdController = TextEditingController();
  final _textController = TextEditingController(
    text: 'Hello from NexConn Flutter sample.',
  );

  String _log =
      'Fill in the fields, then tap the button to send a direct text message.';
  bool _running = false;

  Future<void> _initializeAndConnect() async {
    await NCEngine.destroy();
    await NCEngine.initialize(
      InitParams(appKey: _appKeyController.text.trim()),
    );

    await NCEngine.connect(ConnectParams(token: _tokenController.text.trim()), (
      userId,
      error,
    ) {
      if (!mounted) return;
      setState(() {
        if (error != null && !error.isSuccess) {
          _log += 'Connect failed: ${error.toJson()}\n';
          return;
        }
        _log += 'Connected as: ${userId ?? '(empty)'}\n';
      });
    });
  }

  Future<void> _runSample() async {
    final appKey = _appKeyController.text.trim();
    final token = _tokenController.text.trim();
    final targetUserId = _targetUserIdController.text.trim();
    final text = _textController.text.trim();

    if (appKey.isEmpty ||
        token.isEmpty ||
        targetUserId.isEmpty ||
        text.isEmpty) {
      setState(() {
        _log = 'App Key, Token, Target User ID, and Text are required.';
      });
      return;
    }

    setState(() {
      _running = true;
      _log = 'Initializing SDK and connecting...\n';
    });

    try {
      await _initializeAndConnect();

      final channel = DirectChannel(targetUserId);
      await channel.sendMessage(
        SendMessageParams(messageParams: TextMessageParams(text: text)),
        callback: SendMessageCallback(
          onMessageSent: (code, message) {
            if (!mounted) return;
            setState(() {
              _log += 'onMessageSent code: $code\n';
              _log += 'messageId: ${message?.messageId ?? '(empty)'}\n';
              _log += 'clientId: ${message?.clientId ?? '(empty)'}\n';
            });
          },
        ),
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
    _targetUserIdController.dispose();
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
      appBar: AppBar(title: const Text('Send Text Message In Direct Channel')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'App Key and Token are intentionally blank.\n'
                'Apply for your own App Key and prepare your own Token before running this sample.',
              ),
            ),
          ),
          _buildField('App Key', _appKeyController),
          _buildField('Token', _tokenController),
          _buildField('Target User ID', _targetUserIdController),
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
