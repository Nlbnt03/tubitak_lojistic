import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lojistik/customer_Menu.dart';
import 'package:lojistik/siparis_olustur_customer.dart';
import 'package:lojistik/siparis_olustur_staff.dart';
import 'package:lojistik/staff_Menu.dart';

class DeleteSuccess extends StatefulWidget {
  final String id;

  const DeleteSuccess({super.key, required this.id});

  @override
  State<DeleteSuccess> createState() => _DeleteSuccessState();
}

class _DeleteSuccessState extends State<DeleteSuccess> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getUserRole() async {
    try {
      // Mevcut kullanıcıyı al
      User? user = _auth.currentUser;
      if (user == null) return null;

      // Firestore'dan kullanıcı belgesini getir
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      // Role alanını al
      return userDoc['role'] as String?;
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }

  void navigateToMenu(BuildContext context) async {
    String? role = await getUserRole();

    if (role == 'staff') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => StaffMenu()));
    } else if (role == 'customer') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CustomerMenu()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role not recognized')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Silme Başarılı"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ortadaki resim
            Image.asset(
              'images/silme.png', // Resim dosyasını assets klasöründen yükleyin
              width: 350,
              height: 350,
            ),
            const SizedBox(height: 20),
            // İşleme devam et butonu
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed : () async
                {
                  String? role = await getUserRole();
                  if (role == 'staff')
                  {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SiparisOlustur(id: widget.id)));
                  }
                  else if (role == 'customer')
                  {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SiparisOlusturCustomer(id: widget.id)));
                  }
                  else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Kullanıcı rolü tanımlanamadı')),
                    );
                  }
                },
                child: const Text(
                  "İşleme Devam Et",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Menüye dön butonu
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () {
                  navigateToMenu(context);
                },
                child: const Text(
                  "Menüye Dön",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
