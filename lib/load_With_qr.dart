import 'package:flutter/material.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:lojistik/add_item_barcode.dart';
import 'package:lojistik/add_item_name.dart';
import 'package:lojistik/staff_Menu.dart';

class LoadWithQr extends StatefulWidget {
  const LoadWithQr({Key? key}) : super(key: key);

  @override
  State<LoadWithQr> createState() => _LoadWithQrState();
}

class _LoadWithQrState extends State<LoadWithQr> {
  final TextEditingController _barcodeController = TextEditingController();

  Future<void> scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleBarcodeScannerPage(),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _barcodeController.text = result;
      });

      // Barkod okunduktan sonra yeni sayfaya yönlendirme
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddItemBarcode(barcode: result),
        ),
      );
    } else {
      setState(() {
        _barcodeController.text = "Hata: Barkod okunamadı.";
      });
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
              MaterialPageRoute(builder: (context) => StaffMenu()),
            );
          },
        ),
        title: const Text("Barkod İle Ürün Yükle"),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Barkod İle Ürün Yükle",
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
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddItemName()),
                );
                debugPrint("Manuel olarak yükleye tıklandı: ${_barcodeController.text}");
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Manuel Olarak Yükle", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff65558F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}