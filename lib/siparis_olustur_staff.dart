import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lojistik/delete_succsess.dart';
import 'package:lojistik/listed_product.dart';
import 'package:lojistik/product.dart';
import 'package:lojistik/search_with_barcode.dart';
import 'package:lojistik/siparis_islemleri.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;


class SiparisOlustur extends StatefulWidget {
  final String id;

  const SiparisOlustur({super.key, required this.id});

  @override
  State<SiparisOlustur> createState() => _SiparisOlusturState();
}

class _SiparisOlusturState extends State<SiparisOlustur> {
  late Future<Map<String, dynamic>> _companyDetailsFuture;
  List<Product> _sepetUrunler = [];
  double totalPrice = 0.0;
  TextEditingController textController = TextEditingController();

  late Future<List<Map<String, dynamic>>> _productDetailsFuture;

  @override
  void initState() {
    super.initState();
    _companyDetailsFuture = _getCompanyDetails();
    _fetchSepetUrunler();
    _productDetailsFuture = fetchProductsWithDetails(widget.id);
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
      final processDoc = await FirebaseFirestore.instance.collection('process').doc(companyId).get();

      if (processDoc.exists) {
        List<dynamic> products = processDoc.data()?['products'] ?? [];

        List<Map<String, dynamic>> productDetails = [];
        for (var product in products) {
          String productId = product['productId'];
          int requestedStock = product['requestedStock'];

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

        // Toplam fiyatı hesapla
        _calculateTotalPrice(productDetails);

        return productDetails;
      } else {
        return [];
      }
    } catch (e) {
      print("Hata: $e");
      return [];
    }
  }

  void _calculateTotalPrice(List<Map<String, dynamic>> products) {
    double total = 0.0;
    for (var product in products) {
      total += product['totalPrice']; // Her ürünün totalPrice'ını toplar
    }

    setState(() {
      totalPrice = total; // Toplamı totalPrice değişkenine atar
    });
  }


