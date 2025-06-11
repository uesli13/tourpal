import 'package:cloud_firestore/cloud_firestore.dart';

enum TourSessionStatus {
  scheduled,
  waitingForTraveler, // New status for confirmation flow
  active,
  paused,
  completed,
  cancelled,
  expired, // For cleanup of old sessions
}

class TourSession {
  final String id;
  final String bookingId;
  final String tourPlanId;
  final String guideId;
  final String travelerId;
  final TourSessionStatus status;
  final Timestamp scheduledStartTime;
  final Timestamp? actualStartTime;
  final Timestamp? actualEndTime;
  final int currentPlaceIndex;
  final List<String> visitedPlaces;
  
  // Enhanced online status tracking
  final bool guideOnline;
  final bool travelerOnline;
  
  // Enhanced ready status for confirmation flow
  final bool guideReady;
  final bool travelerReady;
  
  // Location tracking
  final Map<String, dynamic>? guideLocation;
  final Map<String, dynamic>? travelerLocation;
  
  // Enhanced heartbeat system
  final Map<String, Timestamp> lastHeartbeat;
  
  // Exit/rejoin functionality
  final bool canRejoin;
  final List<String> exitHistory; // Track who exited when
  
  // Notifications system
  final Map<String, dynamic> notifications;
  
  // Enhanced metadata
  final Map<String, dynamic> metadata;

  TourSession({
    required this.id,
    required this.bookingId,
    required this.tourPlanId,
    required this.guideId,
    required this.travelerId,
    required this.status,
    required this.scheduledStartTime,
    this.actualStartTime,
    this.actualEndTime,
    this.currentPlaceIndex = 0,
    this.visitedPlaces = const [],
    this.guideOnline = false,
    this.travelerOnline = false,
    this.guideReady = false,
    this.travelerReady = false,
    this.guideLocation,
    this.travelerLocation,
    this.lastHeartbeat = const {},
    this.canRejoin = true,
    this.exitHistory = const [],
    this.notifications = const {},
    this.metadata = const {},
  });

  // Enhanced factory constructor with better error handling
  factory TourSession.fromMap(Map<String, dynamic> map, [String? documentId]) {
    try {
    return TourSession(
        id: documentId ?? map['id'] ?? '',
        bookingId: map['bookingId'] ?? '',
        tourPlanId: map['tourPlanId'] ?? '',
        guideId: map['guideId'] ?? '',
        travelerId: map['travelerId'] ?? '',
        status: _parseStatus(map['status']),
        scheduledStartTime: map['scheduledStartTime'] ?? Timestamp.now(),
        actualStartTime: map['actualStartTime'],
        actualEndTime: map['actualEndTime'],
        currentPlaceIndex: map['currentPlaceIndex'] ?? 0,
      visitedPlaces: List<String>.from(map['visitedPlaces'] ?? []),
        guideOnline: map['guideOnline'] ?? false,
        travelerOnline: map['travelerOnline'] ?? false,
        guideReady: map['guideReady'] ?? false,
        travelerReady: map['travelerReady'] ?? false,
        guideLocation: map['guideLocation'],
        travelerLocation: map['travelerLocation'],
        lastHeartbeat: _parseHeartbeat(map['lastHeartbeat']),
        canRejoin: map['canRejoin'] ?? true,
        exitHistory: List<String>.from(map['exitHistory'] ?? []),
        notifications: Map<String, dynamic>.from(map['notifications'] ?? {}),
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      );
    } catch (e) {
      print('Error parsing TourSession from map: $e');
      // Return a minimal valid session to prevent crashes
      return TourSession(
        id: documentId ?? map['id'] ?? '',
        bookingId: map['bookingId'] ?? '',
        tourPlanId: map['tourPlanId'] ?? '',
        guideId: map['guideId'] ?? '',
        travelerId: map['travelerId'] ?? '',
        status: TourSessionStatus.scheduled,
        scheduledStartTime: Timestamp.now(),
      );
    }
  }

