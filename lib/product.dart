class Product {
  String id; // Firebase döküman ID'si
  String name;
  String barcode;
  int stockQuantity;
  String location;
  DateTime purchaseDate;
  double purchasePrice;
  double salePrice;
  String note;

  Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.stockQuantity,
    required this.location,
    required this.purchaseDate,
    required this.purchasePrice,
    required this.salePrice,
    required this.note,
  });

  // Firebase'e eklemek için JSON dönüşümü
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'barcode': barcode,
      'stockQuantity': stockQuantity,
      'location': location,
      'purchaseDate': purchaseDate.toIso8601String(),
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'note': note,
    };
  }

  // Firebase'den gelen veriyi nesneye dönüştürmek için
  factory Product.fromJson(String id, Map<String, dynamic> json) {
    return Product(
      id: id,
      name: json['name'] ?? '',
      barcode: json['barcode'] ?? '',
      stockQuantity: json['stockQuantity'] ?? 0,
      location: json['location'] ?? '',
      purchaseDate: DateTime.parse(json['purchaseDate'] ?? DateTime.now().toIso8601String()),
      purchasePrice: (json['purchasePrice'] ?? 0).toDouble(),
      salePrice: (json['salePrice'] ?? 0).toDouble(),
      note: json['note'] ?? '',
    );
  }
}
