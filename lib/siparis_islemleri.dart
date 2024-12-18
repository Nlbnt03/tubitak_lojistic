import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lojistik/siparis_olustur_staff.dart';
import 'package:lojistik/staff_Menu.dart';

class SiparisIslemleri extends StatefulWidget {
  const SiparisIslemleri({super.key});

  @override
  State<SiparisIslemleri> createState() => _SiparisIslemleriState();
}

class _SiparisIslemleriState extends State<SiparisIslemleri> {
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
              title: const Text("Firma Ekle"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: companyNameController,
                    decoration: const InputDecoration(labelText: "Firma Adı"),
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
    await _firestore.collection('process').add({
      'companyName': companyName,
      'date': date.toIso8601String(),
    });
  }

  Stream<QuerySnapshot> _getCompanies() {
    return _firestore
        .collection('process')
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
              MaterialPageRoute(builder: (context) => StaffMenu()),
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
              stream: _getCompanies(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Henüz firma eklenmedi."));
                }

                final companies = snapshot.data!.docs.where((doc) {
                  final companyName = doc['companyName'].toString().toLowerCase();
                  return companyName.contains(_searchQuery);
                }).toList();

                if (companies.isEmpty) {
                  return const Center(child: Text("Sonuç bulunamadı."));
                }

                return ListView.builder(
                  itemCount: companies.length,
                  itemBuilder: (context, index) {
                    final company = companies[index];
                    final companyName = company['companyName'];
                    final date = DateTime.parse(company['date']);
                    return ListTile(
                      title: Text(companyName),
                      subtitle: Text("Tarih: ${DateFormat('dd/MM/yyyy').format(date)}"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SiparisOlustur(id: company.id),
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