  static TourSessionStatus _parseStatus(dynamic status) {
    if (status == null) return TourSessionStatus.scheduled;
    
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'scheduled':
          return TourSessionStatus.scheduled;
        case 'waitingfortraveler':
        case 'waiting_for_traveler':
          return TourSessionStatus.waitingForTraveler;
        case 'active':
          return TourSessionStatus.active;
        case 'paused':
          return TourSessionStatus.paused;
        case 'completed':
          return TourSessionStatus.completed;
        case 'cancelled':
          return TourSessionStatus.cancelled;
        case 'expired':
          return TourSessionStatus.expired;
        default:
          return TourSessionStatus.scheduled;
      }
    }
    
    return TourSessionStatus.scheduled;
  }

  static Map<String, Timestamp> _parseHeartbeat(dynamic heartbeat) {
    if (heartbeat == null) return {};
    
    try {
      // Handle single Timestamp (legacy format)
      if (heartbeat is Timestamp) {
        return {'unknown': heartbeat};
      }
      
      // Handle Map format (current format)
      if (heartbeat is Map) {
        final Map<String, dynamic> heartbeatMap = Map<String, dynamic>.from(heartbeat);
        final result = <String, Timestamp>{};
        
        heartbeatMap.forEach((key, value) {
          if (value is Timestamp) {
            result[key] = value;
          } else if (value is int) {
            result[key] = Timestamp.fromMillisecondsSinceEpoch(value);
          }
        });
        
        return result;
      }
      
      return {};
    } catch (e) {
      print('Error parsing heartbeat: $e');
      return {};
    }
  }

  // Enhanced toMap with all new fields
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'tourPlanId': tourPlanId,
      'guideId': guideId,
      'travelerId': travelerId,
      'status': _statusToString(status),
      'scheduledStartTime': scheduledStartTime,
      'actualStartTime': actualStartTime,
      'actualEndTime': actualEndTime,
      'currentPlaceIndex': currentPlaceIndex,
      'visitedPlaces': visitedPlaces,
      'guideOnline': guideOnline,
      'travelerOnline': travelerOnline,
      'guideReady': guideReady,
      'travelerReady': travelerReady,
      'guideLocation': guideLocation,
      'travelerLocation': travelerLocation,
      'lastHeartbeat': lastHeartbeat,
      'canRejoin': canRejoin,
      'exitHistory': exitHistory,
      'notifications': notifications,
      'metadata': metadata,
    };
  }

  String _statusToString(TourSessionStatus status) {
    switch (status) {
      case TourSessionStatus.scheduled:
        return 'scheduled';
      case TourSessionStatus.waitingForTraveler:
        return 'waitingForTraveler';
      case TourSessionStatus.active:
        return 'active';
      case TourSessionStatus.paused:
        return 'paused';
      case TourSessionStatus.completed:
        return 'completed';
      case TourSessionStatus.cancelled:
        return 'cancelled';
      case TourSessionStatus.expired:
        return 'expired';
    }
  }

  // Enhanced copyWith method
  TourSession copyWith({
    String? id,
    String? bookingId,
    String? tourPlanId,
    String? guideId,
    String? travelerId,
    TourSessionStatus? status,
    Timestamp? scheduledStartTime,
    Timestamp? actualStartTime,
    Timestamp? actualEndTime,
    int? currentPlaceIndex,
    List<String>? visitedPlaces,
    bool? guideOnline,
    bool? travelerOnline,
    bool? guideReady,
    bool? travelerReady,
    Map<String, dynamic>? guideLocation,
    Map<String, dynamic>? travelerLocation,
    Map<String, Timestamp>? lastHeartbeat,
    bool? canRejoin,
    List<String>? exitHistory,
    Map<String, dynamic>? notifications,
    Map<String, dynamic>? metadata,
  }) {
    return TourSession(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      tourPlanId: tourPlanId ?? this.tourPlanId,
      guideId: guideId ?? this.guideId,
      travelerId: travelerId ?? this.travelerId,
      status: status ?? this.status,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      currentPlaceIndex: currentPlaceIndex ?? this.currentPlaceIndex,
      visitedPlaces: visitedPlaces ?? this.visitedPlaces,
      guideOnline: guideOnline ?? this.guideOnline,
      travelerOnline: travelerOnline ?? this.travelerOnline,
      guideReady: guideReady ?? this.guideReady,
      travelerReady: travelerReady ?? this.travelerReady,
      guideLocation: guideLocation ?? this.guideLocation,
      travelerLocation: travelerLocation ?? this.travelerLocation,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      canRejoin: canRejoin ?? this.canRejoin,
      exitHistory: exitHistory ?? this.exitHistory,
      notifications: notifications ?? this.notifications,
      metadata: metadata ?? this.metadata,
    );
  }

  // Utility methods for enhanced functionality
  bool get isActive => status == TourSessionStatus.active;
  bool get isPaused => status == TourSessionStatus.paused;
  bool get isCompleted => status == TourSessionStatus.completed;
  bool get isWaitingForTraveler => status == TourSessionStatus.waitingForTraveler;
  bool get canStart => guideReady && travelerReady;
  bool get bothUsersOnline => guideOnline && travelerOnline;
  
  // Get progress percentage
  double get progressPercentage {
    if (visitedPlaces.isEmpty) return 0.0;
    // This would need the total number of places from the tour plan
    // For now, we'll use currentPlaceIndex as a rough estimate
    return currentPlaceIndex > 0 ? (visitedPlaces.length / currentPlaceIndex) : 0.0;
  }

  // Check if user is online based on heartbeat
  bool isUserOnline(String userId, {Duration timeout = const Duration(minutes: 5)}) {
    final heartbeat = lastHeartbeat[userId];
    if (heartbeat == null) return false;
    
    final now = DateTime.now();
    final lastSeen = heartbeat.toDate();
    return now.difference(lastSeen) < timeout;
  }

  // Get user's last seen time
  DateTime? getUserLastSeen(String userId) {
    final heartbeat = lastHeartbeat[userId];
    return heartbeat?.toDate();
  }

  // Check if session has expired
  bool get isExpired {
    if (status == TourSessionStatus.expired) return true;
    
    // Check if scheduled session is too old
    if (status == TourSessionStatus.scheduled || status == TourSessionStatus.waitingForTraveler) {
      final now = DateTime.now();
      final scheduled = scheduledStartTime.toDate();
      return now.difference(scheduled) > const Duration(hours: 24);
    }
    
    return false;
  }

  // Get session duration
  Duration? get sessionDuration {
    if (actualStartTime == null) return null;
    
    final endTime = actualEndTime?.toDate() ?? DateTime.now();
    return endTime.difference(actualStartTime!.toDate());
  }

  // Get formatted status for UI
  String get statusDisplayText {
    switch (status) {
      case TourSessionStatus.scheduled:
        return 'Scheduled';
      case TourSessionStatus.waitingForTraveler:
        return 'Waiting for Traveler';
      case TourSessionStatus.active:
        return 'Active';
      case TourSessionStatus.paused:
        return 'Paused';
      case TourSessionStatus.completed:
        return 'Completed';
      case TourSessionStatus.cancelled:
        return 'Cancelled';
      case TourSessionStatus.expired:
        return 'Expired';
    }
  }

  // Check if user can perform actions
  bool canUserPerformActions(String userId) {
    if (status == TourSessionStatus.completed || 
        status == TourSessionStatus.cancelled || 
        status == TourSessionStatus.expired) {
      return false;
    }
    
    return guideId == userId || travelerId == userId;
  }

  // Get unread notifications for user
  List<Map<String, dynamic>> getUnreadNotifications(String userId) {
    final userNotifications = <Map<String, dynamic>>[];
    
    notifications.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final notification = Map<String, dynamic>.from(value);
        final read = notification['read'] ?? false;
        final targetUser = notification['targetUser'];
        
        if (!read && (targetUser == null || targetUser == userId)) {
          notification['key'] = key;
          userNotifications.add(notification);
        }
      }
    });
    
    return userNotifications;
  }

  @override
  String toString() {
    return 'TourSession(id: $id, status: $status, guideId: $guideId, travelerId: $travelerId, currentPlace: $currentPlaceIndex, visited: ${visitedPlaces.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TourSession &&
        other.id == id &&
        other.status == status &&
        other.currentPlaceIndex == currentPlaceIndex &&
        other.visitedPlaces.length == visitedPlaces.length;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        status.hashCode ^
        currentPlaceIndex.hashCode ^
        visitedPlaces.length.hashCode;
  }
}