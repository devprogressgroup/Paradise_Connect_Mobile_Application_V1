import '../../domain/entities/sales_channel_summary_entity.dart';

class SalesChannelItemModel extends SalesChannelItemEntity {
  const SalesChannelItemModel({
    required super.salesChannelId,
    required super.channelCode,
    required super.channelName,
    required super.totalContacts,
  });

  factory SalesChannelItemModel.fromJson(Map<String, dynamic> json) {
    final fullName = json['sales_channel_name'] as String;
    final separatorIndex = fullName.indexOf(' - ');
    final code = separatorIndex == -1 ? fullName : fullName.substring(0, separatorIndex);
    final name = separatorIndex == -1 ? fullName : fullName.substring(separatorIndex + 3);

    return SalesChannelItemModel(
      salesChannelId: json['sales_channel_id'] as int,
      channelCode: code,
      channelName: name,
      totalContacts: json['total_contacts'] as int,
    );
  }
}

class SalesChannelSummaryModel extends SalesChannelSummaryEntity {
  const SalesChannelSummaryModel({
    required super.totalContacts,
    required super.channels,
  });

  factory SalesChannelSummaryModel.fromJson(Map<String, dynamic> json) {
    final channelList = (json['channels'] as List<dynamic>)
        .map((e) => SalesChannelItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return SalesChannelSummaryModel(
      totalContacts: json['total_contacts'] as int,
      channels: channelList,
    );
  }
}
