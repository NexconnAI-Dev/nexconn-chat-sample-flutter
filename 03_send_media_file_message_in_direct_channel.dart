import 'package:nexconn_flutter/nexconn_flutter.dart';

/// Sends a media file message in a direct channel.
Future<void> sendMediaFileMessageInDirectChannel({
  required String targetUserId,
  required String localFilePath,
}) async {
  // Create a direct channel instance, again using the peer user ID as the channel ID.
  final channel = DirectChannel(targetUserId);

  // Send a media message, and use file message params in this example.
  await channel.sendMediaMessage(
    SendMediaMessageParams(
      messageParams: FileMessageParams(
        path: localFilePath,
      ),
    ),
    handler: SendMediaMessageHandler(
      // Read the upload progress here if your UI needs progress updates.
      onMediaMessageSending: (message, progress) {
        // This block only demonstrates where progress handling can be added.
        final currentProgress = progress;
        if (currentProgress == null) {
          return;
        }
      },
      // Handle the final send result for the media message here.
      onMediaMessageSent: (code, message) {
        // A non-zero code means the file message failed to send.
        if (code != 0) {
          throw Exception('send media file message failed: code=$code');
        }

        // The returned message is already a wrapped MediaMessage subclass.
        final sentMessage = message;

        // This check is included only to show how the result can be validated.
        if (sentMessage == null) {
          throw Exception(
            'send media file message succeeded but message is null',
          );
        }
      },
    ),
  );
}
