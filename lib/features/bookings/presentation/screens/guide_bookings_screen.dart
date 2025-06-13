import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/booking.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../tours/presentation/screens/tour_preview_screen.dart';
import '../../../tours/domain/repositories/tour_repository.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../widgets/guide_booking_card.dart';
import '../../../tours/presentation/screens/tour_session_screen.dart';

class GuideBookingsScreen extends StatefulWidget {
  const GuideBookingsScreen({super.key});

  @override
  State<GuideBookingsScreen> createState() => _GuideBookingsScreenState();
}

class _GuideBookingsScreenState extends State<GuideBookingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadBookings() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<BookingBloc>().add(
        LoadGuideBookingsEvent(guideId: authState.user.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Tour Bookings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.guide,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingConfirmed) {
            _showSnackBar('Booking confirmed successfully! 🎉', Colors.green);
            _loadBookings();
          } else if (state is BookingCancelled) {
            _showSnackBar('Booking declined', Colors.orange);
            _loadBookings();
          } else if (state is BookingError) {
            _showSnackBar('Error: ${state.message}', Colors.red);
          }
        },
        child: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state is BookingLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.guide),
              );
            }

            if (state is BookingError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading bookings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadBookings,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.guide),
                    ),
                  ],
                ),
              );
            }

            if (state is BookingsLoaded) {
              final allBookings = state.bookings;
              final pendingBookings = allBookings.where((b) => b.status == 'pending').toList();
              final confirmedBookings = allBookings.where((b) => b.status == 'confirmed').toList();

              if (allBookings.isEmpty) {
                return _buildEmptyState();
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingsList(pendingBookings, 'pending'),
                  _buildBookingsList(confirmedBookings, 'confirmed'),
                  _buildBookingsList(allBookings, 'all'),
                ],
              );
            }

            return const Center(
              child: Text(
                'Pull to refresh',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 80,
            color: AppColors.guide.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookings yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bookings for your tours will appear here.\nCreate tours to start receiving bookings!',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.tour),
            label: const Text('Manage Tours'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.guide,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, String filterType) {
    if (bookings.isEmpty) {
      String emptyMessage;
      IconData emptyIcon;

      switch (filterType) {
        case 'pending':
          emptyMessage = 'No pending bookings\nNew booking requests will appear here';
          emptyIcon = Icons.schedule;
          break;
        case 'confirmed':
          emptyMessage = 'No confirmed bookings\nConfirmed tours will appear here';
          emptyIcon = Icons.check_circle_outline;
          break;
        default:
          emptyMessage = 'No bookings found\nCreate tours to start receiving bookings';
          emptyIcon = Icons.bookmarks_outlined;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: AppColors.guide.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadBookings(),
      color: AppColors.guide,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return GuideBookingCard(
            booking: booking,
            onViewDetails: () => _viewTourDetails(booking),
            onStartTour: booking.status == 'confirmed' && _isScheduledForToday(booking.startTime.toDate())
                ? () => _startTour(booking)
                : null,
            onConfirm: booking.status == 'pending'
                ? () => _confirmBooking(booking.id)
                : null,
            onCancel: booking.status == 'pending'
                ? () => _cancelBooking(booking.id)
                : null,
          );
        },
      ),
    );
  }

  bool _isScheduledForToday(DateTime scheduleTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduleDate = DateTime(scheduleTime.year, scheduleTime.month, scheduleTime.day);
    return scheduleDate.isAtSameMomentAs(today);
  }

  void _startTour(Booking booking) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      _showSnackBar('Authentication required', Colors.red);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.play_arrow, color: AppColors.guide),
            const SizedBox(width: 8),
            const Text('Start Tour'),
          ],
        ),
        content: const Text(
          'Are you ready to start this tour? The traveler will be notified '
          'and asked to confirm their readiness.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleStartTour(booking, authState.user.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.guide),
            child: const Text('Start Tour', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleStartTour(Booking booking, String guideId) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.guide),
        ),
      );

      // Fetch the tour plan first
      final tourRepository = context.read<TourRepository>();
      final tourPlan = await tourRepository.getTourById(booking.tourPlanId);
      
      if (tourPlan == null) {
        throw Exception('Tour plan not found');
      }

      // Hide loading
      if (mounted) Navigator.pop(context);

      // Show success message
      _showSnackBar(
        'Starting tour session! 🚀\nPreparing confirmation screen...',
        AppColors.guide,
      );

      // Navigate to tour session screen for confirmation instead of directly to active tour
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TourSessionScreen(
            booking: booking,
            tourPlan: tourPlan,
          ),
        ),
      );

    } catch (e) {
      // Hide loading
      if (mounted) Navigator.pop(context);
      
      _showSnackBar(
        'Failed to start tour: $e',
        Colors.red,
      );
    }
  }

  void _confirmBooking(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Confirm Booking'),
          ],
        ),
        content: const Text(
          'Are you sure you want to confirm this booking? '
          'The traveler will be notified and the tour will be scheduled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BookingBloc>().add(
                ConfirmBookingEvent(bookingId: bookingId),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _cancelBooking(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Decline Booking'),
          ],
        ),
        content: const Text(
          'Are you sure you want to decline this booking? '
          'The traveler will be notified that their request was not accepted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BookingBloc>().add(
                CancelBookingEvent(bookingId: bookingId),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Decline', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _viewTourDetails(Booking booking) async {
    try {
      // Fetch the tour plan details
      final tourRepository = context.read<TourRepository>();
      final tourPlan = await tourRepository.getTourById(booking.tourPlanId);
      
      if (tourPlan != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TourPreviewScreen(
              tourPlan: tourPlan,
              places: tourPlan.places,
              hideActions: true, // Hide all action buttons for booking cards
            ),
          ),
        );
      } else if (mounted) {
        _showSnackBar('Tour details not available', Colors.red);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading tour details: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}