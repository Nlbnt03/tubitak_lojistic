import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lojistik/listed_product_customer.dart';
import 'package:lojistik/siparis_islemleri_customer.dart';
import 'package:lojistik/siparis_olustur_customer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerProductDetail extends StatefulWidget {
  final String productId;

  const CustomerProductDetail({Key? key, required this.productId}) : super(key: key);

  @override
  State<CustomerProductDetail> createState() => _CustomerProductDetailState();
}

class _CustomerProductDetailState extends State<CustomerProductDetail> {
  late Future<DocumentSnapshot> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = FirebaseFirestore.instance
        .collection('product')
        .doc(widget.productId)
        .get();
  }

  Future<void> _checkStockAndProcess(String userId, String processId, int requestedQuantity) async {
    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('product')
          .doc(widget.productId)
          .get();

      if (productDoc.exists) {
        final stock = productDoc.data()?['stockQuantity'] ?? 0;

        if (requestedQuantity <= stock) {
          print("Stok yeterli: Talep edilen miktar: $requestedQuantity, Mevcut stok: $stock");

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Talep edilen miktar stoktan düşüldü."),
              backgroundColor: Colors.green,
            ),
          );

          await FirebaseFirestore.instance.collection('product').doc(widget.productId).update({
            'stockQuantity': FieldValue.increment(-requestedQuantity),
          });

          await _addOrUpdateProductInProcess(userId, processId, widget.productId, requestedQuantity);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SiparisOlusturCustomer(id: processId)),
          );
        } else {
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

  Future<void> _addOrUpdateProductInProcess(String userId, String processId, String productId, int requestedQuantity) async {
    try {
      final processRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selfProcess')
          .doc(processId);

      final processDoc = await processRef.get();

      if (processDoc.exists) {
        List<dynamic> products = processDoc.data()?['products'] ?? [];

        final existingProductIndex = products.indexWhere((product) => product['productId'] == productId);

        if (existingProductIndex != -1) {
          products[existingProductIndex]['requestedStock'] += requestedQuantity;
          await processRef.update({'products': products});
        } else {
          Map<String, dynamic> newProduct = {
            "productId": productId,
            "requestedStock": requestedQuantity,
          };

          await processRef.update({
            "products": FieldValue.arrayUnion([newProduct]),
          });
        }
      } else {
        Map<String, dynamic> newProduct = {
          "productId": productId,
          "requestedStock": requestedQuantity,
        };

        await processRef.set({
          "products": [newProduct],
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ürün Detayı"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ListedProductCustomer()),
            );
          },
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Ürün bulunamadı."));
          }

          final productData = snapshot.data!.data() as Map<String, dynamic>;

          final isBarcodeVisible = productData['isBarcodeVisible'] ?? false;
          final isLocationVisible = productData['isLocationVisible'] ?? false;
          final isNameVisible = productData['isNameVisible'] ?? false;
          final isNoteVisible = productData['isNoteVisible'] ?? false;
          final isPurchaseDateVisible = productData['isPurchaseDateVisible'] ?? false;
          final isPurchasePriceVisible = productData['isPurchasePriceVisible'] ?? false;
          final isSalePriceVisible = productData['isSalePriceVisible'] ?? false;
          final isStockQuantityVisible = productData['isStockQuantityVisible'] ?? false;

          final barcode = productData['barcode'] ?? 'Belirtilmemiş';
          final location = productData['location'] ?? 'Belirtilmemiş';
          final name = productData['name'] ?? 'Belirtilmemiş';
          final note = productData['note'] ?? 'Belirtilmemiş';
          final purchaseDate = productData['purchaseDate'] != null
              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(productData['purchaseDate']))
              : 'Belirtilmemiş';
          final purchasePrice = productData['purchasePrice']?.toString() ?? 'Belirtilmemiş';
          final salePrice = productData['salePrice']?.toString() ?? 'Belirtilmemiş';
          final stockQuantity = productData['stockQuantity']?.toString() ?? 'Belirtilmemiş';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                if (isNameVisible) _buildDetailRow('Ürün Adı:', name),
                const Divider(),
                if (isBarcodeVisible) _buildDetailRow('Barkod:', barcode),
                const Divider(),
                if (isLocationVisible) _buildDetailRow('Konum:', location),
                const Divider(),
                if (isStockQuantityVisible) _buildDetailRow('Stok Miktarı:', stockQuantity),
                const Divider(),
                if (isPurchaseDateVisible) _buildDetailRow('Satın Alma Tarihi:', purchaseDate),
                const Divider(),
                if (isPurchasePriceVisible) _buildDetailRow('Satın Alma Fiyatı:', '$purchasePrice ₺'),
                const Divider(),
                if (isSalePriceVisible) _buildDetailRow('Satış Fiyatı:', '$salePrice ₺'),
                const Divider(),
                if (isNoteVisible) _buildDetailRow('Not:', note),
                const Divider(),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff65558F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final savedId = prefs.getString('companyId');

                        if (savedId != null) {
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
                                    const SizedBox(height: 8),
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
                                      Navigator.pop(context);
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
                                        Navigator.pop(context);

                                        final userId = FirebaseAuth.instance.currentUser!.uid;

                                        await _checkStockAndProcess(
                                          userId,
                                          savedId,
                                          enteredQuantity,
                                        );
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
                            MaterialPageRoute(builder: (context) => SiparisIslemleriCustomer()),
                          );
                        }
                      },
                      child: const Text(
                        "Sepete Ekle",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
