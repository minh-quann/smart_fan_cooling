import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_fan_cooling/features/profiles/data/repositories/profile_repository.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/bloc/profile_event.dart';
import 'package:smart_fan_cooling/features/profiles/presentation/bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;

  ProfileBloc(this._repository) : super(ProfileState.initial()) {
    on<LoadProfilesEvent>(_onLoadProfiles);
    on<SelectActiveProfileEvent>(_onSelectActiveProfile);
    on<SaveProfileEvent>(_onSaveProfile);
    on<DeleteProfileEvent>(_onDeleteProfile);
    on<AddAppMappingEvent>(_onAddAppMapping);
    on<ToggleAppMappingEvent>(_onToggleAppMapping);
    on<DeleteAppMappingEvent>(_onDeleteAppMapping);
  }

  void _onLoadProfiles(
    LoadProfilesEvent event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(status: ProfileStatus.loading));
    final profiles = _repository.getProfiles();
    final appMappings = _repository.getAppMappings();
    emit(state.copyWith(
      status: ProfileStatus.success,
      profiles: profiles,
      appMappings: appMappings,
    ));
  }

  void _onSelectActiveProfile(
    SelectActiveProfileEvent event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(activeProfileId: event.profileId));
  }

  void _onSaveProfile(
    SaveProfileEvent event,
    Emitter<ProfileState> emit,
  ) {
    final existingIndex = state.profiles.indexWhere((p) => p.id == event.profile.id);
    if (existingIndex != -1) {
      _repository.updateProfile(event.profile);
    } else {
      _repository.addProfile(event.profile);
    }

    emit(state.copyWith(
      profiles: _repository.getProfiles(),
      activeProfileId: event.profile.id,
    ));
  }

  void _onDeleteProfile(
    DeleteProfileEvent event,
    Emitter<ProfileState> emit,
  ) {
    _repository.deleteProfile(event.profileId);
    final updatedProfiles = _repository.getProfiles();
    final newActiveId = state.activeProfileId == event.profileId
        ? (updatedProfiles.isNotEmpty ? updatedProfiles.first.id : '')
        : state.activeProfileId;

    emit(state.copyWith(
      profiles: updatedProfiles,
      activeProfileId: newActiveId,
    ));
  }

  void _onAddAppMapping(
    AddAppMappingEvent event,
    Emitter<ProfileState> emit,
  ) {
    _repository.addAppMapping(event.mapping);
    emit(state.copyWith(appMappings: _repository.getAppMappings()));
  }

  void _onToggleAppMapping(
    ToggleAppMappingEvent event,
    Emitter<ProfileState> emit,
  ) {
    _repository.toggleAppMapping(event.mappingId, event.isEnabled);
    emit(state.copyWith(appMappings: _repository.getAppMappings()));
  }

  void _onDeleteAppMapping(
    DeleteAppMappingEvent event,
    Emitter<ProfileState> emit,
  ) {
    _repository.deleteAppMapping(event.mappingId);
    emit(state.copyWith(appMappings: _repository.getAppMappings()));
  }
}
