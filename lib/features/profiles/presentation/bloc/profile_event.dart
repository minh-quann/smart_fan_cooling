import 'package:equatable/equatable.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/app_mapping.dart';
import 'package:smart_fan_cooling/features/profiles/domain/models/fan_profile.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfilesEvent extends ProfileEvent {
  const LoadProfilesEvent();
}

class SelectActiveProfileEvent extends ProfileEvent {
  final String profileId;

  const SelectActiveProfileEvent(this.profileId);

  @override
  List<Object?> get props => [profileId];
}

class SaveProfileEvent extends ProfileEvent {
  final FanProfile profile;

  const SaveProfileEvent(this.profile);

  @override
  List<Object?> get props => [profile];
}

class DeleteProfileEvent extends ProfileEvent {
  final String profileId;

  const DeleteProfileEvent(this.profileId);

  @override
  List<Object?> get props => [profileId];
}

class AddAppMappingEvent extends ProfileEvent {
  final AppMapping mapping;

  const AddAppMappingEvent(this.mapping);

  @override
  List<Object?> get props => [mapping];
}

class ToggleAppMappingEvent extends ProfileEvent {
  final String mappingId;
  final bool isEnabled;

  const ToggleAppMappingEvent(this.mappingId, this.isEnabled);

  @override
  List<Object?> get props => [mappingId, isEnabled];
}

class DeleteAppMappingEvent extends ProfileEvent {
  final String mappingId;

  const DeleteAppMappingEvent(this.mappingId);

  @override
  List<Object?> get props => [mappingId];
}
