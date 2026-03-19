import 'package:flutter/material.dart';
import 'package:ai_nexconn_chat_plugin/ai_nexconn_chat_plugin.dart';

void main() {
  runApp(const SampleApp());
}

class SampleApp extends StatelessWidget {
  const SampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: InitializeAndConnectPage());
  }
}

class InitializeAndConnectPage extends StatefulWidget {
  const InitializeAndConnectPage({super.key});

  @override
  State<InitializeAndConnectPage> createState() =>
      _InitializeAndConnectPageState();
}

class _InitializeAndConnectPageState extends State<InitializeAndConnectPage> {
  final _appKeyController = TextEditingController();
  final _tokenController = TextEditingController();
  final _naviServerController = TextEditingController();

  String _log = 'Fill in App Key and Token, then tap the button to run.';
  bool _running = false;

  Future<void> _runSample() async {
    final appKey = _appKeyController.text.trim();
    final token = _tokenController.text.trim();
    final naviServer = _naviServerController.text.trim();

    if (appKey.isEmpty || token.isEmpty) {
      setState(() {
        _log = 'App Key and Token are required.';
      });
      return;
    }

    setState(() {
      _running = true;
      _log = 'Initializing SDK...\n';
    });

    try {
      await NCEngine.destroy();
      await NCEngine.initialize(
        InitParams(
          appKey: appKey,
          naviServer: naviServer.isEmpty ? null : naviServer,
        ),
      );

      if (!mounted) return;
      setState(() {
        _log += 'SDK initialized successfully.\nConnecting...\n';
      });

      await NCEngine.connect(ConnectParams(token: token), (userId, error) {
        if (!mounted) return;
        setState(() {
          if (error != null && !error.isSuccess) {
            _log += 'Connect failed: ${error.toJson()}\n';
            return;
          }
          _log += 'Connect succeeded.\n';
          _log += 'Connected userId: ${userId ?? '(empty)'}\n';
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
    _naviServerController.dispose();
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
      appBar: AppBar(title: const Text('Initialize And Connect Chat SDK')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'App Key and Token are intentionally left blank.\n'
                'Apply for your own App Key from the NexConn platform and '
                'generate Token from your business server before running this sample.',
              ),
            ),
          ),
          _buildField(
            'App Key',
            _appKeyController,
            hint: 'Leave blank until you have applied for one',
          ),
          _buildField(
            'Token',
            _tokenController,
            hint: 'Leave blank until your server can provide one',
          ),
          _buildField(
            'Navi Server (Optional)',
            _naviServerController,
            hint: 'Optional private deployment address',
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
