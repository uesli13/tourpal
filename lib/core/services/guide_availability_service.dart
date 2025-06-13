import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/available_time.dart';
import '../utils/logger.dart';

class GuideAvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get available time slots for a specific date
  Future<List<DateTime>> getAvailableTimeSlotsForDate(
    String guideId,
    DateTime date,
  ) async {
    try {
      // Get guide's weekly availability
      final guideDoc = await _firestore.collection('guides').doc(guideId).get();
      
      if (!guideDoc.exists) {
        return [];
      }
      
      final guideData = guideDoc.data()!;
      final availability = (guideData['availability'] as List<dynamic>?)
          ?.map((e) => AvailableTime.fromMap(e as Map<String, dynamic>))
          .toList() ?? [];
      
      // Find availability for this day of week (0=Sunday, 1=Monday, etc.)
      final dayOfWeek = date.weekday % 7; // Convert to 0-based where Sunday=0
      final dayAvailability = availability.where((a) => a.dayOfWeek == dayOfWeek);
      
      if (dayAvailability.isEmpty) {
        return [];
      }
      
      // Generate 30-minute time slots
      final List<DateTime> timeSlots = [];
      
      for (final availableTime in dayAvailability) {
        final startParts = availableTime.startTime.split(':');
        final endParts = availableTime.endTime.split(':');
        
        final startHour = int.parse(startParts[0]);
        final startMinute = int.parse(startParts[1]);
        final endHour = int.parse(endParts[0]);
        final endMinute = int.parse(endParts[1]);
        
        DateTime currentSlot = DateTime(
          date.year,
          date.month,
          date.day,
          startHour,
          startMinute,
        );
        
        final endTime = DateTime(
          date.year,
          date.month,
          date.day,
          endHour,
          endMinute,
        );
        
        // Generate 30-minute slots
        while (currentSlot.isBefore(endTime)) {
          timeSlots.add(currentSlot);
          currentSlot = currentSlot.add(const Duration(minutes: 30));
        }
      }
      
      // Filter out already booked slots
      final bookedSlots = await _getBookedSlotsForDate(guideId, date);
      final availableSlots = timeSlots.where((slot) {
        return !bookedSlots.any((booked) => 
          booked.year == slot.year &&
          booked.month == slot.month &&
          booked.day == slot.day &&
          booked.hour == slot.hour &&
          booked.minute == slot.minute);
      }).toList();
      
      // Sort by time
      availableSlots.sort();
      
      return availableSlots;
    } catch (e) {
      AppLogger.logInfo('Error getting available time slots: $e');
      return [];
    }
  }

  /// Get booked time slots for a specific date
  Future<List<DateTime>> _getBookedSlotsForDate(String guideId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();
      
      // Filter by guide ID (we need to get the tour guide ID from tour plans)
      final bookedSlots = <DateTime>[];
      
      for (final doc in bookingsQuery.docs) {
        final data = doc.data();
        final tourInstanceId = data['tourInstanceId'] as String;
        
        // Get the tour plan to check if it belongs to this guide
        final tourDoc = await _firestore.collection('tourPlans').doc(tourInstanceId).get();
        if (tourDoc.exists && tourDoc.data()!['guideId'] == guideId) {
          final startTime = (data['startTime'] as Timestamp).toDate();
          bookedSlots.add(startTime);
        }
      }
      
      return bookedSlots;
    } catch (e) {
      AppLogger.logInfo('Error getting booked slots: $e');
      return [];
    }
  }

  /// Check if a guide is available on a specific date and time
  Future<bool> isGuideAvailable(String guideId, DateTime dateTime) async {
    final availableSlots = await getAvailableTimeSlotsForDate(guideId, dateTime);
    return availableSlots.any((slot) => 
      slot.year == dateTime.year &&
      slot.month == dateTime.month &&
      slot.day == dateTime.day &&
      slot.hour == dateTime.hour &&
      slot.minute == dateTime.minute);
  }

  /// Get guide's weekly schedule
  Future<List<AvailableTime>> getGuideWeeklySchedule(String guideId) async {
    try {
      final guideDoc = await _firestore.collection('guides').doc(guideId).get();
      
      if (!guideDoc.exists) {
        return [];
      }
      
      final guideData = guideDoc.data()!;
      final availability = (guideData['availability'] as List<dynamic>?)
          ?.map((e) => AvailableTime.fromMap(e as Map<String, dynamic>))
          .toList() ?? [];
      
      return availability;
    } catch (e) {
      AppLogger.logInfo('Error getting guide weekly schedule: $e');
      return [];
    }
  }
}