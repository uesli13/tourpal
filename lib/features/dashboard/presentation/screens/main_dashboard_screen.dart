import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../tours/presentation/screens/active_tour_map_screen.dart';
import '../../../../models/booking.dart';
import '../../../../models/tour_session.dart';

class MainDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const MainDashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  String? _currentUserId;
  TourSession? _activeTourSession;
  List<Booking> _recentBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  void _initializeDashboard() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _currentUserId = authState.user.id;
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    if (_currentUserId == null) return;

    try {
      // Load active tour session
      await _loadActiveTourSession();
      
      // Load recent bookings
      await _loadRecentBookings();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActiveTourSession() async {
    try {
      final sessionsQuery = await FirebaseFirestore.instance
          .collection('tourSessions')
          .where('travelerId', isEqualTo: _currentUserId)
          .where('status', whereIn: ['active', 'waitingForTraveler', 'scheduled'])
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (sessionsQuery.docs.isNotEmpty) {
        final sessionData = sessionsQuery.docs.first.data();
        _activeTourSession = TourSession.fromMap(sessionData, sessionsQuery.docs.first.id);
      }
    } catch (e) {
      print('Error loading active tour session: $e');
    }
  }

  Future<void> _loadRecentBookings() async {
    try {
      final bookingsQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('travelerId', isEqualTo: _currentUserId)
          .orderBy('bookedAt', descending: true)
          .limit(3)
          .get();

      _recentBookings = bookingsQuery.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error loading recent bookings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active tour banner
              if (_activeTourSession != null)
                _buildActiveTourBanner(),
              
              // Welcome section
              _buildWelcomeSection(),
              
              const SizedBox(height: 24),
              
              // Quick stats
              _buildQuickStats(),
              
              const SizedBox(height: 24),
              
              // Quick actions
              _buildQuickActions(),
              
              const SizedBox(height: 24),
              
              // Recent bookings
              _buildRecentBookings(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTourBanner() {
    final session = _activeTourSession!;
    final isActive = session.status == TourSessionStatus.active;
    final isWaiting = session.status == TourSessionStatus.waitingForTraveler;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive 
              ? [Colors.green.shade400, Colors.green.shade600]
              : [AppColors.primary.withOpacity(0.8), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isActive ? Colors.green : AppColors.primary).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.tour : Icons.schedule,
              color: isActive ? Colors.green.shade600 : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Tour in Progress' : 'Tour Starting Soon',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isActive 
                      ? 'Follow your guide\'s instructions'
                      : isWaiting 
                          ? 'Your guide is ready to start'
                          : 'Waiting for confirmation',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _joinActiveTour(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: isActive ? Colors.green.shade600 : AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(isActive ? 'View Tour' : 'Join Tour'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Discover amazing tours and experiences',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
          ),
        ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
        children: [
        Expanded(
          child: _buildStatCard(
            title: 'Active Tours',
            value: _activeTourSession != null ? '1' : '0',
            icon: Icons.tour,
            color: _activeTourSession != null ? Colors.green : AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
          Expanded(
          child: _buildStatCard(
            title: 'Total Bookings',
            value: _recentBookings.length.toString(),
            icon: Icons.book_online,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.explore,
                    label: 'Explore Tours',
                    color: AppColors.primary,
                    onTap: () => widget.onNavigateToTab?.call(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.event,
                    label: 'My Bookings',
                    color: AppColors.secondary,
                    onTap: () => widget.onNavigateToTab?.call(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.book,
                    label: 'Tour Journal',
                    color: Colors.orange,
                    onTap: () => _showTourJournalInfo(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.map,
                    label: 'Live Tours',
                    color: Colors.green,
                    onTap: () => _showLiveToursInfo(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookings() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
                  'Recent Bookings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateToTab?.call(2),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentBookings.isEmpty)
            const Center(
              child: Column(
                children: [
                  Icon(
                      Icons.event_busy,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 8),
                  Text(
                      'No bookings yet',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                    SizedBox(height: 4),
                    Text(
                      'Start exploring tours to make your first booking!',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
              )
            else
              ...(_recentBookings.map((booking) => _buildBookingItem(booking))),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingItem(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(booking.status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(booking.status),
              color: _getStatusColor(booking.status),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tour Booking',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _formatBookingStatus(booking.status),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(booking.status),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(booking.bookedAt.toDate()),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _joinActiveTour() async {
    if (_activeTourSession == null) return;

    try {
      // Get booking and tour plan data
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .where('travelerId', isEqualTo: _currentUserId)
          .where('tourPlanId', isEqualTo: _activeTourSession!.tourPlanId)
          .limit(1)
          .get();

      if (bookingDoc.docs.isNotEmpty) {
        final booking = Booking.fromMap(bookingDoc.docs.first.data(), bookingDoc.docs.first.id);
        
        // Navigate to active tour screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveTourMapScreen(
              booking: booking,
              tourSession: _activeTourSession,
              sessionId: _activeTourSession!.id,
              isGuide: false,
              isRejoining: true,
            ),
          ),
        );
      }
    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Error joining tour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTourJournalInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tour Journal'),
        content: const Text(
          'Your personal travel diary! During active tours, you can:\n\n'
          '• Write notes about places you visit\n'
          '• Rate your experiences\n'
          '• Add photos and memories\n'
          '• Track your tour progress\n\n'
          'Start a tour to access your journal!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showLiveToursInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Tours'),
        content: const Text(
          'Experience real-time guided tours with:\n\n'
          '• Live location tracking\n'
          '• Interactive maps with directions\n'
          '• Real-time communication with guides\n'
          '• Progress tracking through tour stops\n'
          '• Exit and rejoin functionality\n\n'
          'Book a tour to experience live guidance!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onNavigateToTab?.call(1); // Go to explore
            },
            child: const Text('Explore Tours'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  String _formatBookingStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      default:
        return status.toUpperCase();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}