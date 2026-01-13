class GraphqlQueries {
  // Запрос для получения всех автомобилей из usedCarDealer
  static const String getAllUsedCars = '''
    query AllUsedCars {
      gt_car(where: {details: {_has_key: "in_ucd"}}, order_by: {updated_at: desc}) {
        id
        details
        manufacturer {
          name
          __typename
        }
        name
        short_name
        slug
        updated_at
        __typename
      }
    }
  ''';

  // Запрос для получения всех автомобилей из legendaryCarDealer
  static const String getAllLegendaryCars = '''
    query AllLegendaryCars {
      gt_car(where: {details: {_has_key: "in_legend"}}, order_by: {updated_at: desc}) {
        id
        sort
        state
        price
        image
        frontImage
        manufacturer {
          name
        }
        name
        short_name
        slug
        updated_at
      }
    }
  ''';
}