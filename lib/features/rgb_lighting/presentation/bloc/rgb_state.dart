import 'package:equatable/equatable.dart';
import 'package:smart_fan_cooling/features/rgb_lighting/domain/models/rgb_config.dart';

class RgbState extends Equatable {
  final RgbConfig config;

  const RgbState({required this.config});

  factory RgbState.initial() {
    return RgbState(config: RgbConfig.initial());
  }

  RgbState copyWith({RgbConfig? config}) {
    return RgbState(config: config ?? this.config);
  }

  @override
  List<Object?> get props => [config];
}
