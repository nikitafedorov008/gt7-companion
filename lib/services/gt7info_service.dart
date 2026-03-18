import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/gt7info/gt7info_data.dart';

class GT7InfoService extends ChangeNotifier {
  static const String _apiUrl = 'https://ddm999.github.io/gt7info/data.json';
  
  GT7InfoData? _data;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;

  GT7InfoData? get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;

  Future<void> fetchGT7InfoData({bool forceRefresh = false}) async {
    if (_isLoading) return;

    // Skip if data already loaded and not force refreshing
    if (!forceRefresh && _data != null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_apiUrl));
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        _data = GT7InfoData.fromJson(jsonData);
        _lastUpdated = DateTime.now();
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to load GT7Info data: HTTP ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error loading GT7Info data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Format date as YY-MM-DD
  String formatDate(DateTime date) {
    final year = date.year.toString().substring(2);
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}