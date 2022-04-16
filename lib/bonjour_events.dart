import 'package:json_annotation/json_annotation.dart';

part 'bonjour_events.g.dart';

enum EventType { added, removed, found, resolved }

@JsonSerializable()
class BonjourEvent {
  final EventType type;

  BonjourEvent(this.type);

  factory BonjourEvent.fromJson(Map<String, dynamic> json) =>
      _$BonjourEventFromJson(json);

  Map<String, dynamic> toJson() => _$BonjourEventToJson(this);
}

@JsonSerializable()
class BonjourBroadcastEvent extends BonjourEvent {
  BonjourBroadcastEvent() : super(EventType.added);

  factory BonjourBroadcastEvent.fromJson(Map<String, dynamic> json) =>
      _$BonjourBroadcastEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BonjourBroadcastEventToJson(this);
}

@JsonSerializable()
class BonjourSearchEvent extends BonjourEvent {
  final String serviceType;
  final String serviceName;
  final String? hostName;
  final String? address;

  BonjourSearchEvent(
    EventType type, {
    required this.serviceType,
    required this.serviceName,
    this.hostName,
    this.address,
  }) : super(type);

  factory BonjourSearchEvent.fromJson(Map<String, dynamic> json) =>
      _$BonjourSearchEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BonjourSearchEventToJson(this);
}
