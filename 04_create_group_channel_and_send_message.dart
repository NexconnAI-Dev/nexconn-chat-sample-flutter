import 'package:nexconn_flutter/nexconn_flutter.dart';

/// Creates a group channel and sends a message in that group channel.
Future<void> createGroupChannelAndSendMessage({
  required String groupId,
  required String groupName,
  required List<String> inviteeUserIds,
  required String text,
}) async {
  // Build the basic group info object with at least the group ID and group name.
  final groupInfo = GroupInfo(
    groupId: groupId,
    groupName: groupName,
  );

  // Create the group first, then continue only after the group is available.
  await GroupChannel.createGroup(
    CreateGroupParams(
      info: groupInfo,
      inviteeUserIds: inviteeUserIds,
    ),
    (createdGroup, error) async {
      // If an error is returned here, the group creation flow failed.
      if (error != null && !error.isSuccess) {
        throw Exception('create group failed: ${error.toJson()}');
      }

      // Do not continue if the created group info is missing a valid group ID.
      if (createdGroup?.groupId == null || createdGroup!.groupId!.isEmpty) {
        throw Exception('create group succeeded but groupId is empty');
      }

      // Create a GroupChannel instance based on the created group ID.
      final channel = GroupChannel(createdGroup.groupId!);

      // Send a regular text message into the newly created group channel.
      await channel.sendMessage(
        SendMessageParams(
          messageParams: TextMessageParams(
            text: text,
          ),
        ),
        callback: SendMessageCallback(
          // Handle the final send result in onMessageSent.
          onMessageSent: (code, message) {
            // A non-zero code means the group message failed to send.
            if (code != 0) {
              throw Exception('send group text message failed: code=$code');
            }

            // The returned message is the wrapped message object from the new SDK.
            final sentMessage = message;

            // This check is included only to show how the send result can be validated.
            if (sentMessage == null) {
              throw Exception(
                'send group text message succeeded but message is null',
              );
            }
          },
        ),
      );
    },
  );
}
