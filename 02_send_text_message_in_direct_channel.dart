import 'package:nexconn_flutter/nexconn_flutter.dart';

/// Sends a text message in a direct channel.
Future<void> sendTextMessageInDirectChannel({
  required String targetUserId,
  required String text,
}) async {
  // Create a direct channel instance, using the peer user ID as the channel ID.
  final channel = DirectChannel(targetUserId);

  // Send a regular message, and use text message params as the payload.
  await channel.sendMessage(
    SendMessageParams(
      messageParams: TextMessageParams(
        text: text,
      ),
    ),
    callback: SendMessageCallback(
      // Handle the final send result in onMessageSent.
      onMessageSent: (code, message) {
        // A non-zero code means the send operation failed.
        if (code != 0) {
          throw Exception('send text message failed: code=$code');
        }

        // The returned message is already wrapped by the new SDK model.
        final sentMessage = message;

        // This check is only included to show how the result can be validated.
        if (sentMessage == null) {
          throw Exception('send text message succeeded but message is null');
        }
      },
    ),
  );
}
