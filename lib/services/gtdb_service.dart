import 'package:flutter/foundation.dart';
import 'package:graphql/client.dart';
import '../models/used_car.dart';
import '../models/legendary_car.dart';
import 'graphql_queries.dart';

class GTDBService extends ChangeNotifier {
  late GraphQLClient _client;

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
    // Настройка клиента GraphQL
    final HttpLink httpLink = HttpLink(
      'https://api.playstationdb.com/graphql',
    );

    _client = GraphQLClient(
      cache: GraphQLCache(),
      link: httpLink,
    );
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

      if (legendaryCarsResult.hasException) {
        _errorMessage = _errorMessage != null
            ? '$_errorMessage and Error loading legendary cars: ${legendaryCarsResult.exception}'
            : 'Error loading legendary cars: ${legendaryCarsResult.exception}';
        debugPrint('GraphQL Error (Legendary Cars): ${legendaryCarsResult.exception}');
      } else {
        final legendaryCarList = legendaryCarsResult.data?['gt_car'] as List?;
        if (legendaryCarList != null) {
          _legendaryCars = legendaryCarList.map((car) => LegendaryCar.fromJson(car)).toList();
        }
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
    final options = QueryOptions(
      document: gql(GraphqlQueries.getAllUsedCars),
      variables: {},
    );

    final result = await _client.query(options);
    return result;
  }

  // Fetch legendary cars data
  Future<QueryResult> _fetchLegendaryCars() async {
    final options = QueryOptions(
      document: gql(GraphqlQueries.getAllLegendaryCars),
      variables: {},
    );

    final result = await _client.query(options);
    return result;
  }
}