  Future<void> updateStockAndRemoveProduct(String processId, int productIndex) async {
    try {
      // 1. Process tablosundan product array'i alın
      final processRef = FirebaseFirestore.instance.collection('process').doc(processId);
      final processSnapshot = await processRef.get();

      if (!processSnapshot.exists) {
        throw Exception("Process bulunamadı");
      }

      List<dynamic> products = processSnapshot.data()?['products'] ?? [];

      if (productIndex < 0 || productIndex >= products.length) {
        throw Exception("Geçersiz ürün indexi");
      }

      // 2. Silinecek ürünün bilgilerini alın
      final Map<String, dynamic> product = products[productIndex];
      final String productId = product['productId'];
      final int requestedStock = product['requestedStock'];

      // 3. Product tablosunda stok güncellemesi yap
      final productRef = FirebaseFirestore.instance.collection('product').doc(productId);
      await productRef.update({
        'stockQuantity': FieldValue.increment(requestedStock),
      });

      // 4. Process tablosundaki product array'inden ürünü sil
      products.removeAt(productIndex);
      await processRef.update({
        'products': products,
      });
      fetchProductsWithDetails(processId).then((products) {
        _calculateTotalPrice(products);
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
                Navigator.push(context,MaterialPageRoute(builder: (context) => DeleteSuccess(id: widget.id,),)); // Dialog'u kapat
                updateStockAndRemoveProduct(processId, productIndex); // Silme işlemini başlat
              },
              child: const Text("Onayla"),
            ),
          ],
        );
      },
    );
  }
  Future<String> createPdf(String companyName, String date, List<Map<String, dynamic>> products, double totalPrice) async {
    final pdf = pw.Document();

    // Create base font
    final font = pw.Font.helvetica();

    // Create text styles with the font
    final titleStyle = pw.TextStyle(
      font: font,
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
    );

    final headerStyle = pw.TextStyle(
      font: font,
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
    );

    final normalStyle = pw.TextStyle(
      font: font,
      fontSize: 14,
    );

    final tableHeaderStyle = pw.TextStyle(
      font: font,
      fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Sirket Adi: $companyName'.toUpperCase(), style: titleStyle),
              pw.Text('Tarih: $date'.toUpperCase(), style: normalStyle),
              pw.SizedBox(height: 20),

              pw.Text('Ürün Listesi:'.toUpperCase(), style: headerStyle),
              pw.Divider(),

              // Table Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Ürün Ismi'.toUpperCase(), style: tableHeaderStyle)),
                  pw.Expanded(flex: 2, child: pw.Text('Birim Fiyat'.toUpperCase(), style: tableHeaderStyle)),
                  pw.Expanded(flex: 1, child: pw.Text('Adet'.toUpperCase(), style: tableHeaderStyle)),
                  pw.Expanded(flex: 2, child: pw.Text('Toplam'.toUpperCase(), style: tableHeaderStyle)),
                ],
              ),
              pw.Divider(),

              // Product List
              pw.Column(
                children: products.map((product) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(flex: 3, child: pw.Text("${product['name']}".toUpperCase(), style: normalStyle)),
                        pw.Expanded(flex: 2, child: pw.Text('${product['salePrice'].toStringAsFixed(2)} TL'.toUpperCase(), style: normalStyle)),
                        pw.Expanded(flex: 1, child: pw.Text('${product['requestedStock']}'.toUpperCase(), style: normalStyle)),
                        pw.Expanded(flex: 2, child: pw.Text('${(product['totalPrice'] as num).toStringAsFixed(2)} TL'.toUpperCase(), style: normalStyle)),
                      ],
                    ),
                  );
                }).toList(),
              ),

              pw.Divider(),
              pw.SizedBox(height: 20),

              // Total Price
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Toplam Fiyat: ${totalPrice.toStringAsFixed(2)} TL'.toUpperCase(),
                    style: headerStyle,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save PDF with UTF-8 encoding
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/siparis_detaylari.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  Future<String> generateOrderDetails(String companyName, String date, List<Map<String, dynamic>> products, double totalPrice) async {
    String orderDetails = 'Sipariş Detayları:\n';
    orderDetails += 'Şirket Adı: $companyName\n';
    orderDetails += 'Tarih: $date\n';
    orderDetails += '\nÜrün Listesi:\n';

    for (var product in products) {
      final double salePrice = product['salePrice'] != null ? double.tryParse(product['salePrice'].toString()) ?? 0.0 : 0.0;
      final int requestedStock = product['requestedStock'] != null ? int.tryParse(product['requestedStock'].toString()) ?? 0 : 0;
      final double total = salePrice * requestedStock;

      orderDetails += 'Ürün İsmi: ${product['name'] ?? 'Bilinmiyor'}\n';
      orderDetails += 'Birim Fiyat: ${salePrice.toStringAsFixed(2)}₺\n';
      orderDetails += 'Adet: $requestedStock\n';
      orderDetails += 'Toplam: ${total.toStringAsFixed(2)}₺\n';
      orderDetails += '----------------------\n';
    }

    orderDetails += '\nToplam Fiyat: ${totalPrice.toStringAsFixed(2)}₺\n';

    return orderDetails;
  }


  void sharePdf(String filePath) {
    Share.shareXFiles([XFile(filePath)], text: 'Sipariş detayları ektedir.');
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
                      Text("Sil",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _productDetailsFuture, // Future değişkeni kullanılıyor/ companyId ile ürünleri çek
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        // Update the ElevatedButton's onPressed handler:
                        onPressed: () async {
                          if (snapshot.hasData) {
                            final String companyName = snapshot.data!['companyName'] ?? 'Bilinmiyor';
                            final String currentDate = "${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}";

                            try {
                              // Fetch the processed product details
                              final List<Map<String, dynamic>> products = await _productDetailsFuture;

                              if (products.isNotEmpty) {
                                // Create and share PDF
                                final filePath = await createPdf(companyName, currentDate, products, totalPrice);
                                sharePdf(filePath);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Sepette ürün bulunmamaktadır."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              print("PDF oluşturma hatası: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("PDF oluşturulurken bir hata oluştu: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Şirket bilgileri yüklenemedi."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
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
