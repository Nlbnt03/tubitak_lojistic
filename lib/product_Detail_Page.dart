import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Firestore'dan ürün detaylarını getirme fonksiyonu
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
          productName = productData['name'] ?? 'Bilgi yok';
          barcode = productData['barcode'] ?? 'Bilgi yok';
          stockQuantity = productData['stockQuantity'] ?? 0;
          location = productData['location'] ?? 'Bilgi yok';
          purchasePrice = productData['purchasePrice']?.toDouble() ?? 0.0;
          salePrice = productData['salePrice']?.toDouble() ?? 0.0;
          note = productData['note'] ?? 'Bilgi yok';

          isLoading = false;
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

  // Firestore'da ürün detaylarını güncelleme fonksiyonu
  Future<void> _updateProductDetails() async {
    try {
      await FirebaseFirestore.instance
          .collection('product')
          .doc(widget.productId)
          .update({
        'name': productNameController.text.isNotEmpty
            ? productNameController.text
            : productName,
        'barcode': barcodeController.text.isNotEmpty
            ? barcodeController.text
            : barcode,
        'stockQuantity': stockQuantityController.text.isNotEmpty
            ? int.tryParse(stockQuantityController.text) ?? stockQuantity
            : stockQuantity,
        'location': locationController.text.isNotEmpty
            ? locationController.text
            : location,
        'purchasePrice': purchasePriceController.text.isNotEmpty
            ? double.tryParse(purchasePriceController.text) ?? purchasePrice
            : purchasePrice,
        'salePrice': salePriceController.text.isNotEmpty
            ? double.tryParse(salePriceController.text) ?? salePrice
            : salePrice,
        'note': noteController.text.isNotEmpty ? noteController.text : note,
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
              productNameController,
                  (value) => setState(() => productName = value),
            ),
            Divider(),
            _buildDetailRow(
              'Barkod',
              barcode ?? '',
              barcodeController,
                  (value) => setState(() => barcode = value),
            ),
            Divider(),
            _buildDetailRow(
              'Stok Miktarı',
              stockQuantity.toString(),
              stockQuantityController,
                  (value) => setState(() =>
              stockQuantity = int.tryParse(value) ?? stockQuantity),
            ),
            Divider(),
            _buildDetailRow(
              'Depo Konumu',
              location ?? '',
              locationController,
                  (value) => setState(() => location = value),
            ),
            Divider(),
            _buildDetailRow(
              'Alış Fiyatı',
              purchasePrice.toString() ?? '',
              purchasePriceController,
                  (value) => setState(() => purchasePrice = double.parse(value)),
            ),
            Divider(),
            _buildDetailRow(
              'Satış Fiyatı',
              salePrice.toString() ?? '',
              salePriceController,
                  (value) => setState(() => salePrice = double.parse(value)),
            ),
            Divider(),
            _buildDetailRow(
              'Not',
              note ?? '',
              noteController,
                  (value) => setState(() => note = value),
            ),
            Divider(),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 343,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff65558F)
                  ),
                  onPressed: _updateProductDetails,
                  child: const Text('Ürün Bilgilerini Güncelle',style: TextStyle(color: Colors.white),),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value,
      TextEditingController controller, Function(String) onSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text(value),
              _buildPopupMenu(controller, title, onSaved),
            ],
          ),
        ],
      ),
    );
  }
}
