import 'package:flutter/material.dart';
import 'package:lojistik/customer_Menu.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lojistik/customer_product_detail.dart';
import 'package:lojistik/staff_Menu.dart';

class SearchWithBarcodeCustomer extends StatefulWidget {
  const SearchWithBarcodeCustomer({Key? key}) : super(key: key);

  @override
  State<SearchWithBarcodeCustomer> createState() => _SearchWithBarcodeCustomerState();
}

class _SearchWithBarcodeCustomerState extends State<SearchWithBarcodeCustomer> {
  final TextEditingController _barcodeController = TextEditingController();
  String? barcode;

  Future<void> scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleBarcodeScannerPage(),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        barcode = result;
        _barcodeController.text = result;
      });
    } else {
      setState(() {
        _barcodeController.text = "Hata: Barkod okunamadı.";
      });
    }
  }

  Future<void> _searchProduct(String barcode) async {
    try {
      // Firebase'den 'barcode' ile eşleşen ürünü arıyoruz
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('product')
          .where('barcode', isEqualTo: barcode) // 'barcode' verisini string olarak karşılaştırıyoruz
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Ürün bulundu, detay sayfasına yönlendir
        String productId = snapshot.docs.first.id; // Ürünün ID'sini al
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerProductDetail(productId: productId),
          ),
        );
      } else {
        // Ürün bulunamazsa SnackBar ile kullanıcıyı bilgilendir
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün bulunamadı!')),
        );
      }
    } catch (e) {
      // Hata durumunda SnackBar ile kullanıcıyı bilgilendir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Arka plan rengi
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CustomerMenu()),
            );
          },
        ),
        title: const Text("Barkod İle Ürün Ara"),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Barkod İle Ürün Ara",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: scanBarcode, // Barkod tarama işlemini tetikle
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 2,
                    width: double.infinity,
                    color: Colors.red,
                  ),
                  const Positioned(
                    bottom: 20,
                    child: Text(
                      "Barkod taramak için tıklayın",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              height: 48,
              width: 343,
              child: TextField(
                controller: _barcodeController, // TextField için controller kullanılıyor
                keyboardType: TextInputType.number, // Sadece sayı girişi
                decoration: InputDecoration(
                  labelText: 'Barkod numarası girin',
                  border: OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              height: 48,
              width: 343,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff65558F),
                ),
                onPressed: () {
                  // Barkod numarasına göre arama işlemi yapılacak
                  String barcode = _barcodeController.text.trim();
                  if (barcode.isNotEmpty) {
                    _searchProduct(barcode);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lütfen barkod numarasını girin.')),
                    );
                  }
                },
                child: const Text("Ara", style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}