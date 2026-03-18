import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/car_dealer/legendary_car.dart';
import '../models/car_dealer/used_car.dart';

class GTDBService extends ChangeNotifier {
  late GraphQLClient _usedCarsClient;

  List<UsedCar> _usedCars = [];
  List<LegendaryCar> _legendaryCars = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;

  List<UsedCar> get usedCars => _usedCars;
  List<LegendaryCar> get legendaryCars => _legendaryCars;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;

  GTDBService() {
    // Настройка клиента GraphQL для used cars
    final HttpLink usedCarsHttpLink = HttpLink(
      'https://api.playstationdb.com/graphql',
    );

    _usedCarsClient = GraphQLClient(
      cache: GraphQLCache(),
      link: usedCarsHttpLink,
    );

    // Для legendary cars используем другой клиент, так как API требует GET-запросы
    // Мы будем использовать http-клиент напрямую для этого случая
  }

  Future<void> fetchGTDBData({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch both used and legendary cars data
      final usedCarsResult = await _fetchUsedCars();
      final legendaryCarsResult = await _fetchLegendaryCars();

      // Обработка результатов
      if (usedCarsResult.hasException) {
        _errorMessage = 'Error loading used cars: ${usedCarsResult.exception}';
        debugPrint('GraphQL Error (Used Cars): ${usedCarsResult.exception}');
      } else {
        final usedCarList = usedCarsResult.data?['gt_car'] as List?;
        if (usedCarList != null) {
          _usedCars = usedCarList.map((car) => UsedCar.fromJson(car)).toList();
        }
      }

      // Обработка результатов для легендарных автомобилей
      final legendaryCarList = legendaryCarsResult['data']?['gt_car'] as List?;
      if (legendaryCarList != null) {
        _legendaryCars = legendaryCarList.map((car) => LegendaryCar.fromJson(car)).toList();
      }

      _lastUpdated = DateTime.now();
    } catch (e) {
      _errorMessage = 'Error loading GTDB data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch used cars data
  Future<QueryResult> _fetchUsedCars() async {
    final String usedCarsQuery = await rootBundle.loadString('schemas/used_cars.graphql');

    final options = QueryOptions(
      document: gql(usedCarsQuery),
      variables: {},
    );

    final result = await _usedCarsClient.query(options);
    return result;
  }

  // Fetch legendary cars data using HTTP client (GET request)
  Future<Map<String, dynamic>> _fetchLegendaryCars() async {
    final response = await http.get(
      Uri.parse('https://gtdb.io/api/graphql_middleware/query/LegendCarsDealer'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      final Map<String, dynamic> data = json.decode(response.body);
      // Create a mock QueryResult-like response
      return {'data': data['data']};
    } else {
      throw Exception('Failed to load legendary cars: ${response.statusCode}');
    }
  }
}