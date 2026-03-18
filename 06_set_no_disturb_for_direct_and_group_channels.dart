import 'package:nexconn_flutter/nexconn_flutter.dart';

/// Sets message do-not-disturb for both a direct channel and a group channel.
Future<void> setNoDisturbForDirectAndGroupChannels({
  required String directUserId,
  required String groupId,
  NoDisturbLevel level = NoDisturbLevel.blocked,
}) async {
  // Create a direct channel instance to configure do-not-disturb for the direct chat.
  final directChannel = DirectChannel(directUserId);

  // Apply the target do-not-disturb level to the direct channel.
  await directChannel.setNoDisturbLevel(level, (error) {
    // Throw an exception if the direct channel update fails.
    if (error != null && !error.isSuccess) {
      throw Exception(
        'set direct channel no disturb failed: ${error.toJson()}',
      );
    }
  });

  // Create a group channel instance to configure do-not-disturb for the group chat.
  final groupChannel = GroupChannel(groupId);

  // Apply the same do-not-disturb level to the group channel.
  await groupChannel.setNoDisturbLevel(level, (error) {
    // Throw an exception if the group channel update fails.
    if (error != null && !error.isSuccess) {
      throw Exception(
        'set group channel no disturb failed: ${error.toJson()}',
      );
    }
  });
}
