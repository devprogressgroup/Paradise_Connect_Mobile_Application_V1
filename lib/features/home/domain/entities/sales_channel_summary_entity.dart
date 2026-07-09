class SalesChannelItemEntity {
  final int salesChannelId;
  final String channelCode;
  final String channelName;
  final int totalContacts;

  const SalesChannelItemEntity({
    required this.salesChannelId,
    required this.channelCode,
    required this.channelName,
    required this.totalContacts,
  });
}

class SalesChannelSummaryEntity {
  final int totalContacts;
  final List<SalesChannelItemEntity> channels;

  const SalesChannelSummaryEntity({
    required this.totalContacts,
    required this.channels,
  });
}
