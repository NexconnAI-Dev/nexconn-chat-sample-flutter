import 'package:nexconn_flutter/nexconn_flutter.dart';

/// Gets the recent direct and group channel list.
Future<List<BaseChannel>> getRecentDirectAndGroupChannels({
  int pageSize = 20,
}) async {
  // Create a channel list query that only targets direct and group channels.
  final query = BaseChannel.createChannelListQuery(
    ChannelListQueryParams(
      channelTypes: [
        ChannelType.direct,
        ChannelType.group,
      ],
      pageSize: pageSize,
      topPriority: true,
    ),
  );

  // Use a local variable to receive the asynchronous query result.
  List<BaseChannel> channels = const [];

  // Load the first page of recent channels.
  await query.loadNextPage((result, error) {
    // If the query fails, bubble the error up to the caller.
    if (error != null && !error.isSuccess) {
      throw Exception('load recent channels failed: ${error.toJson()}');
    }

    // Save the successful result to the local variable.
    channels = result ?? const [];
  });

  // Return the recent direct and group channel list to the caller.
  return channels;
}
