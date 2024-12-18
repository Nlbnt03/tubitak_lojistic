import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lojistik/siparis_islemleri.dart';
import 'package:lojistik/siparis_olustur_staff.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({Key? key, required this.productId})
      : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  // Ürün detaylarını saklayan değişkenler
  String? productName;
  String? barcode;
  int? stockQuantity;
  String? location;
  double? purchasePrice;
  double? salePrice;
  String? note;

  // Görünürlük değişkenleri
  bool isNameVisible = true;
  bool isBarcodeVisible = true;
  bool isStockQuantityVisible = true;
  bool isLocationVisible = true;
  bool isPurchasePriceVisible = true;
  bool isSalePriceVisible = true;
  bool isNoteVisible = true;

  bool isLoading = true;

  // TextEditingController'lar
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController stockQuantityController =
  TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController purchasePriceController =
  TextEditingController();
  final TextEditingController salePriceController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    try {
      DocumentSnapshot productSnapshot = await FirebaseFirestore.instance
          .collection('product')
          .doc(widget.productId)
          .get();

      if (productSnapshot.exists) {
        Map<String, dynamic> productData =
        productSnapshot.data() as Map<String, dynamic>;

        setState(() {
          // Ürün bilgilerini atama
          productName = productData['name'] ?? 'Bilgi yok';
          barcode = productData['barcode'] ?? 'Bilgi yok';
          stockQuantity = productData['stockQuantity'] ?? 0;
          location = productData['location'] ?? 'Bilgi yok';
          purchasePrice = productData['purchasePrice']?.toDouble() ?? 0.0;
          salePrice = productData['salePrice']?.toDouble() ?? 0.0;
          note = productData['note'] ?? 'Bilgi yok';

          // Görünürlük ayarlarını Firestore'dan çekip atama
          isNameVisible = productData['isNameVisible'] ?? true;
          isBarcodeVisible = productData['isBarcodeVisible'] ?? true;
          isStockQuantityVisible = productData['isStockQuantityVisible'] ?? true;
          isLocationVisible = productData['isLocationVisible'] ?? true;
          isPurchasePriceVisible = productData['isPurchasePriceVisible'] ?? true;
          isSalePriceVisible = productData['isSalePriceVisible'] ?? true;
          isNoteVisible = productData['isNoteVisible'] ?? true;

          isLoading = false; // Yükleme tamamlandı
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün bulunamadı!')),
        );
        Navigator.pop(context); // Geri dön
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }


  // Görünürlük ayarlarını güncelleme fonksiyonu
  Future<void> _updateVisibility(String key, bool value) async {
    try {
      await FirebaseFirestore.instance
          .collection('product')
          .doc(widget.productId)
          .update({key: value});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$key görünürlüğü güncellendi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _checkStockAndProcess(String companyId, int requestedQuantity) async {
    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('product') // Ürünlerin tutulduğu koleksiyon
          .doc(widget.productId)
          .get();

      if (productDoc.exists) {
        final stock = productDoc.data()?['stockQuantity'] ?? 0; // Firestore'daki stok miktarı

        if (requestedQuantity <= stock) {
          // Stok yeterli
          print("Stok yeterli: Talep edilen miktar: $requestedQuantity, Mevcut stok: $stock");

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Talep edilen miktar stoktan düşüldü."),
              backgroundColor: Colors.green,
            ),
          );

          // Stoktan düş
          await FirebaseFirestore.instance.collection('product').doc(widget.productId).update({
            'stockQuantity': FieldValue.increment(-requestedQuantity),
          });

          // Process koleksiyonuna ürün ekle veya güncelle
          await _addOrUpdateProductInProcess(companyId, widget.productId, requestedQuantity);

          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SiparisOlustur(id: companyId),));
        } else {
          // Stok yetersiz
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Yetersiz stok! Mevcut stok: $stock"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ürün bulunamadı."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addOrUpdateProductInProcess(String companyId, String productId, int requestedQuantity) async {
    try {
      // Firestore'daki `process` koleksiyonuna erişim
      final processRef = FirebaseFirestore.instance.collection('process').doc(companyId);
      final processDoc = await processRef.get();

      if (processDoc.exists) {
        List<dynamic> products = processDoc.data()?['products'] ?? [];

        // Aynı ürün ID'sine sahip ürün var mı kontrol et
        final existingProductIndex = products.indexWhere((product) => product['productId'] == productId);

        if (existingProductIndex != -1) {
          // Ürün mevcutsa, miktarı güncelle
          products[existingProductIndex]['requestedStock'] += requestedQuantity;

          // Güncellenmiş listeyi tekrar kaydet
          await processRef.update({
            'products': products,
          });

          print("Ürün sepette mevcut, miktar güncellendi.");
        } else {
          // Ürün yoksa yeni ürün ekle
          Map<String, dynamic> newProduct = {
            "productId": productId,
            "requestedStock": requestedQuantity,
          };

          await processRef.update({
            "products": FieldValue.arrayUnion([newProduct]),
          });

          print("Yeni ürün sepete eklendi.");
        }
      } else {
        // Eğer `process` belgesi yoksa yeni belge oluştur ve ürünü ekle
        Map<String, dynamic> newProduct = {
          "productId": productId,
          "requestedStock": requestedQuantity,
        };

        await processRef.set({
          "products": [newProduct],
        });

        print("Yeni ürün sepete eklendi ve process belgesi oluşturuldu.");
      }
    } catch (e) {
      print("Process koleksiyonuna ekleme veya güncelleme sırasında hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addProductToProcess(String companyId, String productId, int requestedQuantity) async {
    try {
      // Firestore'daki `process` koleksiyonuna erişim
      final processRef = FirebaseFirestore.instance.collection('process').doc(companyId);

      // Eklemek istediğiniz ürün
      Map<String, dynamic> newProduct = {
        "productId": productId,
        "requestedStock": requestedQuantity,
      };

      // Process tablosunda ürün sepetine yeni ürün ekle
      await processRef.update({
        "products": FieldValue.arrayUnion([newProduct]),
      });

      print("Ürün başarıyla process koleksiyonuna eklendi.");
    } catch (e) {
      print("Process koleksiyonuna ekleme sırasında hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Edit popup'u gösterme fonksiyonu
  void _showEditPopup(
      {required TextEditingController controller,
        required String label,
        required Function(String) onSaved}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label düzenle'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              onSaved(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(TextEditingController controller, String label,
      Function(String) onSaved) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'düzenle') {
          _showEditPopup(controller: controller, label: label, onSaved: onSaved);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'düzenle', child: Text('Düzenle')),
      ],
    );
  }

  // Görünürlük ayarını değiştiren dialog
  void _showVisibilityDialog(
      BuildContext context,
      String title,
      String message,
      bool currentValue,
      Function(bool) onChanged,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            RadioListTile<bool>(
              title: const Text('Görünür'),
              value: true,
              groupValue: currentValue,
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<bool>(
              title: const Text('Görünmez'),
              value: false,
              groupValue: currentValue,
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Verilerin güncellenmesi ve Firebase'e kaydedilmesi
  void _updateProductData() async {
    try {
      await FirebaseFirestore.instance.collection('product').doc(widget.productId).update({
        'name': productName,
        'barcode': barcode,
        'stockQuantity': stockQuantity,
        'location': location,
        'purchasePrice': purchasePrice,
        'salePrice': salePrice,
        'note': note,
        'isNameVisible': isNameVisible,
        'isBarcodeVisible': isBarcodeVisible,
        'isStockQuantityVisible': isStockQuantityVisible,
        'isLocationVisible': isLocationVisible,
        'isPurchasePriceVisible': isPurchasePriceVisible,
        'isSalePriceVisible': isSalePriceVisible,
        'isNoteVisible': isNoteVisible,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün bilgileri başarıyla güncellendi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Detayı'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Ürün Adı',
              productName ?? '',
              isNameVisible,
                  (value) {
                setState(() => isNameVisible = value);
                _updateVisibility('isNameVisible', value);
              },
            ),
            const Divider(),
            _buildDetailRow(
              'Barkod',
              barcode ?? '',
              isBarcodeVisible,
                  (value) {
                setState(() => isBarcodeVisible = value);
                _updateVisibility('isBarcodeVisible', value);
              },
            ),
            const Divider(),
            _buildDetailRow(
              'Stok Miktarı',
              stockQuantity.toString(),
              isStockQuantityVisible,
                  (value) {
                setState(() => isStockQuantityVisible = value);
                _updateVisibility('isStockQuantityVisible', value);
              },
            ),
            const Divider(),
            _buildDetailRow(
              'Depo Konumu',
              location ?? '',
              isLocationVisible,
                  (value) {
                setState(() => isLocationVisible = value);
                _updateVisibility('isLocationVisible', value);
              },
            ),
            const Divider(),
            _buildDetailRow(
              'Alış Fiyatı',
              purchasePrice.toString(),
              isPurchasePriceVisible,
                  (value) {
                setState(() => isPurchasePriceVisible = value);
                _updateVisibility('isPurchasePriceVisible', value);
              },
            ),
            const Divider(),
            _buildDetailRow(
              'Satış Fiyatı',
              salePrice.toString(),
              isSalePriceVisible,
                  (value) {
                setState(() => isSalePriceVisible = value);
                _updateVisibility('isSalePriceVisible', value);
              },
            ),
            const Divider(),
            _buildDetailRow(
              'Not',
              note ?? '',
              isNoteVisible,
                  (value) {
                setState(() => isNoteVisible = value);
                _updateVisibility('isNoteVisible', value);
              },
            ),
            const Divider(),
            SizedBox(height: 20,),
            Center(
              child: SizedBox(
                width: 343,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff65558F),
                  ),
                  onPressed: _updateProductData,
                  child: const Text('Verileri Güncelle',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
                ),
              ),
            ),
            SizedBox(height: 20,),
            Center(
              child: SizedBox(
                width: 343,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff65558F),
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final savedId = prefs.getString('companyId'); // Kaydedilmiş ID'yi al

                    if (savedId != null) {
                      print('Company ID: $savedId');

                      // AlertDialog ile miktar sor
                      TextEditingController quantityController = TextEditingController();

                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Miktar Girin"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Talep edilen stok miktarını girin:"),
                                SizedBox(height: 2,),
                                TextField(
                                  controller: quantityController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: "Miktar"),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Dialog'u kapat
                                },
                                child: const Text("İptal"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final enteredQuantity = int.tryParse(quantityController.text);

                                  if (enteredQuantity == null || enteredQuantity <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Geçerli bir miktar giriniz."),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } else {
                                    // Firestore'daki stok miktarını kontrol et
                                    Navigator.pop(context); // Dialog'u kapat
                                    await _checkStockAndProcess(savedId, enteredQuantity);
                                  }
                                },
                                child: const Text("Tamam"),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Seçili Şirket bulunamadı.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SiparisIslemleri()),
                      );
                    }
                  },
                  child: const Text(
                    'Sepete Ekle',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      String title,
      String value,
      bool isVisible,
      Function(bool) onVisibilityChanged,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 5.0,),
            IconButton(
              icon: Icon(
                Icons.remove_red_eye,
                color: isVisible ? Colors.green : Colors.red,
              ),
              onPressed: () {
                _showVisibilityDialog(
                  context,
                  '$title Görünürlüğü',
                  '$title görünürlüğünü değiştirmek ister misiniz?',
                  isVisible,
                  onVisibilityChanged,
                );
              },
            ),
          ],
        ),
        Row(
          children: [
            Text(value),
            _buildPopupMenu(
              isVisible ? TextEditingController(text: value) : TextEditingController(),
              title,
                  (newValue) {
                setState(() {
                  if (title == 'Ürün Adı') {
                    productName = newValue;
                  } else if (title == 'Barkod') {
                    barcode = newValue;
                  } else if (title == 'Stok Miktarı') {
                    stockQuantity = int.tryParse(newValue);
                  } else if (title == 'Depo Konumu') {
                    location = newValue;
                  } else if (title == 'Alış Fiyatı') {
                    purchasePrice = double.tryParse(newValue);
                  } else if (title == 'Satış Fiyatı') {
                    salePrice = double.tryParse(newValue);
                  } else if (title == 'Not') {
                    note = newValue;
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
