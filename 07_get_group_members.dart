import 'package:nexconn_flutter/nexconn_flutter.dart';

/// Gets member information for a specified group channel.
Future<List<GroupMemberInfo>> getGroupMembers({
  required String groupId,
  required List<String> userIds,
}) async {
  // Create a group channel instance for the target group.
  final channel = GroupChannel(groupId);

  // Use a local variable to receive the asynchronous member list result.
  List<GroupMemberInfo> members = const [];

  // Query the member info for the specified user ID list.
  await channel.getMembers(userIds, (result, error) {
    // If the query fails, bubble the error up to the caller.
    if (error != null && !error.isSuccess) {
      throw Exception('get group members failed: ${error.toJson()}');
    }

    // Save the successful member result locally.
    members = result ?? const [];
  });

  // Return the queried group member list to the caller.
  return members;
}
