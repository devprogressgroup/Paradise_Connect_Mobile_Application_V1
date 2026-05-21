import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/attandance/domain/entities/location_entity.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_attendance.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_locations.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_office_locations.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_today_attendance.dart';
import 'package:progress_group/features/attandance/domain/usecase/submit_attendance.dart';
import 'package:progress_group/features/attandance/domain/usecase/submit_attendance_activity.dart';
import 'package:progress_group/features/attandance/domain/entities/attandance_entity.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_event.dart';
import 'package:progress_group/features/attandance/presentation/state/attandance/attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final GetAttendanceUseCase getAttendanceUseCase;
  final GetTodayAttendanceUseCase getTodayAttendanceUseCase;
  final GetLocationsUseCase getLocationsUseCase;
  final GetOfficeLocationsUseCase getOfficeLocationsUseCase;
  final SubmitAttendanceUseCase submitAttendanceUseCase;
  final SubmitAttendanceActivityUseCase submitAttendanceActivityUseCase;

  AttendanceBloc({
    required this.getAttendanceUseCase,
    required this.getTodayAttendanceUseCase,
    required this.getLocationsUseCase,
    required this.getOfficeLocationsUseCase,
    required this.submitAttendanceUseCase,
    required this.submitAttendanceActivityUseCase,
  }) : super(AttendanceInitial()) {
    on<GetAttendanceEvent>((event, emit) async {
      final currentState = state;
      List<AttendanceLocation>? locations;
      List<AttendanceLocation>? officeLocations;
      
      if (currentState is AttendanceLoaded) {
        locations = currentState.locations;
        officeLocations = currentState.officeLocations;
      }

      emit(AttendanceLoading());
      try {
        final data = await getAttendanceUseCase(salesPersonIds: event.salesPersonIds);
        emit(AttendanceLoaded(
          data: data, 
          locations: locations, 
          officeLocations: officeLocations
        ));
      } catch (e) {
        emit(AttendanceError(e.toString()));
      }
    });

    on<FetchAttendanceDataEvent>((event, emit) async {
      final currentState = state;
      List<AttendanceLocation>? pameranLocations;
      if (currentState is AttendanceLoaded) {
        pameranLocations = currentState.locations;
      }

      emit(AttendanceLoading());
      try {
        final results = await Future.wait([
          getAttendanceUseCase(salesPersonIds: event.salesPersonIds),
          getOfficeLocationsUseCase(),
          getTodayAttendanceUseCase().catchError((_) => null),
        ]);

        final logs = results[0] as List<AttendanceEntity>;
        final offices = results[1] as List<AttendanceLocation>;
        final todayData = results[2] as AttendanceEntity?;

        emit(AttendanceLoaded(
          data: logs,
          officeLocations: offices,
          locations: pameranLocations,
          todayData: todayData,
        ));
      } catch (e) {
        emit(AttendanceError(e.toString()));
      }
    });

    on<GetLocationsEvent>((event, emit) async {
      final currentState = state;
      List<AttendanceEntity> currentData = [];
      List<AttendanceLocation>? officeLocations;
      if (currentState is AttendanceLoaded) {
        currentData = currentState.data;
        officeLocations = currentState.officeLocations;
      }

      try {
        final locations = await getLocationsUseCase();
        debugPrint("DEBUG: Pameran Locations fetched: ${locations.length}");
        emit(AttendanceLoaded(data: currentData, locations: locations, officeLocations: officeLocations));
      } catch (e) {
        emit(AttendanceError(e.toString()));
      }
    });

    on<GetOfficeLocationsEvent>((event, emit) async {
      final currentState = state;
      List<AttendanceEntity> currentData = [];
      List<AttendanceLocation>? pameranLocations;
      if (currentState is AttendanceLoaded) {
        currentData = currentState.data;
        pameranLocations = currentState.locations;
      }

      try {
        final locations = await getOfficeLocationsUseCase();
        debugPrint("DEBUG: Office Locations fetched: ${locations.length}");
        emit(AttendanceLoaded(data: currentData, locations: pameranLocations, officeLocations: locations));
      } catch (e) {
        emit(AttendanceError(e.toString()));
      }
    });

    on<SubmitAttendanceEvent>((event, emit) async {
      emit(AttendanceSubmitLoading());
      try {
        await submitAttendanceUseCase(
          datetime: event.datetime,
          flag: event.flag,
          location: event.location,
          note: event.note,
          filePath: event.filePath,
          nikNumber: event.nikNumber,
        );
        emit(AttendanceSubmitSuccess());
      } catch (e) {
        emit(AttendanceError(e.toString()));
      }
    });

    on<SubmitAttendanceActivityEvent>((event, emit) async {
      emit(AttendanceSubmitLoading());
      try {
        await submitAttendanceActivityUseCase(
          datetime: event.datetime,
          flag: event.flag,
          location: event.location,
          note: event.note,
          filePaths: event.filePaths,
          nikNumber: event.nikNumber,
        );
        emit(AttendanceSubmitSuccess());
      } catch (e) {
        emit(AttendanceError(e.toString()));
      }
    });
  }
}