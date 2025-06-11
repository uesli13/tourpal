import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../models/booking.dart';
import '../../../../models/place.dart';
import '../../../../models/tour_plan.dart';
import '../../../../models/tour_session.dart';
import '../../../../models/tour_journal.dart';
import '../../../../models/user.dart' as UserModel;
import '../../services/location_tracking_service.dart';
import '../../services/tour_journal_service.dart';
import '../../services/tour_session_service.dart';
import '../widgets/bottom_carousel_widget.dart';
import '../widgets/guide_controls_widget.dart';
import '../../../../core/services/google_directions_service.dart';

class ActiveTourMapScreen extends StatefulWidget {
  final Booking? booking;
  final TourSession? tourSession;
  final TourPlan? tourPlan;
  final bool isRejoining; // Support for rejoining tours
  final String sessionId;
  final bool isGuide;
  final Function(int)? onPlaceTapped;

  const ActiveTourMapScreen({
    super.key,
    this.booking,
    this.tourSession,
    this.tourPlan,
    this.isRejoining = false,
    required this.sessionId,
    required this.isGuide,
    this.onPlaceTapped,
  });

  @override
  State<ActiveTourMapScreen> createState() => _ActiveTourMapScreenState();
}

class _ActiveTourMapScreenState extends State<ActiveTourMapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  late final LocationTrackingService _locationService;
  late final TourSessionService _sessionService;
  late final TourJournalService _journalService;
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  LatLng? _otherPersonLocation;
  int _currentPlaceIndex = 0;
  List<Place> _tourPlaces = [];
  TourSession? _currentSession;
  TourJournal? _tourJournal;
  bool _isGuide = false;
  String? _currentUserId;
  bool _isInitialized = false;
  bool _canExitTour = false;
  
  // Enhanced component visibility management
  bool _showGuideControls = false;
  bool _isCarouselExpanded = false;
  bool _showJournalEntry = false;
  
  // Journal entry state
  int _journalRating = 0;
  final TextEditingController _journalNoteController = TextEditingController();
  File? _selectedJournalImage;
  bool _isUploadingJournalImage = false;
  
  // User profiles for profile image markers
  UserModel.User? _guideProfile;
  UserModel.User? _travelerProfile;

  // Tour state tracking
  List<bool> _visitedPlaces = [];
  bool _tourCompleted = false;

  // Timer for periodic heartbeat updates
  Timer? _heartbeatTimer;

  // Enhanced Google Directions API integration
  Duration? _estimatedTravelTime;
  double? _estimatedDistance;
  List<LatLng> _routePoints = [];
  
  // Animation controllers for smooth UI transitions
  late AnimationController _carouselController;
  late AnimationController _guideControlsController;
  late AnimationController _journalController;
  late Animation<double> _carouselAnimation;
  late Animation<double> _guideControlsAnimation;
  late Animation<double> _journalAnimation;
  
  // Connection status tracking
  bool _isConnected = true;
  Timer? _connectionTimer;
  
  // Exit/rejoin functionality
  Timer? _exitTimer;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    // Enhanced guide detection with multiple fallbacks
    _isGuide = _determineIfUserIsGuide();
    _currentSession = widget.tourSession;
    
    // Initialize animation controllers
    _carouselController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _guideControlsController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _journalController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _carouselAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _carouselController, curve: Curves.easeInOut),
    );
    _guideControlsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _guideControlsController, curve: Curves.easeInOut),
    );
    _journalAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _journalController, curve: Curves.easeInOut),
    );
    
    // Initialize services with proper error handling
    try {
      _locationService = LocationTrackingService();
      _sessionService = TourSessionService();
      _journalService = TourJournalService();
    } catch (e) {
      print('Error initializing services: $e');
      _locationService = LocationTrackingService();
      _sessionService = TourSessionService();
      _journalService = TourJournalService();
    }
    
    _initializeTour();
    _startConnectionMonitoring();
    _startHeartbeat();
  }

  @override
  void dispose() {
    _locationService.dispose();
    _heartbeatTimer?.cancel();
    _connectionTimer?.cancel();
    _exitTimer?.cancel();
    _carouselController.dispose();
    _guideControlsController.dispose();
    _journalController.dispose();
    _journalNoteController.dispose();
    super.dispose();
  }

  bool _determineIfUserIsGuide() {
    // Multiple ways to determine if user is guide
    if (widget.tourPlan?.guideId == _currentUserId) return true;
    if (widget.tourSession?.guideId == _currentUserId) return true;
    if (widget.booking?.travelerId != _currentUserId) return true; // Fallback logic
    return false;
  }

  void _startConnectionMonitoring() {
    _connectionTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkConnection();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentSession != null) {
        _sessionService.sendHeartbeat(_currentSession!.id);
      }
    });
  }

  Future<void> _checkConnection() async {
    try {
      await FirebaseFirestore.instance
          .collection('tourSessions')
          .doc(_currentSession?.id ?? 'test')
          .get();
      if (!_isConnected) {
        setState(() => _isConnected = true);
        _showConnectionRestoredSnackBar();
      }
    } catch (e) {
      if (_isConnected) {
        setState(() => _isConnected = false);
        _showConnectionLostSnackBar();
      }
    }
  }

  Future<void> _initializeTour() async {
    try {
      // Ensure we have tour plan data
      await _ensureTourPlanData();
      
      // Load user profiles for profile image markers
      await _loadUserProfiles();
      
      // Initialize location tracking
      await _locationService.initialize();
      
      // Get current location
      _currentLocation = await _locationService.getCurrentLocation();
      
      // Set up tour places and visited state
      if (widget.tourPlan != null) {
        _tourPlaces = widget.tourPlan!.places;
        _visitedPlaces = List.filled(_tourPlaces.length, false);
      }

      // Initialize or get tour session
      if (widget.isRejoining && _currentSession != null) {
        // Rejoining existing session - restore state
        _currentPlaceIndex = _currentSession!.currentPlaceIndex;
        _canExitTour = true; // Can exit and rejoin
        
        // Mark user as online when rejoining
        await _sessionService.markUserOnline(_currentSession!.id, _isGuide);
        print('Marked user online when rejoining: ${_isGuide ? "Guide" : "Traveler"}');
        
        _showRejoinedTourSnackBar();
      } else {
        // Starting new tour session or joining existing one
        await _createOrUpdateTourSession();
        _canExitTour = true; // Enable exit/rejoin functionality
      }

      // Initialize or get tour journal for travelers
      if (!_isGuide) {
        String sessionIdForJournal = _currentSession?.id ?? widget.sessionId;
        String tourInstanceId = widget.booking?.tourInstanceId ?? sessionIdForJournal;
        
        print('Initializing journal for traveler with sessionId: $sessionIdForJournal, tourInstanceId: $tourInstanceId');
        
        _tourJournal = await _journalService.getTourJournal(sessionIdForJournal);
        if (_tourJournal == null) {
          print('No existing journal found, creating new one...');
          _tourJournal = await _journalService.createTourJournal(
            sessionId: sessionIdForJournal,
            tourPlanId: widget.booking?.tourPlanId ?? widget.tourPlan?.id ?? '',
            guideId: widget.tourPlan?.guideId ?? _currentSession?.guideId ?? '',
            travelerId: _currentUserId ?? '',
          );
          print('Created new journal: ${_tourJournal?.id}');
        } else {
          print('Found existing journal: ${_tourJournal?.id}');
        }
      }
      
      // Create markers for tour places and users
      await _createTourMarkers();
      
      // Get directions to next place
      await _updateDirectionsToNextPlace();
      
      // Start location tracking and session updates
      _locationService.startTracking();
      _startLocationTracking();
      _listenToSessionUpdates();

      // Start carousel animation
      _carouselController.forward();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing tour: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize tour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Load user profiles for profile image markers
  Future<void> _loadUserProfiles() async {
    try {
      // Load guide profile
      if (widget.tourPlan?.guideId != null) {
        final guideDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.tourPlan!.guideId)
            .get();
        if (guideDoc.exists) {
          _guideProfile = UserModel.User.fromMap(guideDoc.data()!, guideDoc.id);
        }
      }

      // Load traveler profile
      if (widget.booking?.travelerId != null) {
        final travelerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.booking!.travelerId)
            .get();
        if (travelerDoc.exists) {
          _travelerProfile = UserModel.User.fromMap(travelerDoc.data()!, travelerDoc.id);
        }
      }
    } catch (e) {
      print('Error loading user profiles: $e');
    }
  }

  // Ensure we have tour plan data, fetch if missing
  Future<void> _ensureTourPlanData() async {
    if (widget.tourPlan != null) return; // Already have tour plan
    
    String? tourPlanId;
    
    // Try to get tour plan ID from different sources
    if (widget.booking != null) {
      tourPlanId = widget.booking!.tourPlanId;
    } else if (widget.tourSession != null) {
      tourPlanId = widget.tourSession!.tourPlanId;
    }
    
    if (tourPlanId != null) {
      try {
        final tourPlanDoc = await FirebaseFirestore.instance
            .collection('tourPlans')
            .doc(tourPlanId)
            .get();
        
        if (tourPlanDoc.exists) {
          // Create a temporary tour plan object for this session
          final tourPlanData = TourPlan.fromMap(tourPlanDoc.data()!, tourPlanDoc.id);
          _tourPlaces = tourPlanData.places;
          
          // Re-evaluate guide status with the fetched data
          if (_currentUserId == tourPlanData.guideId) {
            _isGuide = true;
          }
        }
      } catch (e) {
        print('Error fetching tour plan: $e');
      }
    }
  }

  // Create or update tour session based on entry method
  Future<void> _createOrUpdateTourSession() async {
    if (_currentSession == null && widget.booking != null) {
      // Create new session from booking (this should rarely happen now)
      print('Creating new tour session...');
      _currentSession = await _sessionService.createSession(
        bookingId: widget.booking!.id,
        guideId: widget.tourPlan?.guideId ?? '',
        travelerId: widget.booking!.travelerId,
      );
      print('Created session: ${_currentSession!.id}');
    } else if (_currentSession != null) {
      // Joining existing session (both guide and traveler use this path now)
      print('Joining existing tour session: ${_currentSession!.id}');
      await _sessionService.startSession(_currentSession!.id);
      
      // Mark current user as online when joining existing session
      await _sessionService.markUserOnline(_currentSession!.id, _isGuide);
      print('Marked current user online: ${_isGuide ? "Guide" : "Traveler"}');
    }
    
    // Ensure current user is marked online regardless of how they joined
    if (_currentSession != null) {
      print('Ensuring current user is online...');
      await _sessionService.markUserOnline(_currentSession!.id, _isGuide);
      print('Current user online status confirmed: ${_isGuide ? "Guide" : "Traveler"}');
    }
  }

  void _startLocationTracking() {
    _locationService.locationStream.listen((location) {
      setState(() {
        _currentLocation = location;
      });
      
      // Update location in session for real-time tracking
      if (_currentSession != null) {
        _sessionService.updateUserLocation(
          _currentSession!.id,
          location.latitude,
          location.longitude,
          _isGuide,
        );
      }
      
      // Update markers with new location
      _updateUserLocationMarkers();
      
      // Update directions if location changed significantly
      _updateDirectionsToNextPlace();
    });
    
    // Also immediately mark user online when location tracking starts
    if (_currentSession != null) {
      _sessionService.markUserOnline(_currentSession!.id, _isGuide);
      print('Marked user online when location tracking started: ${_isGuide ? "Guide" : "Traveler"}');
    }
  }

  void _listenToSessionUpdates() {
    if (_currentSession?.id != null) {
      // Listen directly to the session document for better synchronization
      FirebaseFirestore.instance
          .collection('tourSessions')
          .doc(_currentSession!.id)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          final updatedSession = TourSession.fromMap(snapshot.data()!, snapshot.id);
          setState(() {
            _currentSession = updatedSession;
            _currentPlaceIndex = updatedSession.currentPlaceIndex;
            _visitedPlaces = List.generate(_tourPlaces.length, (index) => 
              updatedSession.visitedPlaces.contains(_tourPlaces[index].id)
            );
          });
          
          // Update other person's location if available
          if (_isGuide && updatedSession.travelerLocation != null) {
            final travelerLoc = updatedSession.travelerLocation!;
            setState(() {
              _otherPersonLocation = LatLng(
                travelerLoc['latitude'] ?? 0.0,
                travelerLoc['longitude'] ?? 0.0,
              );
            });
            _updateUserLocationMarkers();
          } else if (!_isGuide && updatedSession.guideLocation != null) {
            final guideLoc = updatedSession.guideLocation!;
            setState(() {
              _otherPersonLocation = LatLng(
                guideLoc['latitude'] ?? 0.0,
                guideLoc['longitude'] ?? 0.0,
              );
            });
            _updateUserLocationMarkers();
          }
          
          // Update tour markers when visited places change
          _createTourMarkers();
          
          // Update directions when current place changes
          _updateDirectionsToNextPlace();
          
          // Check if tour is completed - either by status or all places visited
          final allPlacesVisited = _visitedPlaces.every((visited) => visited);
          if ((updatedSession.status == TourSessionStatus.completed || allPlacesVisited) && !_tourCompleted) {
            setState(() {
              _tourCompleted = true;
              // If all places are visited but currentPlaceIndex hasn't been updated, set it to show completion
              if (allPlacesVisited && _currentPlaceIndex < _tourPlaces.length) {
                _currentPlaceIndex = _tourPlaces.length;
              }
            });
            _showCompletionDialog();
          }
        }
      });
    }
  }

  Future<void> _createTourMarkers() async {
    final Set<Marker> newMarkers = {};
    
    // Add markers for each place in the tour
    for (int i = 0; i < _tourPlaces.length; i++) {
      final place = _tourPlaces[i];
      final isVisited = _visitedPlaces.length > i ? _visitedPlaces[i] : false;
      final isCurrent = i == _currentPlaceIndex;
      
      newMarkers.add(
        Marker(
          markerId: MarkerId('place_$i'),
          position: LatLng(
            place.location.latitude,
            place.location.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isVisited 
                ? BitmapDescriptor.hueGreen 
                : isCurrent 
                    ? BitmapDescriptor.hueOrange 
                    : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.description ?? 'Tour location',
          ),
        ),
      );
    }
    
    setState(() {
      _markers = newMarkers;
    });
    
    // Add user location markers
    await _updateUserLocationMarkers();
  }

  Future<void> _updateUserLocationMarkers() async {
    final Set<Marker> updatedMarkers = Set.from(_markers);
    
    // Remove existing user markers
    updatedMarkers.removeWhere((marker) => 
      marker.markerId.value == 'current_user' || 
      marker.markerId.value == 'other_user'
    );
    
    // Add current user marker
    if (_currentLocation != null) {
      final currentUserMarker = await _createUserMarker(
        'current_user',
        _currentLocation!,
        _isGuide ? _guideProfile : _travelerProfile,
        _isGuide,
        isCurrentUser: true,
      );
      if (currentUserMarker != null) {
        updatedMarkers.add(currentUserMarker);
      }
    }
    
    // Add other user marker
    if (_otherPersonLocation != null) {
      final otherUserMarker = await _createUserMarker(
        'other_user',
        _otherPersonLocation!,
        _isGuide ? _travelerProfile : _guideProfile,
        !_isGuide,
        isCurrentUser: false,
      );
      if (otherUserMarker != null) {
        updatedMarkers.add(otherUserMarker);
      }
    }
    
    setState(() {
      _markers = updatedMarkers;
    });
  }

  Future<Marker?> _createUserMarker(
    String markerId,
    LatLng position,
    UserModel.User? userProfile,
    bool isGuide,
    {required bool isCurrentUser}
  ) async {
    try {
      BitmapDescriptor icon;
      
      if (userProfile?.profileImageUrl != null) {
        // Create custom marker with profile image
        icon = await _createProfileImageMarker(
          userProfile!.profileImageUrl!,
          isGuide,
          isCurrentUser,
        );
      } else {
        // Create person icon marker when no profile image is available
        icon = await _createPersonIconMarker(isGuide, isCurrentUser);
      }
      
      return Marker(
        markerId: MarkerId(markerId),
        position: position,
        icon: icon,
        infoWindow: InfoWindow(
          title: isCurrentUser ? 'You' : (userProfile?.displayName ?? (isGuide ? 'Guide' : 'Traveler')),
          snippet: isGuide ? 'Tour Guide' : 'Traveler',
        ),
      );
    } catch (e) {
      print('Error creating user marker: $e');
      return null;
    }
  }

  Future<BitmapDescriptor> _createProfileImageMarker(
    String imageUrl,
    bool isGuide,
    bool isCurrentUser,
  ) async {
    try {
      // Download the image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load image');
      }
      
      // Create a custom marker with the profile image
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      
      // Marker size
      const double size = 120.0;
      const double imageSize = 80.0;
      
      // Draw marker background circle
      final Paint backgroundPaint = Paint()
        ..color = isCurrentUser 
            ? (isGuide ? AppColors.guide : AppColors.primary)
            : Colors.grey[300]!
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2,
        backgroundPaint,
      );
      
      // Draw white inner circle
      final Paint innerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        (imageSize / 2) + 4,
        innerPaint,
      );
      
      // Draw profile image
      final Uint8List imageBytes = response.bodyBytes;
      final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      // Create circular clip for image
      canvas.clipRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(size / 2, size / 2),
          width: imageSize,
          height: imageSize,
        ),
        const Radius.circular(imageSize / 2),
      ));
      
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromCenter(
          center: const Offset(size / 2, size / 2),
          width: imageSize,
          height: imageSize,
        ),
        Paint(),
      );
      
      // Convert to bitmap
      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image markerImage = await picture.toImage(size.toInt(), size.toInt());
      final ByteData? byteData = await markerImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      
      return BitmapDescriptor.fromBytes(pngBytes);
    } catch (e) {
      print('Error creating profile image marker: $e');
      // Fallback to person icon marker instead of generic marker
      return await _createPersonIconMarker(isGuide, isCurrentUser);
    }
  }

  Future<BitmapDescriptor> _createPersonIconMarker(bool isGuide, bool isCurrentUser) async {
    try {
      // Create a custom marker with person icon
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      
      // Marker size
      const double size = 120.0;
      const double iconSize = 60.0;
      
      // Draw marker background circle
      final Paint backgroundPaint = Paint()
        ..color = isCurrentUser 
            ? (isGuide ? AppColors.guide : AppColors.primary)
            : (isGuide ? AppColors.guide.withOpacity(0.7) : AppColors.primary.withOpacity(0.7))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2,
        backgroundPaint,
      );
      
      // Draw white inner circle
      final Paint innerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        (iconSize / 2) + 8,
        innerPaint,
      );
      
      // Draw person icon
      final Paint iconPaint = Paint()
        ..color = isGuide ? AppColors.guide : AppColors.primary
        ..style = PaintingStyle.fill;
      
      // Draw person head (circle)
      canvas.drawCircle(
        const Offset(size / 2, size / 2 - 8),
        12,
        iconPaint,
      );
      
      // Draw person body (rounded rectangle)
      final RRect bodyRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(size / 2, size / 2 + 12),
          width: 24,
          height: 20,
        ),
        const Radius.circular(12),
      );
      canvas.drawRRect(bodyRect, iconPaint);
      
      // Add a small border around the icon for better visibility
      final Paint borderPaint = Paint()
        ..color = isCurrentUser 
            ? (isGuide ? AppColors.guide : AppColors.primary)
            : Colors.grey[600]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2 - 1.5,
        borderPaint,
      );
      
      // Convert to bitmap
      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image markerImage = await picture.toImage(size.toInt(), size.toInt());
      final ByteData? byteData = await markerImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      
      return BitmapDescriptor.fromBytes(pngBytes);
    } catch (e) {
      print('Error creating person icon marker: $e');
      // Final fallback to default marker
      return BitmapDescriptor.defaultMarkerWithHue(
        isGuide ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueViolet,
      );
    }
  }

  Future<void> _updateDirectionsToNextPlace() async {
    if (_currentLocation == null || _currentPlaceIndex >= _tourPlaces.length) {
      return;
    }
    
    try {
      final nextPlace = _tourPlaces[_currentPlaceIndex];
      final destination = LatLng(
        nextPlace.location.latitude,
        nextPlace.location.longitude,
      );
      
      final directions = await GoogleDirectionsService.getWalkingDirections(
        origin: _currentLocation!,
        destination: destination,
      );
      
      if (directions != null) {
      setState(() {
          _estimatedTravelTime = Duration(minutes: directions.durationValue.round());
          _estimatedDistance = directions.distanceValue;
          _routePoints = directions.polylinePoints;
      });
        
        // Update polylines on map
        _updateRoutePolylines();
      }
    } catch (e) {
      print('Error updating directions: $e');
    }
  }

  void _updateRoutePolylines() {
    final Set<Polyline> newPolylines = {};
    
    if (_routePoints.isNotEmpty) {
      newPolylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
        color: AppColors.primary,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

      setState(() {
      _polylines = newPolylines;
    });
  }

  // Guide functionality - mark place as visited
  Future<void> _onPlaceVisited(int placeIndex) async {
    if (!_isGuide || _currentSession == null || placeIndex >= _tourPlaces.length) {
      return;
    }
    
    try {
      final place = _tourPlaces[placeIndex];
      await _sessionService.markPlaceAsVisited(_currentSession!.id, place.id);
      
      // Update current place index if this was the current place
      if (placeIndex == _currentPlaceIndex && placeIndex < _tourPlaces.length - 1) {
        await _sessionService.updateCurrentPlace(_currentSession!.id, placeIndex + 1);
      }
      
      // Check if this was the last place or if all places are now visited
      final updatedVisitedPlaces = List<bool>.from(_visitedPlaces);
      updatedVisitedPlaces[placeIndex] = true;
      final allPlacesVisited = updatedVisitedPlaces.every((visited) => visited);
      
      if (allPlacesVisited) {
        // Complete the tour when all places are visited
        await _sessionService.completeTour(_currentSession!.id);
        print('Tour completed - all places visited');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${place.name} marked as visited!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error marking place as visited: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark place as visited: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Exit tour functionality
  Future<void> _exitTour() async {
    try {
      // Stop location tracking
      _locationService.dispose();
      
      // Mark user as offline
      if (_currentSession != null) {
        await _sessionService.markUserOffline(_currentSession!.id, _isGuide);
      }
      
      // Show exit confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have exited the tour. You can rejoin anytime.'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Navigate back
      Navigator.of(context).pop();
    } catch (e) {
      print('Error exiting tour: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exiting tour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Enhanced UI feedback methods
  void _showConnectionLostSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text('Connection lost. Trying to reconnect...'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showConnectionRestoredSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi, color: Colors.white),
            SizedBox(width: 8),
            Text('Connection restored!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRejoinedTourSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.refresh, color: Colors.white),
            SizedBox(width: 8),
            Text('Welcome back! Tour resumed.'),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎉 Tour Completed!'),
          content: const Text(
            'Congratulations! You have successfully completed the tour. Thank you for joining us!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Exit tour screen
              },
              child: const Text('Finish'),
            ),
          ],
        );
      },
    );
  }

  // Get tour instance ID for database operations
  String get tourInstanceId {
    return widget.tourSession?.id ?? 
           widget.booking?.tourInstanceId ?? 
           'unknown-instance';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_currentLocation != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(_currentLocation!, 15),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(0, 0),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false, // We use custom markers
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // Connection status indicator
          if (!_isConnected)
          Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                              Text(
                      'Connection lost. Trying to reconnect...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ],
                              ),
              ),
            ),

          // Top controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: Column(
                            children: [
                // Exit tour button
                if (_canExitTour)
                  FloatingActionButton(
                    heroTag: "exit_tour",
                    mini: true,
                    backgroundColor: Colors.red,
                    onPressed: _showExitTourDialog,
                    child: const Icon(Icons.exit_to_app, color: Colors.white),
                  ),
                
                const SizedBox(height: 8),
                
                // My location button
                FloatingActionButton(
                  heroTag: "my_location",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _goToMyLocation,
                  child: const Icon(Icons.my_location, color: AppColors.primary),
                ),
                
                      const SizedBox(height: 8),
                
                // Guide controls button (for guides)
                if (_isGuide)
                  FloatingActionButton(
                    heroTag: "guide_controls",
                    mini: true,
                    backgroundColor: AppColors.guide,
                    onPressed: _toggleGuideControls,
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                            ),
                          ],
                        ),
                      ),

          // Guide controls (for guides)
          if (_isGuide && _showGuideControls)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 20,
              right: 20,
              child: AnimatedBuilder(
                animation: _guideControlsAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - _guideControlsAnimation.value) * -100),
                    child: Opacity(
                      opacity: _guideControlsAnimation.value,
                      child: GuideControlsWidget(
                        currentPlaceIndex: _currentPlaceIndex,
                        tourPlaces: _tourPlaces,
                        visitedPlaces: _visitedPlaces,
                        tourSession: _currentSession,
                        onPlaceChanged: (index) {
                          setState(() {
                            _currentPlaceIndex = index;
                          });
                        },
                        onPlaceVisitedChanged: (index, visited) {
                          _onPlaceVisited(index);
                        },
                        onTourCompleted: () {
                          setState(() {
                            _tourCompleted = true;
                          });
                          _showCompletionDialog();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

          // Bottom carousel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _carouselAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _carouselAnimation.value) * 200),
                  child: BottomCarouselWidget(
        places: _tourPlaces,
        currentPlaceIndex: _currentPlaceIndex,
        visitedPlaces: _visitedPlaces,
                    tourSession: _currentSession,
      isGuide: _isGuide,
      estimatedTravelTime: _estimatedTravelTime,
                    estimatedDistance: _estimatedDistance,
                    guideProfile: _guideProfile,
                    travelerProfile: _travelerProfile,
                    isExpanded: _isCarouselExpanded,
                    onExpansionChanged: _toggleCarouselExpansion,
                    onJournalEntry: !_isGuide ? (index) {
          setState(() {
            _currentPlaceIndex = index;
                        _showJournalEntry = true;
                        // Hide other components
                        _showGuideControls = false;
                        _isCarouselExpanded = false;
                        _guideControlsController.reverse();
                      });
                      _journalController.forward();
                    } : null,
                    onPlaceTapped: (index) {
                      if (_mapController != null && index < _tourPlaces.length) {
                        final place = _tourPlaces[index];
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(place.location.latitude, place.location.longitude),
                            16,
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Enhanced journal entry interface (for travelers)
          if (!_isGuide && _showJournalEntry)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _journalAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - _journalAnimation.value) * MediaQuery.of(context).size.height * 0.6),
                    child: _buildEnhancedJournalEntry(),
                  );
                },
              ),
            ),

          // Traveler quick actions (floating action buttons for travelers)
          if (!_isGuide && !_showJournalEntry && !_isCarouselExpanded)
            Positioned(
              bottom: _isCarouselExpanded 
                  ? MediaQuery.of(context).size.height * 0.45 + 20 
                  : MediaQuery.of(context).size.height * 0.25 + 20, // Above the carousel
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // View all places button
                  FloatingActionButton(
                    heroTag: "view_places",
                    mini: true,
                    backgroundColor: AppColors.primary.withOpacity(0.9),
                    onPressed: () => _showPlacesOverview(),
                    child: const Icon(Icons.list, color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _goToMyLocation() {
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 16),
      );
    }
  }

  void _showExitTourDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit Tour'),
          content: const Text(
            'Are you sure you want to exit the tour? You can rejoin anytime.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exitTour();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  // Enhanced component visibility management
  void _toggleGuideControls() {
    setState(() {
      _showGuideControls = !_showGuideControls;
      if (_showGuideControls) {
        // Hide other components when guide controls are shown
        _isCarouselExpanded = false;
        _showJournalEntry = false;
      }
    });
    
    if (_showGuideControls) {
      _guideControlsController.forward();
    } else {
      _guideControlsController.reverse();
    }
  }

  void _toggleCarouselExpansion() {
      setState(() {
      _isCarouselExpanded = !_isCarouselExpanded;
      if (_isCarouselExpanded) {
        // Hide other components when carousel is expanded
        _showGuideControls = false;
        _showJournalEntry = false;
        _guideControlsController.reverse();
        _journalController.reverse();
      }
    });
  }

  void _toggleJournalEntry() {
    setState(() {
      _showJournalEntry = !_showJournalEntry;
      if (_showJournalEntry) {
        // Hide other components when journal is shown
        _showGuideControls = false;
        _isCarouselExpanded = false;
        _guideControlsController.reverse();
        // Reset form when opening
        _resetJournalForm();
      } else {
        // Reset form when closing
        _resetJournalForm();
      }
    });
    
    if (_showJournalEntry) {
      _journalController.forward();
    } else {
      _journalController.reverse();
    }
  }

  void _resetJournalForm() {
    setState(() {
      _journalRating = 0;
      _journalNoteController.clear();
      _selectedJournalImage = null;
      _isUploadingJournalImage = false;
    });
  }

  // Places overview for travelers
  void _showPlacesOverview() {
    showModalBottomSheet(
        context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
            children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tour Places',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Progress indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primary),
              const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_visitedPlaces.where((v) => v).length} of ${_tourPlaces.length} places visited',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Places list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _tourPlaces.length,
                itemBuilder: (context, index) {
                  final place = _tourPlaces[index];
                  final isVisited = index < _visitedPlaces.length && _visitedPlaces[index];
                  final isCurrent = index == _currentPlaceIndex;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primary.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent ? AppColors.primary : Colors.grey[300]!,
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isVisited ? Colors.green : isCurrent ? AppColors.primary : Colors.grey[300],
                        ),
                        child: Icon(
                          isVisited ? Icons.check : isCurrent ? Icons.location_on : Icons.schedule,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        place.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                            'Stop ${index + 1} • ${place.stayingDuration} min stay',
                style: TextStyle(
                  fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (place.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              place.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isVisited 
                                  ? Colors.green.withOpacity(0.2)
                                  : isCurrent 
                                      ? AppColors.primary.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isVisited ? 'Add Journal' : isCurrent ? 'Current' : 'Upcoming',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isVisited ? Colors.green : isCurrent ? AppColors.primary : Colors.grey,
                              ),
                            ),
                          ),
                          if (isVisited) ...[
                            const SizedBox(height: 4),
                            Icon(
                              Icons.edit_note,
                              size: 16,
                              color: Colors.green,
                            ),
                          ],
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (isVisited) {
                          // Open journal entry for visited places
                          setState(() {
                            _currentPlaceIndex = index;
                            _showJournalEntry = true;
                            // Hide other components
                            _showGuideControls = false;
                            _isCarouselExpanded = false;
                            _guideControlsController.reverse();
                          });
                          _journalController.forward();
                        } else {
                          // Focus on the place on the map for unvisited places
                          if (_currentPlaceIndex != index) {
                            setState(() {
                              _currentPlaceIndex = index;
                            });
                          }
                          _animateToPlace(_tourPlaces[index]);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _animateToPlace(Place place) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(place.location.latitude, place.location.longitude),
          16,
        ),
      );
    }
  }

  Widget _buildEnhancedJournalEntry() {
    if (_currentPlaceIndex >= _tourPlaces.length) return Container();
    
    final place = _tourPlaces[_currentPlaceIndex];
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                    image: place.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(place.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: place.photoUrl == null
                      ? Icon(Icons.place, color: Colors.grey[400], size: 25)
                      : null,
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                      const Text(
                        'Journal Entry',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        place.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                IconButton(
                  onPressed: _toggleJournalEntry,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
          ),
        ],
      ),
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: _buildJournalEntryForm(place),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalEntryForm(Place place) {
    return StatefulBuilder(
      builder: (context, setJournalState) {
        final ImagePicker _picker = ImagePicker();
        
        Future<void> _pickImage() async {
          try {
            final XFile? image = await _picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1024,
              maxHeight: 1024,
              imageQuality: 80,
            );
            
            if (image != null) {
              setState(() {
                _selectedJournalImage = File(image.path);
              });
            }
          } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to pick image: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }

        Future<void> _takePhoto() async {
          try {
            final XFile? image = await _picker.pickImage(
              source: ImageSource.camera,
              maxWidth: 1024,
              maxHeight: 1024,
              imageQuality: 80,
            );
            
            if (image != null) {
              setState(() {
                _selectedJournalImage = File(image.path);
          });
        }
      } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to take photo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

        Future<String?> _uploadImage(File imageFile) async {
          try {
            setState(() {
              _isUploadingJournalImage = true;
            });

            final String fileName = 'journal_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final Reference storageRef = FirebaseStorage.instance
                .ref()
                .child('journal_photos')
                .child(_tourJournal?.id ?? 'unknown')
                .child(fileName);

            final UploadTask uploadTask = storageRef.putFile(imageFile);
            final TaskSnapshot snapshot = await uploadTask;
            final String downloadUrl = await snapshot.ref.getDownloadURL();

            return downloadUrl;
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload image: $e'),
                backgroundColor: Colors.red,
              ),
            );
            return null;
          } finally {
            setState(() {
              _isUploadingJournalImage = false;
            });
          }
        }

        void _showImageSourceDialog() {
          showModalBottomSheet(
      context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
          children: [
                  const Text(
                    'Add Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
            onPressed: () {
                            Navigator.pop(context);
                            _takePhoto();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _pickImage();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Star rating (required)
              Row(
                children: [
                  const Text(
                    'Rate your experience',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _journalRating = index + 1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.star,
                        size: 32,
                        color: index < _journalRating ? Colors.amber : Colors.grey[300],
                      ),
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 24),
              
              // Notes section
              const Text(
                'Add your notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _journalNoteController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Write about your experience at ${place.name}...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Photo section
              const Text(
                'Add photos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              
              // Selected image preview
              if (_selectedJournalImage != null)
                Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(_selectedJournalImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedJournalImage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Photo upload button
              Container(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUploadingJournalImage ? null : _showImageSourceDialog,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppColors.primary),
                  ),
                  icon: _isUploadingJournalImage 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.camera_alt, color: AppColors.primary),
                  label: Text(
                    _selectedJournalImage != null 
                        ? 'Change Photo' 
                        : _isUploadingJournalImage 
                            ? 'Uploading...' 
                            : 'Add Photo',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _toggleJournalEntry,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isUploadingJournalImage ? null : () async {
                        // Validate required star rating
                        if (_journalRating == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please rate your experience (required)'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }

                        try {
                          setState(() {
                            _isUploadingJournalImage = true;
                          });

                          String? photoUrl;
                          if (_selectedJournalImage != null) {
                            photoUrl = await _uploadImage(_selectedJournalImage!);
                            if (photoUrl == null) {
                              // Upload failed, don't proceed
                              return;
                            }
                          }

                          String content = 'Rating: $_journalRating/5 stars';
                          if (_journalNoteController.text.isNotEmpty) {
                            content += '\nNotes: ${_journalNoteController.text}';
                          }
                          
      await _journalService.addJournalEntry(
                            journalId: _tourJournal?.id ?? '',
                            placeId: place.id,
                            type: 'experience',
        content: content,
                            imageUrls: photoUrl != null ? [photoUrl] : null,
                          );
                          
                          // Reset form after successful save
                          setState(() {
                            _journalRating = 0;
                            _journalNoteController.clear();
                            _selectedJournalImage = null;
                          });
                          
                          _toggleJournalEntry();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Journal entry saved successfully!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
    } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to save entry: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          setState(() {
                            _isUploadingJournalImage = false;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isUploadingJournalImage
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Saving...'),
                              ],
                            )
                          : const Text(
                              'Save Entry',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}