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
  final String serviceName;
  BonjourBroadcastEvent(EventType type, this.serviceName) : super(type);

  factory BonjourBroadcastEvent.fromJson(Map<String, dynamic> json) =>
      _$BonjourBroadcastEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BonjourBroadcastEventToJson(this);
}

@JsonSerializable()
class BonjourSearchEvent extends BonjourEvent {
  final String serviceType;
  final String? serviceName;
  final String? hostName;
  final String? address;
  final int? port;
  final List<String>? txt;

  BonjourSearchEvent(EventType type,
      {required this.serviceType,
      this.serviceName,
      this.hostName,
      this.address,
      this.port,
      this.txt})
      : super(type);

  factory BonjourSearchEvent.fromJson(Map<String, dynamic> json) =>
      _$BonjourSearchEventFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$BonjourSearchEventToJson(this);
}
