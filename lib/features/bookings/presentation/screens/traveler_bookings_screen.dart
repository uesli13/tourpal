import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/booking.dart';
import '../bloc/booking_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../tours/presentation/screens/tour_preview_screen.dart';
import '../../../tours/presentation/screens/tour_session_screen.dart';
import '../../../tours/domain/repositories/tour_repository.dart';
import '../../../tours/services/tour_journal_service.dart';
import '../../../tours/presentation/widgets/tour_journal_widget.dart';
import '../../../../models/tour_journal.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../widgets/traveler_booking_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TravelerBookingsScreen extends StatefulWidget {
  const TravelerBookingsScreen({super.key});

  @override
  State<TravelerBookingsScreen> createState() => _TravelerBookingsScreenState();
}

class _TravelerBookingsScreenState extends State<TravelerBookingsScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _loadBookings() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<BookingBloc>().add(
        LoadTravelerBookingsEvent(travelerId: authState.user.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety check - create controller if somehow not initialized
    _tabController ??= TabController(length: 4, vsync: this);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.tourist,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController!,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingCancelled) {
            _showSnackBar('Booking cancelled successfully', Colors.orange);
            _loadBookings();
          } else if (state is BookingError) {
            _showSnackBar('Error: ${state.message}', Colors.red);
          }
        },
        child: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state is BookingLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.tourist),
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.tourist),
                    ),
                  ],
                ),
              );
            }

            if (state is BookingsLoaded) {
              final allBookings = state.bookings;
              final now = DateTime.now();
              
              final upcomingBookings = allBookings.where((b) => 
                b.status == 'confirmed' && b.startTime.toDate().isAfter(now)
              ).toList();
              
              final pendingBookings = allBookings.where((b) => b.status == 'pending').toList();
              final completedBookings = allBookings.where((b) => 
                b.status == 'completed' || 
                (b.status == 'confirmed' && b.startTime.toDate().isBefore(now))
              ).toList();

              if (allBookings.isEmpty) {
                return _buildEmptyState();
              }

              return TabBarView(
                controller: _tabController!,
                children: [
                  _buildBookingsList(upcomingBookings, 'upcoming'),
                  _buildBookingsList(pendingBookings, 'pending'),
                  _buildBookingsList(completedBookings, 'completed'),
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
            Icons.bookmarks_outlined,
            size: 80,
            color: AppColors.tourist.withValues(alpha: 0.3),
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
            'Your tour bookings will appear here.\nStart exploring amazing tours!',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore),
            label: const Text('Explore Tours'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tourist,
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
        case 'upcoming':
          emptyMessage = 'No upcoming tours\nConfirmed bookings will appear here';
          emptyIcon = Icons.schedule;
          break;
        case 'pending':
          emptyMessage = 'No pending bookings\nYour booking requests will appear here';
          emptyIcon = Icons.hourglass_empty;
          break;
        case 'completed':
          emptyMessage = 'No completed tours yet\nFinished tours will appear here';
          emptyIcon = Icons.check_circle_outline;
          break;
        default:
          emptyMessage = 'No bookings found\nExplore tours to make your first booking';
          emptyIcon = Icons.bookmarks_outlined;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: AppColors.tourist.withValues(alpha: 0.3),
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

    // Sort bookings by start time
    bookings.sort((a, b) => b.startTime.compareTo(a.startTime));

    return RefreshIndicator(
      onRefresh: () async => _loadBookings(),
      color: AppColors.tourist,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return TravelerBookingCard(
            booking: booking,
            onViewDetails: () => _viewTourDetails(booking),
            onJoinTour: booking.status == 'confirmed'
                ? () => _joinTour(booking)
                : null,
            onCancel: booking.status == 'pending'
                ? () => _cancelBooking(booking.id)
                : null,
            onViewJournal: booking.status == 'completed'
                ? () => _viewJournal(booking)
                : null,
          );
        },
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
            const Text('Cancel Booking'),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this booking? '
          'This action cannot be undone and you may not be able to book the same time slot again.',
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
            child: const Text('Cancel Booking', style: TextStyle(color: Colors.white)),
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

  void _joinTour(Booking booking) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.tourist),
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
        'Joining tour! 🎉\nPreparing confirmation screen...',
        AppColors.tourist,
      );

      // Navigate to tour session screen for confirmation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TourSessionScreen(
            booking: booking,
            tourPlan: tourPlan,
            isGuide: false, // Traveler joining the tour
          ),
        ),
      );

    } catch (e) {
      // Hide loading
      if (mounted) Navigator.pop(context);
      
      _showSnackBar(
        'Failed to join tour: $e',
        Colors.red,
      );
    }
  }

  void _viewJournal(Booking booking) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.tourist),
        ),
      );

      // Fetch the tour plan and journal
      final tourRepository = context.read<TourRepository>();
      final tourPlan = await tourRepository.getTourById(booking.tourPlanId);
      
      if (tourPlan == null) {
        throw Exception('Tour plan not found');
      }

      // Get the tour journal using the booking ID
      final journalService = TourJournalService();
      TourJournal? tourJournal = await journalService.getTourJournalByBookingId(booking.id);
      
      // If not found by booking ID, try by tour plan ID as fallback
      if (tourJournal == null) {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          tourJournal = await journalService.getTourJournalByTourPlanId(booking.tourPlanId, currentUserId);
        }
      }

      // Hide loading
      if (mounted) Navigator.pop(context);

      if (tourJournal == null) {
        _showSnackBar('No journal found for this tour', Colors.orange);
        return;
      }

      // Show journal in a full-screen modal
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(
                'Tour Journal - ${tourPlan.title}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: AppColors.tourist,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: TourJournalWidget(
              tourJournal: tourJournal,
              tourPlaces: tourPlan.places,
              visitedPlaces: List.generate(tourPlan.places.length, (index) => true), // All places visited for completed tours
              currentPlaceIndex: tourPlan.places.length - 1, // Last place for completed tours
              onJournalUpdated: (updatedJournal) {
                // Read-only mode for completed tours, no updates allowed
              },
              onClose: () => Navigator.pop(context),
            ),
          ),
        ),
      );

    } catch (e) {
      // Hide loading
      if (mounted) Navigator.pop(context);
      
      _showSnackBar(
        'Failed to load journal: $e',
        Colors.red,
      );
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