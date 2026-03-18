import 'package:nexconn_flutter/nexconn_flutter.dart';

/// Initializes and connects the Chat SDK.
Future<void> initializeAndConnectChatSdk({
  required String appKey,
  required String token,
  String? naviServer,
}) async {
  // Initialize the SDK first, because all IM capabilities depend on the engine.
  await NCEngine.initialize(
    InitParams(
      appKey: appKey,
      naviServer: naviServer,
    ),
  );

  // Connect to the IM service with the user token issued by your business server.
  await NCEngine.connect(
    ConnectParams(
      token: token,
      timeout: 30,
    ),
    (userId, error) {
      // If an error is returned here, the connection was not established.
      if (error != null && !error.isSuccess) {
        throw Exception('connect failed: ${error.toJson()}');
      }

      // Read the connected user ID here if your business logic needs it.
      final connectedUserId = userId;

      // This check is included only to show how the connection result can be validated.
      if (connectedUserId == null || connectedUserId.isEmpty) {
        throw Exception('connect succeeded but userId is empty');
      }
    },
  );
}
