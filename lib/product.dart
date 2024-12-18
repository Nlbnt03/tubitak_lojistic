class Product {
  String id;
  String name;
  String barcode;
  int stockQuantity;
  String location;
  DateTime purchaseDate;
  double purchasePrice;
  double salePrice;
  String note;

  // Görünürlük kontrolü
  bool isNameVisible;
  bool isBarcodeVisible;
  bool isStockQuantityVisible;
  bool isLocationVisible;
  bool isPurchaseDateVisible;
  bool isPurchasePriceVisible;
  bool isSalePriceVisible;
  bool isNoteVisible;

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
    required this.isNameVisible,
    required this.isBarcodeVisible,
    required this.isStockQuantityVisible,
    required this.isLocationVisible,
    required this.isPurchaseDateVisible,
    required this.isPurchasePriceVisible,
    required this.isSalePriceVisible,
    required this.isNoteVisible,
  });

  // JSON formatına dönüştürme (Firebase için)
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
      'isNameVisible': isNameVisible,
      'isBarcodeVisible': isBarcodeVisible,
      'isStockQuantityVisible': isStockQuantityVisible,
      'isLocationVisible': isLocationVisible,
      'isPurchaseDateVisible': isPurchaseDateVisible,
      'isPurchasePriceVisible': isPurchasePriceVisible,
      'isSalePriceVisible': isSalePriceVisible,
      'isNoteVisible': isNoteVisible,
    };
  }

  // JSON formatından nesneye dönüştürme (Firebase'den veri okuma için)
  factory Product.fromJson(String id, Map<String, dynamic> json) {
    return Product(
      id: id,
      name: json['name'] ?? '',
      barcode: json['barcode'] ?? '',
      stockQuantity: json['stockQuantity'] ?? 0,
      location: json['location'] ?? '',
      purchaseDate: (json['purchaseDate'] != null)
          ? DateTime.parse(json['purchaseDate'])
          : DateTime.now(),
      purchasePrice: json['purchasePrice'] ?? 0.0,
      salePrice: json['salePrice'] ?? 0.0,
      note: json['note'] ?? '',
      isNameVisible: json['isNameVisible'] ?? true,
      isBarcodeVisible: json['isBarcodeVisible'] ?? true,
      isStockQuantityVisible: json['isStockQuantityVisible'] ?? true,
      isLocationVisible: json['isLocationVisible'] ?? true,
      isPurchaseDateVisible: json['isPurchaseDateVisible'] ?? true,
      isPurchasePriceVisible: json['isPurchasePriceVisible'] ?? true,
      isSalePriceVisible: json['isSalePriceVisible'] ?? true,
      isNoteVisible: json['isNoteVisible'] ?? true,
    );
  }
}
