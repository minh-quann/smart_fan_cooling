import 'package:equatable/equatable.dart';

/// AppMapping maps an application executable or name to a specific FanProfile.
class AppMapping extends Equatable {
  final String id;
  final String appName;
  final String executableName;
  final String iconPath;
  final String profileId;
  final bool isEnabled;

  const AppMapping({
    required this.id,
    required this.appName,
    required this.executableName,
    required this.iconPath,
    required this.profileId,
    this.isEnabled = true,
  });

  AppMapping copyWith({
    String? id,
    String? appName,
    String? executableName,
    String? iconPath,
    String? profileId,
    bool? isEnabled,
  }) {
    return AppMapping(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      executableName: executableName ?? this.executableName,
      iconPath: iconPath ?? this.iconPath,
      profileId: profileId ?? this.profileId,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        appName,
        executableName,
        iconPath,
        profileId,
        isEnabled,
      ];
}
