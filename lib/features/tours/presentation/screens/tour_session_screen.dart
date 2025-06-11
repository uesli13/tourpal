import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/booking.dart';
import '../../../../models/tour_session.dart';
import '../../../../models/tour_plan.dart';
import '../../../../models/user.dart' as UserModel;
import 'active_tour_map_screen.dart';

class TourSessionScreen extends StatefulWidget {
  final Booking booking;
  final TourPlan tourPlan;
  final bool isGuide;

  const TourSessionScreen({
    super.key,
    required this.booking,
    required this.tourPlan,
    this.isGuide = false,
  });

  @override
  State<TourSessionScreen> createState() => _TourSessionScreenState();
}

class _TourSessionScreenState extends State<TourSessionScreen> with TickerProviderStateMixin {
  TourSession? _tourSession;
  bool _isLoading = true;
  bool _isReady = false;
  bool _isGuide = false;
  StreamSubscription<DocumentSnapshot>? _sessionSubscription;
  
  // Enhanced UI elements
  late AnimationController _pulseController;
  late AnimationController _readyController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _readyAnimation;
  
  // User profiles for better UI
  UserModel.User? _guideProfile;
  UserModel.User? _travelerProfile;
  
  // Connection status
  bool _isConnected = true;
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();
    _isGuide = widget.isGuide || _determineIfUserIsGuide();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _readyController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _readyAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _readyController, curve: Curves.elasticOut),
    );
    
    _pulseController.repeat(reverse: true);
    
    _initializeSession();
    _loadUserProfiles();
    _startConnectionMonitoring();
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _connectionTimer?.cancel();
    _pulseController.dispose();
    _readyController.dispose();
    super.dispose();
  }

  bool _determineIfUserIsGuide() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return currentUserId == widget.tourPlan.guideId;
  }

  Future<void> _loadUserProfiles() async {
    try {
      // Load guide profile
      final guideDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.tourPlan.guideId)
          .get();
      if (guideDoc.exists) {
        _guideProfile = UserModel.User.fromMap(guideDoc.data()!, guideDoc.id);
      }

      // Load traveler profile
      final travelerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.booking.travelerId)
          .get();
      if (travelerDoc.exists) {
        _travelerProfile = UserModel.User.fromMap(travelerDoc.data()!, travelerDoc.id);
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      print('Error loading user profiles: $e');
    }
  }

  void _startConnectionMonitoring() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    try {
      await FirebaseFirestore.instance
          .collection('tourSessions')
          .doc(_tourSession?.id ?? 'test')
          .get();
      if (!_isConnected) {
        setState(() => _isConnected = true);
      }
    } catch (e) {
      if (_isConnected) {
        setState(() => _isConnected = false);
      }
    }
  }

  Future<void> _initializeSession() async {
    try {
      _tourSession = await _getOrCreateTourSession();
      _listenToSessionUpdates();
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing session: $e');
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to initialize tour session', e.toString());
    }
  }

  Future<TourSession> _getOrCreateTourSession() async {
    // First, try to find existing session by booking ID
    final sessionQuery = await FirebaseFirestore.instance
        .collection('tourSessions')
        .where('bookingId', isEqualTo: widget.booking.id)
        .limit(1)
        .get();

    if (sessionQuery.docs.isNotEmpty) {
      // Session exists, return it
      final session = TourSession.fromMap(
        sessionQuery.docs.first.data(),
        sessionQuery.docs.first.id,
      );
      print('Found existing session: ${session.id}');
      return session;
    } else {
      // No session exists, create new one (this should only happen for guides)
      if (!_isGuide) {
        throw Exception('No tour session found. Please wait for the guide to start the tour.');
      }
      
      print('Creating new tour session...');
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      final sessionData = {
        'bookingId': widget.booking.id,
        'tourPlanId': widget.booking.tourPlanId,
        'guideId': widget.tourPlan.guideId,
        'travelerIds': [widget.booking.travelerId],
        'travelerId': widget.booking.travelerId, // For backward compatibility
        'status': 'scheduled', // Start as scheduled, becomes active when both ready
        'currentPlaceIndex': 0,
        'guideReady': false,
        'travelerReady': false,
        'startTime': widget.booking.startTime,
        'tourInstanceId': widget.booking.tourInstanceId,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'guideLocation': null,
        'travelerLocation': null,
        'visitedPlaces': <String>[],
        // Enhanced online status tracking
        'guideOnline': _isGuide,
        'travelerOnline': false,
        'guideLastSeen': _isGuide ? Timestamp.now() : null,
        'travelerLastSeen': null,
        // Connection quality tracking
        'connectionQuality': 'good',
        // Use single Timestamp format to match existing database
        'lastHeartbeat': Timestamp.now(),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('tourSessions')
          .add(sessionData);
      
      final newSession = TourSession.fromMap(sessionData, docRef.id);
      print('Created session: ${newSession.id}');
      return newSession;
    }
  }

  void _listenToSessionUpdates() {
    if (_tourSession == null) return;

    _sessionSubscription = FirebaseFirestore.instance
        .collection('tourSessions')
        .doc(_tourSession!.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final session = TourSession.fromMap(snapshot.data()!, snapshot.id);
        final wasReady = _isReady;
        
        setState(() {
          _tourSession = session;
          _isReady = _isGuide ? session.guideReady : session.travelerReady;
        });

        // Trigger ready animation if just became ready
        if (!wasReady && _isReady) {
          _readyController.forward();
        }

        // Navigate to active tour if both are ready and session is active
        if (session.status == TourSessionStatus.active && 
            session.guideReady && 
            session.travelerReady) {
          _navigateToActiveTour();
        }
      }
    });
  }

  Future<void> _updateReadiness(bool isReady) async {
    if (_tourSession == null) return;

    print('Updating readiness: ${_isGuide ? "Guide" : "Traveler"} = $isReady');
    
    final field = _isGuide ? 'guideReady' : 'travelerReady';
    final onlineField = _isGuide ? 'guideOnline' : 'travelerOnline';
    final lastSeenField = _isGuide ? 'guideLastSeen' : 'travelerLastSeen';
    
    try {
      // Prepare update data
      final updateData = {
        field: isReady,
        onlineField: isReady, // Mark as online when ready
        lastSeenField: Timestamp.now(),
        'updatedAt': Timestamp.now(),
        // Keep the existing single Timestamp format for heartbeat
        'lastHeartbeat': Timestamp.now(),
      };

      // If guide is becoming ready, update status to waitingForTraveler
      if (_isGuide && isReady) {
        updateData['status'] = 'waitingForTraveler';
        print('Guide ready - updating status to waitingForTraveler');
      }

      await FirebaseFirestore.instance
          .collection('tourSessions')
          .doc(_tourSession!.id)
          .update(updateData);

      // Check if both users are ready to start the tour
      if (isReady) {
        // Get the latest session data to check both readiness states
        final sessionDoc = await FirebaseFirestore.instance
            .collection('tourSessions')
            .doc(_tourSession!.id)
            .get();
        
        if (sessionDoc.exists) {
          final sessionData = sessionDoc.data()!;
          final guideReady = sessionData['guideReady'] ?? false;
          final travelerReady = sessionData['travelerReady'] ?? false;
          
          print('Readiness check - Guide: $guideReady, Traveler: $travelerReady');
          
          if (guideReady && travelerReady) {
            print('Both users ready - starting tour session');
            await _startTourSession();
          }
        }
      }
    } catch (e) {
      print('Error updating readiness: $e');
      _showErrorSnackBar('Failed to update readiness. Please try again.');
    }
  }

  Future<void> _startTourSession() async {
    if (_tourSession == null) return;

    print('Starting tour session...');
    try {
      await FirebaseFirestore.instance
          .collection('tourSessions')
          .doc(_tourSession!.id)
          .update({
        'status': 'active',
        'actualStartTime': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error starting tour session: $e');
      _showErrorSnackBar('Failed to start tour session.');
    }
  }

  void _navigateToActiveTour() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveTourMapScreen(
          booking: widget.booking,
          tourSession: _tourSession,
          tourPlan: widget.tourPlan,
          sessionId: _tourSession?.id ?? '',
          isGuide: _isGuide,
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Also exit the tour screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Preparing your tour...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced Header
            _buildHeader(),
            
            // Connection Status
            if (!_isConnected) _buildConnectionWarning(),
            
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Tour Info Card
                    _buildTourInfoCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Participants Status
                    _buildParticipantsStatus(),
                    
                    const SizedBox(height: 32),
                    
                    // Ready Button
                    _buildReadyButton(),
                    
                    const SizedBox(height: 24),
                    
                    // Instructions
                    _buildInstructions(),
                    
                    const SizedBox(height: 24),
                    
                    // Debug section (remove in production)
                    if (_tourSession != null) _buildDebugSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tour Confirmation',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _isGuide ? 'Waiting for traveler confirmation' : 'Confirm your readiness',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Role indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (_isGuide ? AppColors.guide : AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isGuide ? 'GUIDE' : 'TRAVELER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _isGuide ? AppColors.guide : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Connection issues detected. Please check your internet.',
              style: TextStyle(color: Colors.orange, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTourInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primary.withOpacity(0.1),
                  image: widget.tourPlan.coverImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(widget.tourPlan.coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.tourPlan.coverImageUrl == null
                    ? Icon(Icons.tour, color: AppColors.primary, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tourPlan.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.tourPlan.duration}h',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.place, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.tourPlan.places.length} places',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Scheduled: ${_formatDateTime(widget.booking.startTime.toDate())}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsStatus() {
    final guideReady = _tourSession?.guideReady ?? false;
    final travelerReady = _tourSession?.travelerReady ?? false;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Participants Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Guide Status
          _buildParticipantRow(
            name: _guideProfile?.displayName ?? 'Guide',
            role: 'Guide',
            isReady: guideReady,
            isCurrentUser: _isGuide,
            profileImageUrl: _guideProfile?.profileImageUrl,
          ),
          
          const SizedBox(height: 12),
          
          // Traveler Status
          _buildParticipantRow(
            name: _travelerProfile?.displayName ?? 'Traveler',
            role: 'Traveler',
            isReady: travelerReady,
            isCurrentUser: !_isGuide,
            profileImageUrl: _travelerProfile?.profileImageUrl,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantRow({
    required String name,
    required String role,
    required bool isReady,
    required bool isCurrentUser,
    String? profileImageUrl,
  }) {
    return Row(
      children: [
        // Profile Image
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            image: profileImageUrl != null
                ? DecorationImage(
                    image: NetworkImage(profileImageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: profileImageUrl == null
              ? Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: 20,
                )
              : null,
        ),
        
        const SizedBox(width: 12),
        
        // Name and Role
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'YOU',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                role,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        
        // Status Indicator
        AnimatedBuilder(
          animation: isReady ? _readyAnimation : _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isReady ? _readyAnimation.value : (isCurrentUser && !isReady ? _pulseAnimation.value : 1.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isReady 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isReady ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isReady ? Icons.check_circle : Icons.schedule,
                      size: 16,
                      color: isReady ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isReady ? 'Ready' : 'Waiting',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isReady ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReadyButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isReady ? null : () => _updateReadiness(true),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isReady ? Colors.green : AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _isReady ? 0 : 4,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isReady
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'You\'re Ready!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      _isGuide ? 'I\'m Ready to Guide' : 'I\'m Ready to Explore',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    final guideReady = _tourSession?.guideReady ?? false;
    final travelerReady = _tourSession?.travelerReady ?? false;
    
    String instructionText;
    IconData instructionIcon;
    Color instructionColor;
    
    if (_isReady) {
      if (_isGuide && !travelerReady) {
        instructionText = 'Waiting for traveler to confirm they\'re ready...';
        instructionIcon = Icons.hourglass_empty;
        instructionColor = Colors.orange;
      } else if (!_isGuide && !guideReady) {
        instructionText = 'Waiting for guide to confirm they\'re ready...';
        instructionIcon = Icons.hourglass_empty;
        instructionColor = Colors.orange;
      } else if (guideReady && travelerReady) {
        instructionText = 'Both participants ready! Starting tour...';
        instructionIcon = Icons.rocket_launch;
        instructionColor = Colors.green;
      } else {
        instructionText = 'Great! You\'re ready for the tour.';
        instructionIcon = Icons.check_circle;
        instructionColor = Colors.green;
      }
    } else {
      instructionText = _isGuide 
          ? 'Confirm you\'re ready to start guiding this tour. The traveler will be notified.'
          : 'Confirm you\'re ready to start this tour. Your guide is waiting for you.';
      instructionIcon = Icons.info_outline;
      instructionColor = AppColors.primary;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: instructionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: instructionColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            instructionIcon,
            color: instructionColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              instructionText,
              style: TextStyle(
                fontSize: 14,
                color: instructionColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Debug Info',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Session ID: ${_tourSession!.id}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            'Status: ${_tourSession!.status}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            'Guide Ready: ${_tourSession!.guideReady}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            'Traveler Ready: ${_tourSession!.travelerReady}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            'Current User: ${_isGuide ? "Guide" : "Traveler"}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            'Is Ready: $_isReady',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (bookingDate.isAtSameMomentAs(today)) {
      dateStr = 'Today';
    } else if (bookingDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}';
    }
    
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }
}