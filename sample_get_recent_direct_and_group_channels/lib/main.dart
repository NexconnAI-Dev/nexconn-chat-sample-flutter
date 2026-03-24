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
    return const MaterialApp(home: GetRecentChannelsPage());
  }
}

class GetRecentChannelsPage extends StatefulWidget {
  const GetRecentChannelsPage({super.key});

  @override
  State<GetRecentChannelsPage> createState() => _GetRecentChannelsPageState();
}

class _GetRecentChannelsPageState extends State<GetRecentChannelsPage> {
  final _appKeyController = TextEditingController();
  final _tokenController = TextEditingController();
  final _pageSizeController = TextEditingController(text: '20');

  String _log =
      'Fill in App Key and Token, then load recent direct and group channels.';
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
    final pageSize = int.tryParse(_pageSizeController.text.trim()) ?? 20;

    if (appKey.isEmpty || token.isEmpty) {
      setState(() {
        _log = 'App Key and Token are required.';
      });
      return;
    }

    setState(() {
      _running = true;
      _log = 'Initializing SDK and connecting...\n';
    });

    try {
      await _initializeAndConnect();

      final query = BaseChannel.createChannelsQuery(
        ChannelsQueryParams(
          channelTypes: const [ChannelType.direct, ChannelType.group],
          pageSize: pageSize,
          topPriority: true,
        ),
      );

      await query.loadNextPage((page, error) {
        if (!mounted) return;
        setState(() {
          if (error != null && !error.isSuccess) {
            _log += 'loadNextPage failed: ${error.toJson()}\n';
            return;
          }

          final channels = page?.data ?? const <BaseChannel>[];
          _log += 'Loaded ${channels.length} channels.\n';
          for (final channel in channels) {
            _log += '- ${channel.channelType.name} / ${channel.channelId}\n';
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
    _pageSizeController.dispose();
    super.dispose();
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
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
      appBar: AppBar(title: const Text('Get Recent Direct And Group Channels')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'App Key and Token are intentionally blank.\n'
                'Use your own credentials before loading the recent channel list.',
              ),
            ),
          ),
          _buildField('App Key', _appKeyController),
          _buildField('Token', _tokenController),
          _buildField(
            'Page Size',
            _pageSizeController,
            keyboardType: TextInputType.number,
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
