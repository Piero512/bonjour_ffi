// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bonjour_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BonjourEvent _$BonjourEventFromJson(Map<String, dynamic> json) => BonjourEvent(
      $enumDecode(_$EventTypeEnumMap, json['type']),
    );

Map<String, dynamic> _$BonjourEventToJson(BonjourEvent instance) =>
    <String, dynamic>{
      'type': _$EventTypeEnumMap[instance.type],
    };

const _$EventTypeEnumMap = {
  EventType.added: 'added',
  EventType.removed: 'removed',
  EventType.found: 'found',
  EventType.resolved: 'resolved',
};

BonjourBroadcastEvent _$BonjourBroadcastEventFromJson(
        Map<String, dynamic> json) =>
    BonjourBroadcastEvent(
      $enumDecode(_$EventTypeEnumMap, json['type']),
      json['serviceName'] as String,
    );

Map<String, dynamic> _$BonjourBroadcastEventToJson(
        BonjourBroadcastEvent instance) =>
    <String, dynamic>{
      'type': _$EventTypeEnumMap[instance.type],
      'serviceName': instance.serviceName,
    };

BonjourSearchEvent _$BonjourSearchEventFromJson(Map<String, dynamic> json) =>
    BonjourSearchEvent(
      $enumDecode(_$EventTypeEnumMap, json['type']),
      serviceType: json['serviceType'] as String,
      serviceName: json['serviceName'] as String?,
      hostName: json['hostName'] as String?,
      address: json['address'] as String?,
      port: json['port'] as int?,
      txt: (json['txt'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$BonjourSearchEventToJson(BonjourSearchEvent instance) =>
    <String, dynamic>{
      'type': _$EventTypeEnumMap[instance.type],
      'serviceType': instance.serviceType,
      'serviceName': instance.serviceName,
      'hostName': instance.hostName,
      'address': instance.address,
      'port': instance.port,
      'txt': instance.txt,
    };
