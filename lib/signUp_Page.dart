import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'logIn_Page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Form key
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // CheckBox kontrol değişkenleri
  bool _kvkkAccepted = false;
  bool _userAgreementAccepted = false;
  bool _commercialMessageAccepted = false;

  // Şifreyi gizleme
  bool _isPasswordVisible = false;

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kayıt Ol"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Başlık
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: const [
                    Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text(
                        "Kayıt Ol",
                        style: TextStyle(
                          fontSize: 30,
                          color: Color(0xff333333),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                // Ad-Soyad, Telefon, E-posta, Şifre alanları
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ad TextField
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Ad',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ad boş olamaz';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),

                    // Soyad TextField
                    TextFormField(
                      controller: _surnameController,
                      decoration: InputDecoration(
                        labelText: 'Soyad',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Soyad boş olamaz';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),

                    // Telefon Numarası TextField
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Telefon Numarası',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Telefon numarası boş olamaz';
                        }
                        if (!RegExp(r'^(0|\+90)[1-9][0-9]{9}$').hasMatch(value)) {
                          return 'Geçerli bir telefon numarası girin (örn. +90 veya 0 ile başlayın)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),

                    // E-posta TextField
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'E-posta',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'E-posta boş olamaz';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]+').hasMatch(value)) {
                          return 'Geçerli bir e-posta girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10.0),

                    // Şifre TextField
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Şifre boş olamaz';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20.0),
                  ],
                ),

                // Onay Kutuları
                Column(
                  children: [
                    // KVKK
                    Row(
                      children: [
                        Checkbox(
                          value: _kvkkAccepted,
                          onChanged: (value) {
                            setState(() {
                              _kvkkAccepted = value ?? false;
                            });
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            print("KVKK Onayı Tıklandı");
                          },
                          child: const Text(
                            "Kişisel Verilerin Korunması Onayı (KVKK)",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Kullanıcı Sözleşmesi
                    Row(
                      children: [
                        Checkbox(
                          value: _userAgreementAccepted,
                          onChanged: (value) {
                            setState(() {
                              _userAgreementAccepted = value ?? false;
                            });
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            print("Kullanıcı Sözleşmesi Onayı Tıklandı");
                          },
                          child: const Text(
                            "Kullanıcı Sözleşmesi Onayı",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Ticari Elektronik İleti
                    Row(
                      children: [
                        Checkbox(
                          value: _commercialMessageAccepted,
                          onChanged: (value) {
                            setState(() {
                              _commercialMessageAccepted = value ?? false;
                            });
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            print("Ticari Elektronik İleti Onayı Tıklandı");
                          },
                          child: const Text(
                            "Ticari Elektronik İleti Onayı",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10.0),

                // Kayıt Ol butonu
                SizedBox(
                  width: 358,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_kvkkAccepted &&
                            _userAgreementAccepted &&
                            _commercialMessageAccepted) {
                          // Firebase'e kayıt işlemi
                          _registerUser();
                        } else {
                          // Kullanıcı onay kutularını işaretlememiş
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tüm onayları kabul edin')),
                          );
                        }
                      }
                    },
                    child: const Text("Kayıt Ol", style: TextStyle(color: Color(0xff333333))),
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),

                // Giriş Yap bağlantısı
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Zaten Hesabınız Var mı? Giriş Yap",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _registerUser() async {
    try {
      // Firebase Auth ile kullanıcı kaydı
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Firebase Firestore'a kullanıcı verilerini kaydetme
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text,
        'surname': _surnameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'role': 'customer', // Varsayılan olarak müşteri olarak belirle
      });

      // Kayıt başarılı mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt Başarılı')),
      );

      // Giriş sayfasına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      // Hata mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }

}
