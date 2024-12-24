import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lojistik/delete_succsess.dart';
import 'package:lojistik/listed_product_customer.dart';
import 'package:lojistik/product.dart';
import 'package:lojistik/search_with_barcode.dart';
import 'package:lojistik/siparis_islemleri_customer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SiparisOlusturCustomer extends StatefulWidget {
  final String id;

  const SiparisOlusturCustomer({super.key, required this.id});

  @override
  State<SiparisOlusturCustomer> createState() => _SiparisOlusturCustomerState();
}

class _SiparisOlusturCustomerState extends State<SiparisOlusturCustomer> {
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
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('selfProcess')
        .doc(widget.id)
        .get();

    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    } else {
      throw Exception("Veri bulunamadı");
    }
  }


  Future<void> _fetchSepetUrunler() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('selfProcess')
        .doc(widget.id)
        .get();

    if (snapshot.exists) {
      List<dynamic> sepetIds = snapshot['products'] ?? [];
      List<Product> sepetUrunler = [];

      for (var product in sepetIds) {
        String productId = product['productId'];
        int requestedStock = product['requestedStock'];

        DocumentSnapshot productDoc = await FirebaseFirestore.instance
            .collection('product')
            .doc(productId)
            .get();

        if (productDoc.exists) {
          sepetUrunler.add(Product.fromJson(
            productDoc.id,
            {
              ...productDoc.data() as Map<String, dynamic>,
              'requestedStock': requestedStock,
            },
          ));
        }
      }
      setState(() {
        _sepetUrunler = sepetUrunler;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchProductsWithDetails(String companyId) async {
    try {
      final String userId = FirebaseAuth.instance.currentUser!.uid;

      // selfProcess içindeki ürünleri al
      final processDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selfProcess')
          .doc(companyId)
          .get();

      if (processDoc.exists) {
        List<dynamic> products = processDoc.data()?['products'] ?? [];

        // Her bir ürünün detaylarını product koleksiyonundan çek
        List<Map<String, dynamic>> productDetails = [];
        for (var product in products) {
          String productId = product['productId'];
          int requestedStock = product['requestedStock'];

          final productDoc = await FirebaseFirestore.instance
              .collection('product')
              .doc(productId)
              .get();

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
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ListedProductCustomer(),));
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
  Future<void> updateStockAndRemoveProduct(String userId, String processId, int productIndex) async {
    try {
      // 1. users koleksiyonundan selfProcess alt koleksiyonunu referans al
      final processRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('selfProcess')
          .doc(processId);

      final processSnapshot = await processRef.get();

      // Eğer belge mevcut değilse hata fırlat
      if (!processSnapshot.exists) {
        throw Exception("Process bulunamadı");
      }

      // 'products' alanını al
      List<dynamic> products = processSnapshot.data()?['products'] ?? [];

      // Geçerli bir index kontrolü
      if (productIndex < 0 || productIndex >= products.length) {
        throw Exception("Geçersiz ürün indexi");
      }

      // 2. Silinecek ürünün bilgilerini al
      final Map<String, dynamic> product = products[productIndex];
      final String productId = product['productId'];
      final int requestedStock = product['requestedStock'];

      // 3. Product koleksiyonunda stok güncellemesi yap
      final productRef = FirebaseFirestore.instance.collection('product').doc(productId);
      await productRef.update({
        'stockQuantity': FieldValue.increment(requestedStock),
      });

      // 4. Process alt koleksiyonundaki product array'inden ürünü sil
      products.removeAt(productIndex);
      await processRef.update({
        'products': products,
      });

      // Başarı mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ürün başarıyla silindi ve stok güncellendi."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Hata mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  void confirmDeleteProduct(String processId, int productIndex) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ürünü Sil"),
          content: const Text("Bu ürünü silmek istediğinize emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Dialog'u kapat
              },
              child: const Text("İptal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context,MaterialPageRoute(builder: (context) => DeleteSuccess(id: widget.id),)); // Dialog'u kapat
                updateStockAndRemoveProduct(userId, processId, productIndex); // Silme işlemini başlat
              },
              child: const Text("Onayla"),
            ),
          ],
        );
      },
    );
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
              MaterialPageRoute(builder: (context) => SiparisIslemleriCustomer()),
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
                      Text("Sil",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchProductsWithDetails(widget.id), // selfProcess içeriği
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
                                  GestureDetector(
                                    onTap: () {
                                      confirmDeleteProduct(widget.id, index); // Bu şekilde bir callback sağlıyoruz
                                    },
                                    child: const Icon(Icons.delete, color: Colors.red),
                                  ),
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
