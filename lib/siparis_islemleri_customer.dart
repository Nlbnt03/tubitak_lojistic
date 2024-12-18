import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lojistik/customer_Menu.dart';
import 'package:lojistik/siparis_olustur_customer.dart';

class SiparisIslemleriCustomer extends StatefulWidget {
  const SiparisIslemleriCustomer({super.key});

  @override
  State<SiparisIslemleriCustomer> createState() => _SiparisIslemleriCustomerState();
}

class _SiparisIslemleriCustomerState extends State<SiparisIslemleriCustomer> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _showAddCompanyDialog() async {
    final TextEditingController companyNameController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("İşlem Oluştur"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: companyNameController,
                    decoration: const InputDecoration(labelText: "İşlem Adı"),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Tarih: ${DateFormat('dd/MM/yyyy').format(selectedDate)}"),
                      IconButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null && picked != selectedDate) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          icon: Icon(Icons.date_range_outlined))
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("İptal",style: TextStyle(color: Colors.white),),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green
                  ),
                  onPressed: () {
                    if (companyNameController.text.isNotEmpty) {
                      _addCompany(companyNameController.text, selectedDate);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Ekle",style: TextStyle(color: Colors.white),),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addCompany(String companyName, DateTime date) async {
    try {
      // Oturum açmış kullanıcının ID'sini alın
      final String userId = FirebaseAuth.instance.currentUser!.uid;

      // Kullanıcının selfProcess alt koleksiyonuna işlem ekleyin
      await FirebaseFirestore.instance
          .collection('users') // Kullanıcı koleksiyonu
          .doc(userId) // Kullanıcı ID'si
          .collection('selfProcess') // Alt koleksiyon
          .add({
        'companyName': companyName,
        'date': date.toIso8601String(),
        'products': [], // Başlangıçta ürün listesi boş olabilir
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("İşlem başarıyla eklendi."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Stream<QuerySnapshot> _getCompanies() {
    // Oturum açmış kullanıcının ID'sini alın
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    // Kullanıcının selfProcess alt koleksiyonundaki işlemleri dinleyin
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('selfProcess')
        .orderBy('date', descending: true)
        .snapshots();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sipariş İşlemleri"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CustomerMenu()),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: _showAddCompanyDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: "Ara",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getCompanies(), // Kullanıcının işlemlerini dinleyen stream
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Henüz işlem eklenmedi."));
                }

                // Arama sorgusuna göre filtreleme
                final processes = snapshot.data!.docs.where((doc) {
                  final companyName = doc['companyName'].toString().toLowerCase();
                  return companyName.contains(_searchQuery); // _searchQuery arama metni
                }).toList();

                if (processes.isEmpty) {
                  return const Center(child: Text("Sonuç bulunamadı."));
                }

                return ListView.builder(
                  itemCount: processes.length,
                  itemBuilder: (context, index) {
                    final process = processes[index];
                    final companyName = process['companyName'];
                    final date = DateTime.parse(process['date']);

                    return ListTile(
                      title: Text(companyName),
                      subtitle: Text("Tarih: ${DateFormat('dd/MM/yyyy').format(date)}"),
                      onTap: () {
                        // SiparisOlustur sayfasına yönlendirme
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SiparisOlusturCustomer(id: process.id),
                          ),
                        );
                      },
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
