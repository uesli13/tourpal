import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../bookings/presentation/screens/guide_bookings_screen.dart';
import '../../../tours/presentation/screens/create_tour_screen.dart';
import '../../../tours/presentation/screens/active_tour_map_screen.dart';
import '../../../../models/booking.dart';
import '../../../../models/tour_session.dart';
import '../../../../models/tour_plan.dart';

class GuideDashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  
  const GuideDashboardScreen({super.key, this.onNavigateToTab});

  @override
  State<GuideDashboardScreen> createState() => _GuideDashboardScreenState();
}

class _GuideDashboardScreenState extends State<GuideDashboardScreen> {
  String? _currentUserId;
  TourSession? _activeTourSession;
  List<Booking> _recentBookings = [];
  List<TourPlan> _myTours = [];
  bool _isLoading = true;
  int _totalBookings = 0;
  int _activeTours = 0;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  void _initializeDashboard() {
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserId != null) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    if (_currentUserId == null) return;

    try {
      // Load all data in parallel
      await Future.wait([
        _loadActiveTourSession(),
        _loadRecentBookings(),
        _loadMyTours(),
        _loadStats(),
      ]);
      
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
          .where('guideId', isEqualTo: _currentUserId)
          .where('status', whereIn: ['active', 'waitingForTraveler', 'scheduled'])
          .orderBy('scheduledStartTime', descending: true)
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
      // Get bookings for tours created by this guide
      final myToursQuery = await FirebaseFirestore.instance
          .collection('tourPlans')
          .where('guideId', isEqualTo: _currentUserId)
          .get();

      if (myToursQuery.docs.isNotEmpty) {
        final tourPlanIds = myToursQuery.docs.map((doc) => doc.id).toList();
        
        final bookingsQuery = await FirebaseFirestore.instance
            .collection('bookings')
            .where('tourPlanId', whereIn: tourPlanIds)
            .orderBy('bookedAt', descending: true)
            .limit(5)
            .get();

        _recentBookings = bookingsQuery.docs
            .map((doc) => Booking.fromMap(doc.data(), doc.id))
            .toList();
      }
    } catch (e) {
      print('Error loading recent bookings: $e');
    }
  }

  Future<void> _loadMyTours() async {
    try {
      final toursQuery = await FirebaseFirestore.instance
          .collection('tourPlans')
          .where('guideId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      _myTours = toursQuery.docs
          .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error loading my tours: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      // Count total bookings for this guide's tours
      final myToursQuery = await FirebaseFirestore.instance
          .collection('tourPlans')
          .where('guideId', isEqualTo: _currentUserId)
          .get();

      if (myToursQuery.docs.isNotEmpty) {
        final tourPlanIds = myToursQuery.docs.map((doc) => doc.id).toList();
        
        final bookingsQuery = await FirebaseFirestore.instance
            .collection('bookings')
            .where('tourPlanId', whereIn: tourPlanIds)
            .get();

        _totalBookings = bookingsQuery.docs.length;
      }

      // Count active tours (sessions)
      final activeSessionsQuery = await FirebaseFirestore.instance
          .collection('tourSessions')
          .where('guideId', isEqualTo: _currentUserId)
          .where('status', whereIn: ['active', 'waitingForTraveler'])
          .get();

      _activeTours = activeSessionsQuery.docs.length;
    } catch (e) {
      print('Error loading stats: $e');
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Guide Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.secondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadDashboardData();
            },
          ),
        ],
      ),
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
              
              // Stats cards
              _buildStatsCards(),
              
              const SizedBox(height: 24),
              
              // Quick actions
              _buildQuickActions(),
              
              const SizedBox(height: 24),
              
              // Recent bookings
              _buildRecentBookings(),
              
              const SizedBox(height: 24),
              
              // My tours
              _buildMyTours(),
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
              : [AppColors.guide.withOpacity(0.8), AppColors.guide],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isActive ? Colors.green : AppColors.guide).withOpacity(0.3),
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
              color: isActive ? Colors.green.shade600 : AppColors.guide,
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
                      ? 'Guide your traveler through the tour'
                      : isWaiting 
                          ? 'Waiting for traveler to join'
                          : 'Tour scheduled to start',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _manageActiveTour(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: isActive ? Colors.green.shade600 : AppColors.guide,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(isActive ? 'Manage Tour' : 'Start Tour'),
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
              'Welcome, Guide!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
          'Manage your tours and guide amazing experiences',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Active Tours',
            value: _activeTours.toString(),
            icon: Icons.tour,
            color: _activeTours > 0 ? Colors.green : AppColors.guide,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Total Bookings',
            value: _totalBookings.toString(),
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
            Builder(
              builder: (context) => Column(
                children: [
                  _buildActionRow(
                    context: context,
                    icon: Icons.add_circle_outline,
                    label: 'Create New Tour',
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateTourScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionRow(
                    context: context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Manage Bookings',
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GuideBookingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionRow(
                    context: context,
                    icon: Icons.tour_outlined,
                    label: 'View My Tours',
                    color: AppColors.guide,
                    onTap: () => widget.onNavigateToTab?.call(1),
                  ),
                  const SizedBox(height: 12),
                  _buildActionRow(
                    context: context,
                    icon: Icons.schedule_outlined,
                    label: 'View Schedule',
                    color: AppColors.info,
                    onTap: () => widget.onNavigateToTab?.call(2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GuideBookingsScreen(),
                      ),
                    );
                  },
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
                      'Create tours to start receiving bookings!',
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
              ...(_recentBookings.take(3).map((booking) => _buildBookingItem(booking))),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTours() {
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
                  'My Tours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateToTab?.call(1),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_myTours.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.tour,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No tours created yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Create your first tour to start guiding!',
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
              ...(_myTours.map((tour) => _buildTourItem(tour))),
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

  Widget _buildTourItem(TourPlan tour) {
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
              color: AppColors.guide.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.tour,
              color: AppColors.guide,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tour.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${tour.places.length} places • ${tour.duration} hours',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '€${tour.price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.guide,
            ),
          ),
        ],
      ),
    );
  }

  void _manageActiveTour() async {
    if (_activeTourSession == null) return;

    try {
      // Get booking and tour plan data
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .where('tourPlanId', isEqualTo: _activeTourSession!.tourPlanId)
          .where('travelerId', isEqualTo: _activeTourSession!.travelerId)
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
              isGuide: true,
              isRejoining: true,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error managing tour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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