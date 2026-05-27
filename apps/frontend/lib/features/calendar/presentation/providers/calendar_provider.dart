import 'package:flutter/foundation.dart';
import 'package:frontend/features/auth/data/datasources/api_service.dart';

class CalendarProvider with ChangeNotifier {
  final ApiService _apiService;
  List<CalendarEvent> _events = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  CalendarProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  List<CalendarEvent> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  Future<void> loadEvents(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _apiService.getEvents(token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  List<CalendarEvent> getEventsForDate(DateTime date) {
    return _events.where((event) {
      return event.start.year == date.year &&
          event.start.month == date.month &&
          event.start.day == date.day;
    }).toList();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void addEvent(CalendarEvent event) {
    _events.add(event);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

