import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lojistik/customer_Menu.dart';
import 'package:lojistik/customer_product_detail.dart';
import 'package:lojistik/product.dart'; // Mevcut Product sınıfınızı dahil edin
import 'product_detail_page.dart'; // Yeni oluşturulan sayfayı ekleyin

class ListedProductCustomer extends StatefulWidget {
  const ListedProductCustomer({super.key});

  @override
  State<ListedProductCustomer> createState() => _ListedProductCustomerState();
}

class _ListedProductCustomerState extends State<ListedProductCustomer> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('product').get();
      setState(() {
        _products = snapshot.docs
            .map((doc) => Product.fromJson(doc.id, doc.data() as Map<String, dynamic>))
            .toList();
        _filteredProducts = _products; // Başlangıçta tüm ürünler gösterilecek
      });
    } catch (e) {
      print("Firebase'den ürünleri çekerken hata oluştu: $e");
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _products
          .where((product) => product.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => CustomerMenu(),));
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
            child: _filteredProducts.isEmpty
                ? const Center(child: Text("Ürün bulunamadı"))
                : ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return ListTile(
                  leading: const Icon(Icons.inventory_2, size: 35),
                  title: Text(product.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CustomerProductDetail(productId: product.id),
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
