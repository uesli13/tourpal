import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../services/dashboard_service.dart';
import '../../../../models/user.dart';
import '../../../../models/tour_plan.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// Dashboard BLoC following TourPal development rules
/// 
/// Handles dashboard state management and aggregates data from multiple services:
/// - User profile information
/// - Recent and favorite tours
/// - Booking statistics
/// - Performance metrics
/// 
/// Events:
/// - [LoadDashboard]: Load complete dashboard data
/// - [RefreshDashboard]: Refresh dashboard data
/// - [LoadRecentTours]: Load user's recent tours
/// - [LoadFavoriteTours]: Load user's favorite tours
/// - [LoadBookingStats]: Load user's booking statistics
/// 
/// States:
/// - [DashboardInitial]: Initial state
/// - [DashboardLoading]: Loading dashboard data
/// - [DashboardLoaded]: Dashboard data loaded successfully
/// - [DashboardRefreshing]: Refreshing existing data
/// - [DashboardError]: Error occurred while loading data
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardService _dashboardService;
  
  DashboardBloc({
    required DashboardService dashboardService,
  }) : _dashboardService = dashboardService,
       super(const DashboardInitial()) {
    
    // Register event handlers following TourPal rules
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
    on<LoadRecentTours>(_onLoadRecentTours);
    on<LoadFavoriteTours>(_onLoadFavoriteTours);
    on<LoadBookingStats>(_onLoadBookingStats);
    
    // Log BLoC initialization
    AppLogger.info('DashboardBloc initialized');
  }

  @override
  void onChange(Change<DashboardState> change) {
    super.onChange(change);
    // Log state transitions following TourPal logging rules
    AppLogger.blocTransition(
      'DashboardBloc',
      change.currentState.runtimeType.toString(),
      change.nextState.runtimeType.toString(),
    );
  }

  @override
  void onEvent(DashboardEvent event) {
    super.onEvent(event);
    // Log events following TourPal logging rules
    AppLogger.blocEvent('DashboardBloc', event.runtimeType.toString());
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading dashboard for user: ${event.userId}');
    
    try {
      emit(const DashboardLoading());
      
      // Load dashboard data using available service methods
      final results = await Future.wait([
        _dashboardService.getRecentTours(event.userId, limit: 5),
        _dashboardService.getFavoriteTours(event.userId, limit: 5),
        _dashboardService.getUserStats(event.userId),
      ]);

      final recentTours = results[0] as List<TourPlan>;
      final favoriteTours = results[1] as List<TourPlan>;
      final stats = results[2] as DashboardStats;

      emit(DashboardLoaded(
        user: User(
          id: event.userId,
          email: '', // Will be populated by auth state
          name: 'User', // Will be populated by profile service
          isGuide: false, // Default value, will be updated by profile service
          favoriteTours: const [], // Will be loaded from profile
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ), // Placeholder user - should be loaded from ProfileService
        recentTours: recentTours,
        favoriteTours: favoriteTours,
        stats: stats,
      ));

      stopwatch.stop();
      AppLogger.performance('Dashboard Load', stopwatch.elapsed);
      AppLogger.info('Dashboard loaded successfully for user: ${event.userId}');
      
    } on DashboardException catch (e) {
      AppLogger.error('Dashboard service error', e);
      emit(DashboardError(message: e.message));
    } on AppException catch (e) {
      AppLogger.error('App error loading dashboard', e);
      emit(DashboardError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error loading dashboard', e);
      emit(const DashboardError(message: 'Failed to load dashboard'));
    }
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Refreshing dashboard for user: ${event.userId}');
    
    try {
      // Show refreshing state if we have previous data
      if (state is DashboardLoaded) {
        emit(DashboardRefreshing(previousState: state as DashboardLoaded));
      } else {
        emit(const DashboardLoading());
      }
      
      // Refresh data
      add(LoadDashboard(userId: event.userId));
      
      stopwatch.stop();
      AppLogger.performance('Dashboard Refresh', stopwatch.elapsed);
      
    } catch (e) {
      AppLogger.error('Error refreshing dashboard', e);
      emit(const DashboardError(message: 'Failed to refresh dashboard'));
    }
  }

  Future<void> _onLoadRecentTours(
    LoadRecentTours event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      AppLogger.info('Loading recent tours for user: ${event.userId}');
      
      final recentTours = await _dashboardService.getRecentTours(
        event.userId,
        limit: event.limit,
      );

      // Update existing state if available
      if (state is DashboardLoaded) {
        final currentState = state as DashboardLoaded;
        emit(currentState.copyWith(recentTours: recentTours));
      }
      
    } on DashboardException catch (e) {
      AppLogger.error('Error loading recent tours', e);
      emit(DashboardError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error loading recent tours', e);
      emit(const DashboardError(message: 'Failed to load recent tours'));
    }
  }

  Future<void> _onLoadFavoriteTours(
    LoadFavoriteTours event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      AppLogger.info('Loading favorite tours for user: ${event.userId}');
      
      final favoriteTours = await _dashboardService.getFavoriteTours(
        event.userId,
        limit: event.limit,
      );

      // Update existing state if available
      if (state is DashboardLoaded) {
        final currentState = state as DashboardLoaded;
        emit(currentState.copyWith(favoriteTours: favoriteTours));
      }
      
    } on DashboardException catch (e) {
      AppLogger.error('Error loading favorite tours', e);
      emit(DashboardError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error loading favorite tours', e);
      emit(const DashboardError(message: 'Failed to load favorite tours'));
    }
  }

  Future<void> _onLoadBookingStats(
    LoadBookingStats event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      AppLogger.info('Loading booking stats for user: ${event.userId}');
      
      final stats = await _dashboardService.getUserStats(event.userId);

      // Update existing state if available
      if (state is DashboardLoaded) {
        final currentState = state as DashboardLoaded;
        emit(currentState.copyWith(stats: stats));
      }
      
    } on DashboardException catch (e) {
      AppLogger.error('Error loading booking stats', e);
      emit(DashboardError(message: e.message));
    } catch (e) {
      AppLogger.error('Unexpected error loading booking stats', e);
      emit(const DashboardError(message: 'Failed to load booking statistics'));
    }
  }
}

/// Extension for DashboardLoaded state updates
extension DashboardLoadedExtension on DashboardLoaded {
  DashboardLoaded copyWith({
    User? user,
    List<TourPlan>? recentTours,
    List<TourPlan>? favoriteTours,
    DashboardStats? stats,
  }) {
    return DashboardLoaded(
      user: user ?? this.user,
      recentTours: recentTours ?? this.recentTours,
      favoriteTours: favoriteTours ?? this.favoriteTours,
      stats: stats ?? this.stats,
    );
  }
}