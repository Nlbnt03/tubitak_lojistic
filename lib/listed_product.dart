import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lojistik/product.dart'; // Mevcut Product sınıfınızı dahil edin
import 'product_detail_page.dart'; // Yeni oluşturulan sayfayı ekleyin

class ListedProduct extends StatefulWidget {
  const ListedProduct({super.key});

  @override
  State<ListedProduct> createState() => _ListedProductState();
}

class _ListedProductState extends State<ListedProduct> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _showDeleteConfirmationDialog(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ürünü Sil"),
          content: const Text("Bu ürünü silmek istediğinize emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
              },
              child: const Text("İptal"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Dialog'u kapat
                await _deleteProduct(productId, context);
              },
              child: const Text(
                "Onayla",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(String productId, BuildContext context) async {
    try {
      // Firestore'dan ürünü sil
      await FirebaseFirestore.instance.collection('product').doc(productId).delete();

      // Başarı mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ürün başarıyla silindi."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Hata mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ürün silinirken hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Ürünler"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Ürün ara",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => _filterProducts(value),
            ),
          ),
          // Ürün Listesi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('product').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Hata oluştu, lütfen tekrar deneyin."));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Ürün bulunamadı"));
                }

                final products = snapshot.data!.docs
                    .map((doc) => Product.fromJson(doc.id, doc.data() as Map<String, dynamic>))
                    .where((product) => product.name.toLowerCase().contains(_searchQuery))
                    .toList();

                if (products.isEmpty) {
                  return const Center(child: Text("Aradığınız kriterlere uygun ürün bulunamadı."));
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(productId: product.id),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            // Ürün simgesi
                            const Icon(Icons.inventory, size: 35),
                            const SizedBox(width: 16), // Boşluk
                            // Ürün adı ve detaylar
                            Expanded(
                              child: Text(
                                product.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _showDeleteConfirmationDialog(context, product.id);
                              },
                              child: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),

                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
