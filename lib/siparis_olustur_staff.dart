import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lojistik/listed_product.dart';
import 'package:lojistik/product.dart';
import 'package:lojistik/search_with_barcode.dart';
import 'package:lojistik/siparis_islemleri.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SiparisOlustur extends StatefulWidget {
  final String id;

  const SiparisOlustur({super.key, required this.id});

  @override
  State<SiparisOlustur> createState() => _SiparisOlusturState();
}

class _SiparisOlusturState extends State<SiparisOlustur> {
  late Future<Map<String, dynamic>> _companyDetailsFuture;
  List<Product> _sepetUrunler = [];

  @override
  void initState()
  {
    super.initState();
    _companyDetailsFuture = _getCompanyDetails();
    _fetchSepetUrunler();
  }

  Future<void> saveProductId(String productId) async
  {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('companyId', productId);
    print("Ürün ID kaydedildi: $productId");
  }


  Future<Map<String, dynamic>> _getCompanyDetails() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('process')
        .doc(widget.id)
        .get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    } else {
      throw Exception("Veri bulunamadı");
    }
  }

  Future<void> _fetchSepetUrunler() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('process')
        .doc(widget.id)
        .get();

    if (snapshot.exists) {
      List<dynamic> sepetIds = snapshot['sepet'] ?? [];
      List<Product> sepetUrunler = [];

      for (String id in sepetIds) {
        DocumentSnapshot productDoc = await FirebaseFirestore.instance
            .collection('product')
            .doc(id)
            .get();
        if (productDoc.exists) {
          sepetUrunler.add(Product.fromJson(
              productDoc.id, productDoc.data() as Map<String, dynamic>));
        }
      }
      setState(() {
        _sepetUrunler = sepetUrunler;
      });
    }
  }

  // Ürün ekleme seçeneklerini gösteren AlertDialog
  void _showAddProductOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ürün Ekle"),
          content: SingleChildScrollView( // İçeriği kaydırılabilir yapar
            child: SizedBox(
              height: 150, // AlertDialog içeriği için maksimum yükseklik
              child: Column(
                mainAxisSize: MainAxisSize.min, // Column'un minimum boyutta kalmasını sağlar
                children: [
                  SizedBox(
                    width: 343,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff65558F),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ListedProduct(),));
                        print("İsim ile Ekle seçildi.");
                      },
                      child: const Text("İsim ile Ekle",style: TextStyle(color: Colors.white),),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 343,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff65558F),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SearchWithBarcode(),));
                        print("Barkod ile Ekle seçildi.");
                      },
                      child: const Text("Barkod ile Ekle",style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("İptal"),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchProductsWithDetails(String companyId) async {
    try {
      // Firestore'dan `process` belgesini al
      final processDoc = await FirebaseFirestore.instance.collection('process').doc(companyId).get();

      if (processDoc.exists) {
        List<dynamic> products = processDoc.data()?['products'] ?? [];

        // Her bir ürünün detaylarını `product` koleksiyonundan çek
        List<Map<String, dynamic>> productDetails = [];
        for (var product in products) {
          String productId = product['productId'];
          int requestedStock = product['requestedStock'];

          // Ürün bilgilerini `product` koleksiyonundan al
          final productDoc = await FirebaseFirestore.instance.collection('product').doc(productId).get();
          if (productDoc.exists) {
            final productData = productDoc.data();
            productDetails.add({
              'name': productData?['name'],
              'salePrice': productData?['salePrice'],
              'requestedStock': requestedStock,
              'totalPrice': productData?['salePrice'] * requestedStock,
            });
          }
        }
        return productDetails;
      } else {
        return [];
      }
    } catch (e) {
      print("Hata: $e");
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sipariş Oluştur"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SiparisIslemleri()),
            );
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _companyDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            final companyName = snapshot.data!['companyName'] ?? 'Bilinmiyor';

            return Column(
              children: [
                // Şirket Adı ve Tarih
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        companyName,
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}",
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Sepet Başlıklar
                Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Text("Ürün İsmi",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("Birim Fiyat",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("Adet",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("Toplam",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                // Sepet Ürünleri
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchProductsWithDetails(widget.id), // companyId ile ürünleri çek
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Hata: ${snapshot.error}"));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("Sepette ürün bulunamadı."));
                      } else {
                        List<Map<String, dynamic>> products = snapshot.data!;
                        return ListView.builder(
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  SizedBox(width: 100, child: Text(product['name'])), // Ürün adı
                                  Text("${product['salePrice']}₺"), // Satış fiyatı
                                  Text("${product['requestedStock']}"), // Talep edilen stok
                                  Text("${product['totalPrice'].toStringAsFixed(2)}₺"), // Toplam fiyat
                                ],
                              ),
                            );
                          },
                        );

                      }
                    },
                  ),
                ),

                // Alt Butonlar
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 343,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff65558F),
                        ),
                        onPressed: () {

                        },
                        child: const Text("Yazdır",style: TextStyle(color: Colors.white),),
                      ),
                    ),
                    SizedBox(height: 20,),
                    SizedBox(
                      width: 343,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff65558F),
                        ),
                        onPressed:() async{
                          await saveProductId(widget.id); // product.id, eklenmek istenen ürünün ID'si
                          print("Compay ID shared preferences ile kaydedildi.");
                          _showAddProductOptions();
                        },
                        child: const Text("Ürün Ekle",style: TextStyle(color: Colors.white),),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30,),
              ],
            );
          } else {
            return const Center(child: Text("Veri bulunamadı"));
          }
        },
      ),
    );
  }
}
