import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lojistik/logIn_Page.dart';
import 'package:lojistik/signUp_Page.dart';

class ProfilSayfasi extends StatefulWidget {
  @override
  _ProfilSayfasiState createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  Map<String, dynamic>? _userData;
  String? _updatedName;
  String? _updatedSurname;
  String? _updatedPhone;
  String? _updatedEmail;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kullanıcı bilgileri bulunamadı')),
        );
      }
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcı bilgileri getirilemedi')),
      );
    }
  }

  void _showEditDialog(String field, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$field Düzenle'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: field),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.of(context).pop();
              },
              child: Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserData() async {
    try {
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).update({
          'name': _updatedName ?? _userData?['name'],
          'surname': _updatedSurname ?? _userData?['surname'],
          'phone': _updatedPhone ?? _userData?['phone'],
          'email': _updatedEmail ?? _userData?['email'],
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bilgiler başarıyla güncellendi')),
        );

        _fetchUserData(); // Bilgileri yeniden çek
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bilgiler güncellenemedi: $e')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış yapılamadı: $e')),
      );
    }
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Şifre Değiştir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Mevcut Şifre'),
              ),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Yeni Şifre'),
              ),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Yeni Şifre (Tekrar)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                _changePassword(
                    oldPasswordController.text,
                    newPasswordController.text,
                    confirmPasswordController.text);
                Navigator.of(context).pop();
              },
              child: Text('Onayla'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword(String oldPassword, String newPassword, String confirmPassword) async {
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yeni şifreler eşleşmiyor')),
      );
      return;
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: _user!.email!,
        password: oldPassword,
      );

      await _user!.reauthenticateWithCredential(cred);
      await _user!.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şifre başarıyla güncellendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şifre güncellenemedi: $e')),
      );
    }
  }

  Future<void> _deleteUserAccount() async {
    try {
      // Firebase'den oturum açmış kullanıcının bilgilerini al
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Kullanıcıyı sil
        await user.delete();

        // Hesap silindikten sonra giriş sayfasına yönlendirme
        Navigator.pushReplacement(context,MaterialPageRoute(builder: (context) => LoginPage(),)); // '/login' sayfasına yönlendirme
        print("Kullanıcı hesabı başarıyla silindi.");
      } else {
        print("Oturum açmış bir kullanıcı bulunamadı.");
      }
    } catch (e) {
      // Eğer hata olursa, hatayı yakala
      print("Kullanıcı hesabı silinirken bir hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _userData == null
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Profil",style: TextStyle(fontSize: 25),),
              SizedBox(height: 40,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ad',
                          style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                      Text('${_updatedName ?? _userData?['name'] ?? 'N/A'}'.toUpperCase(),
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff65558F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: () {
                      _showEditDialog('Ad', _userData?['name'] ?? '',
                              (value) {
                            setState(() {
                              _updatedName = value;
                            });
                          });
                    },
                    child: Text("Düzenle",style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
              SizedBox(height: 5), // Boşluk ekliyorum
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Soyad',
                          style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                      Text('${_updatedSurname ?? _userData?['surname'] ?? 'N/A'}'.toUpperCase(),
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff65558F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: () {
                      _showEditDialog('Soyad', _userData?['surname'] ?? '',
                              (value) {
                            setState(() {
                              _updatedSurname = value;
                            });
                          });
                    },
                    child: Text("Düzenle",style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
              SizedBox(height: 5), // Boşluk ekliyorum
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Telefon Numarası',
                          style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                      Text('${_updatedPhone ?? _userData?['phone'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff65558F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: () {
                      _showEditDialog('Telefon Numarası', _userData?['phone'] ?? '',
                              (value) {
                            setState(() {
                              _updatedPhone = value;
                            });
                          });
                    },
                    child: Text("Düzenle",style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
              SizedBox(height: 5), // Boşluk ekliyorum
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mail',
                          style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
                      Text('${_updatedEmail ?? _userData?['email'] ?? 'N/A'}',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10), // Boşluk ekliyorum
              Divider(),
              SizedBox(height: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: _updateUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,  // Butonun arka plan rengi
                      side: BorderSide(color: Colors.grey, width: 1),  // Siyah çizgi
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),  // Radius değeri
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // İç boşluk
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Row'u içeriğin boyutuna göre ayarla
                      children: [
                        Text(
                          'Bilgileri Güncelle',
                          style: TextStyle(color: Colors.black,fontSize: 15),
                        ),
                        SizedBox(width: 8),  // İkon ve yazı arasına boşluk ekliyorum
                        Icon(Icons.chevron_right_sharp, color: Colors.black),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _showChangePasswordDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,  // Butonun arka plan rengi
                      side: BorderSide(color: Colors.grey, width: 1),  // Siyah çizgi
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),  // Radius değeri
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // İç boşluk
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Row'u içeriğin boyutuna göre ayarla
                      children: [
                        Text(
                          'Şifre Değiştir',
                          style: TextStyle(color: Colors.black,fontSize: 15),
                        ),
                        SizedBox(width: 8),  // İkon ve yazı arasına boşluk ekliyorum
                        Icon(Icons.chevron_right_sharp, color: Colors.black),
                      ],
                    ),
                  ),
                  SizedBox(height: 10,),
                  ElevatedButton(
                    onPressed: () {
                      // Bir uyarı dialogu göstermek
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("Hesabı Sil"),
                            content: Text("Hesabınızı silmek istediğinizden emin misiniz?"),
                            actions: [
                              ElevatedButton(
                                onPressed: () async {
                                  // Hesap silme işlemini tetikle
                                  await _deleteUserAccount();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => LoginPage()),
                                  ); // Dialogu kapat
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white, // Butonun arka plan rengi
                                  side: BorderSide(color: Colors.green, width: 2), // Siyah çizgi
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12), // Yuvarlatılmış köşeler
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete, color: Colors.black), // Silme ikonu
                                    SizedBox(width: 8), // İkon ve metin arasına boşluk
                                    Text(
                                      'Evet',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Dialogu kapat
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white, // Butonun arka plan rengi
                                  side: BorderSide(color: Colors.red, width: 2), // Siyah çizgi
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12), // Yuvarlatılmış köşeler
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cancel, color: Colors.black), // İptal ikonu
                                    SizedBox(width: 8), // İkon ve metin arasına boşluk
                                    Text(
                                      'Hayır',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Butonun arka plan rengi
                      side: BorderSide(color: Colors.grey, width: 1), // Siyah çizgi
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Yuvarlatılmış köşeler
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hesabı Sil',
                          style: TextStyle(color: Colors.black),
                        ),
                        SizedBox(width: 8), // İkon ve metin arasında boşluk
                        Icon(Icons.chevron_right_sharp, color: Colors.black),
                      ],
                    ),
                  ),
                  SizedBox(height: 10,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,  // Butonun arka plan rengi
                          side: BorderSide(color: Colors.red, width: 1),  // Siyah çizgi
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),  // Radius değeri
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // İç boşluk
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Row'u içeriğin boyutuna göre ayarla
                          children: [
                            Icon(Icons.logout_outlined, color: Colors.red),
                            SizedBox(width: 8),  // İkon ve yazı arasına boşluk ekliyorum
                            Text(
                              'Çıkış Yap',
                              style: TextStyle(color: Colors.red,fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      Text("v1.0.0",style: TextStyle(fontSize: 16,),),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}