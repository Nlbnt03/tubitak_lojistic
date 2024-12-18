import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Takvim için
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lojistik/added_succes.dart';
import 'package:lojistik/product.dart';
import 'package:lojistik/staff_Menu.dart';

class AddItemName extends StatefulWidget {
  const AddItemName({super.key});

  @override
  State<AddItemName> createState() => _AddItemNameState();
}

class _AddItemNameState extends State<AddItemName> {
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController stockQuantityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController purchaseDateController = TextEditingController();
  final TextEditingController purchasePriceController = TextEditingController();
  final TextEditingController salePriceController = TextEditingController();
  final TextEditingController noteController = TextEditingController();


  // Görülebilirlik durumları
  bool isNameVisible = true;
  bool isBarcodeVisible = true;
  bool isStockQuantityVisible = true;
  bool isLocationVisible = true;
  bool isPurchaseDateVisible = true;
  bool isPurchasePriceVisible = true;
  bool isSalePriceVisible = true;
  bool isNoteVisible = true;

  Future<void> addProductToFirebase(Product product) async {
    await FirebaseFirestore.instance.collection('product').add(product.toJson());
  }


  void _showEditDialog(TextEditingController controller, String label) {
    final TextEditingController tempController =
    TextEditingController(text: controller.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label Düzenle'),
        content: TextField(
          controller: tempController,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                controller.text = tempController.text;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
  void _showVisibilityDialog(BuildContext context, String label, String message, bool currentValue, Function(bool) onChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            ListTile(
              title: Text("Görülebilir"),
              leading: Radio<bool>(
                value: true, // Görülebilir seçeneği
                groupValue: currentValue,
                onChanged: (bool? value) {
                  if (value != null) {
                    onChanged(value); // Değeri güncelle
                    Navigator.of(context).pop(); // Dialog'u kapat
                  }
                },
              ),
            ),
            ListTile(
              title: Text("Görülemez"),
              leading: Radio<bool>(
                value: false, // Görülemez seçeneği
                groupValue: currentValue,
                onChanged: (bool? value) {
                  if (value != null) {
                    onChanged(value); // Değeri güncelle
                    Navigator.of(context).pop(); // Dialog'u kapat
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        purchaseDateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  Widget _buildEditableTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool isDatePicker = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 45,
            child: TextField(
              controller: controller,
              readOnly: isDatePicker,
              keyboardType: keyboardType,
              onTap: isDatePicker ? () => _selectDate(context) : null,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditDialog(controller, label);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Düzenle'),
            ),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back),onPressed: (){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => StaffMenu(),));
        },),
        title: const Text("İsim İle Ürün Yükle"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Ürün Adı",style: TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold),),
                    SizedBox(width: 5.0),
                    IconButton(
                      icon: Icon(
                        Icons.remove_red_eye,
                        color: isNameVisible ? Colors.green : Colors.red, // Icon rengi, seçilen duruma göre değişir.
                      ),
                      onPressed: () {
                        _showVisibilityDialog(context, "Satış Fiyatı", "Satış fiyatı görünürlüğünü ayarla", isNameVisible, (value) {
                          setState(() {
                            isNameVisible = value; // RadioButton değeri değiştiğinde isSalePriceVisible güncellenir.
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
              _buildEditableTextField(
                controller: productNameController,
                label: "Ürün Adı",
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Barkod Numarası",style: TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold),),
                    SizedBox(width: 5.0),
                    IconButton(
                      icon: Icon(
                        Icons.remove_red_eye,
                        color: isBarcodeVisible ? Colors.green : Colors.red, // Icon rengi, seçilen duruma göre değişir.
                      ),
                      onPressed: () {
                        _showVisibilityDialog(context, "Satış Fiyatı", "Satış fiyatı görünürlüğünü ayarla", isBarcodeVisible, (value) {
                          setState(() {
                            isBarcodeVisible = value; // RadioButton değeri değiştiğinde isSalePriceVisible güncellenir.
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
              _buildEditableTextField(
                controller: barcodeController,
                label: "Barkod Numarası",
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Stok Miktarı",style: TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold),),
                    SizedBox(width: 5.0),
                    IconButton(
                      icon: Icon(
                        Icons.remove_red_eye,
                        color: isStockQuantityVisible ? Colors.green : Colors.red, // Icon rengi, seçilen duruma göre değişir.
                      ),
                      onPressed: () {
                        _showVisibilityDialog(context, "Satış Fiyatı", "Satış fiyatı görünürlüğünü ayarla", isStockQuantityVisible, (value) {
                          setState(() {
                            isStockQuantityVisible = value; // RadioButton değeri değiştiğinde isSalePriceVisible güncellenir.
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
              _buildEditableTextField(
                controller: stockQuantityController,
                label: "Stok Miktarı",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Depo Konumu",style: TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold),),
                    SizedBox(width: 5.0),
                    IconButton(
                      icon: Icon(
                        Icons.remove_red_eye,
                        color: isLocationVisible ? Colors.green : Colors.red, // Icon rengi, seçilen duruma göre değişir.
                      ),
                      onPressed: () {
                        _showVisibilityDialog(context, "Satış Fiyatı", "Satış fiyatı görünürlüğünü ayarla", isLocationVisible, (value) {
                          setState(() {
                            isLocationVisible = value; // RadioButton değeri değiştiğinde isSalePriceVisible güncellenir.
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
              _buildEditableTextField(
                controller: locationController,
                label: "Depo Konumu",
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Alım Tarihi",style: TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold),),
                    SizedBox(width: 5.0),
                    IconButton(
                      icon: Icon(
                        Icons.remove_red_eye,
                        color: isPurchaseDateVisible ? Colors.green : Colors.red, // Icon rengi, seçilen duruma göre değişir.
                      ),
                      onPressed: () {
                        _showVisibilityDialog(context, "Satış Fiyatı", "Satış fiyatı görünürlüğünü ayarla", isPurchaseDateVisible, (value) {
                          setState(() {
                            isPurchaseDateVisible = value; // RadioButton değeri değiştiğinde isSalePriceVisible güncellenir.
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
              _buildEditableTextField(
                controller: purchaseDateController,
                label: "Alım Tarihi",
                isDatePicker: true,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Alış Fiyatı",style: TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold),),
                    SizedBox(width: 5.0),
                    IconButton(
                      icon: Icon(
                        Icons.remove_red_eye,
                        color: isPurchasePriceVisible ? Colors.green : Colors.red, // Icon rengi, seçilen duruma göre değişir.
                      ),
                      onPressed: () {
                        _showVisibilityDialog(context, "Satış Fiyatı", "Satış fiyatı görünürlüğünü ayarla", isPurchasePriceVisible, (value) {
                          setState(() {
                            isPurchasePriceVisible = value; // RadioButton değeri değiştiğinde isSalePriceVisible güncellenir.
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
              _buildEditableTextField(
                controller: purchasePriceController,
                label: "Alış Fiyatı",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "Satış Fiyatı",
                      style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 5.0),
                    IconButton(
                      icon: Icon(
                        Icons.remove_red_eye,
                        color: isSalePriceVisible ? Colors.green : Colors.red, // Icon rengi, seçilen duruma göre değişir.
                      ),
                      onPressed: () {
                        _showVisibilityDialog(context, "Satış Fiyatı", "Satış fiyatı görünürlüğünü ayarla", isSalePriceVisible, (value) {
                          setState(() {
                            isSalePriceVisible = value; // RadioButton değeri değiştiğinde isSalePriceVisible güncellenir.
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
              _buildEditableTextField(
                controller: salePriceController,
                label: "Satış Fiyatı",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Not",style: TextStyle(color: Colors.black,fontSize: 16,fontWeight: FontWeight.bold),),
                    SizedBox(width: 5.0),
                    IconButton(
                      icon: Icon(
                        Icons.remove_red_eye,
                        color: isNoteVisible ? Colors.green : Colors.red, // Icon rengi, seçilen duruma göre değişir.
                      ),
                      onPressed: () {
                        _showVisibilityDialog(context, "Satış Fiyatı", "Satış fiyatı görünürlüğünü ayarla", isNoteVisible, (value) {
                          setState(() {
                            isNoteVisible = value; // RadioButton değeri değiştiğinde isSalePriceVisible güncellenir.
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
              _buildEditableTextField(
                controller: noteController,
                label: "Not",
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 343,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff65558F),
                  ),
                  onPressed: () async {
                    try {
                      final product = Product(
                        id: '', // Firestore otomatik oluşturacak
                        name: productNameController.text,
                        barcode: barcodeController.text,
                        stockQuantity: int.tryParse(stockQuantityController.text) ?? 0,
                        location: locationController.text,
                        purchaseDate: DateFormat('dd/MM/yyyy').parse(purchaseDateController.text),
                        purchasePrice: double.tryParse(purchasePriceController.text) ?? 0.0,
                        salePrice: double.tryParse(salePriceController.text) ?? 0.0,
                        note: noteController.text,
                        isNameVisible: isNameVisible,
                        isBarcodeVisible: isBarcodeVisible,
                        isStockQuantityVisible: isStockQuantityVisible,
                        isLocationVisible: isLocationVisible,
                        isPurchaseDateVisible: isPurchaseDateVisible,
                        isPurchasePriceVisible: isPurchasePriceVisible,
                        isSalePriceVisible: isSalePriceVisible,
                        isNoteVisible: isNoteVisible,

                      );
                      await addProductToFirebase(product);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ürün başarıyla eklendi!')),
                      );
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AddedSucces(),));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hata: $e')),
                      );
                    }
                  },

                  child: Text("+   Ürün Yükle",style: TextStyle(color: Colors.white,fontSize: 18,fontWeight: FontWeight.bold),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
