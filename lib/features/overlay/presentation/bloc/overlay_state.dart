import 'package:equatable/equatable.dart';
import 'package:smart_fan_cooling/features/overlay/domain/models/overlay_config.dart';

class OsdOverlayState extends Equatable {
  final OverlayConfig config;

  const OsdOverlayState({
    this.config = const OverlayConfig(),
  });

  OsdOverlayState copyWith({
    OverlayConfig? config,
  }) {
    return OsdOverlayState(
      config: config ?? this.config,
    );
  }

  @override
  List<Object?> get props => [config];
}
