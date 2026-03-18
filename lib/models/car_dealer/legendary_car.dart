class LegendaryCar {
  final int id;
  final int? sort;
  final String? state;
  final int? price;
  final String? image;
  final String? frontImage;
  final String? manufacturerName;
  final String? name;
  final String? shortName;
  final String? slug;
  final String? updatedAt;

  LegendaryCar({
    required this.id,
    this.sort,
    this.state,
    this.price,
    this.image,
    this.frontImage,
    this.manufacturerName,
    this.name,
    this.shortName,
    this.slug,
    this.updatedAt,
  });

  factory LegendaryCar.fromJson(Map<String, dynamic> json) {
    final manufacturer = json['manufacturer'] as Map<String, dynamic>?;

    return LegendaryCar(
      id: json['id'] ?? 0,
      sort: json['sort'],
      state: json['state'],
      price: json['price'],
      image: json['image'],
      frontImage: json['frontImage'],
      manufacturerName: manufacturer?['name'],
      name: json['name'],
      shortName: json['short_name'],
      slug: json['slug'],
      updatedAt: json['updated_at'],
    );
  }

  String get statusText {
    switch (state) {
      case 'soldout':
        return 'SOLD OUT';
      case 'limited':
        return 'LIMITED';
      case 'new':
        return 'NEW';
      default:
        return 'AVAILABLE';
    }
  }

  String get displayPrice {
    if (price == null) return '0';
    return 'Cr. ${_formatCredits(price!)}';
  }

  String _formatCredits(int credits) {
    if (credits == 0) return '0';
    return credits.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},'
    );
  }
}