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

  void showAgreementDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        bool isBottomReached = false;
        ScrollController scrollController = ScrollController();

        scrollController.addListener(() {
          if (scrollController.position.atEdge) {
            if (scrollController.position.pixels != 0) {
              setState(() {
                isBottomReached = true;
              });
            }
          }
        });

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                height: 300,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(content),
                ),
              ),
              actions: [
                if (isBottomReached)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tamam'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

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
                            showAgreementDialog(context, "Kişisel Verilerin Korunması Onayı (KVKK)", kvkkContent);
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
                            showAgreementDialog(context, "Kullanıcı Sözleşmesi Onayı", userAgreementContent);
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
                            showAgreementDialog(context, "Ticari Elektronik İleti Onayı", commercialMessageContent);
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
                    child: const Text("Kayıt Ol", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff65558F),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Zaten Hesabınız Var Mı?",style: TextStyle(color: Colors.blue),),
                        Text(" Giriş Yap",style: TextStyle(color: Color(0xffFF82AB), fontWeight: FontWeight.bold),)
                      ],
                    )
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

const String kvkkContent = '''
1. Veri Sorumlusunun Kimliği
Bu aydınlatma metni, [Şirket Adı] (“Şirket”) tarafından, 6698 sayılı Kişisel Verilerin Korunması Kanunu (“KVKK”) uyarınca veri sorumlusu sıfatıyla hazırlanmıştır.

2. Kişisel Verilerin İşlenme Amaçları
Şirketimiz, kişisel verilerinizi aşağıdaki amaçlarla işlemektedir:

Ürün ve hizmetlerin sunulması, geliştirilmesi ve müşteri memnuniyetinin artırılması,
Sözleşmelerin ifası, faturalandırma ve ödeme işlemlerinin gerçekleştirilmesi,
Hukuki yükümlülüklerin yerine getirilmesi,
Yetkili kamu kurumları ile yasal çerçevede bilgi paylaşımı,
Müşteri taleplerinin ve şikayetlerinin yönetilmesi,
Pazarlama, kampanya ve tanıtım faaliyetlerinin yürütülmesi.
3. Kişisel Verilerin Toplanma Yöntemi ve Hukuki Sebebi
Kişisel verileriniz, otomatik veya otomatik olmayan yollarla, aşağıdaki yöntemlerle toplanmaktadır:

Web sitelerimiz, mobil uygulamalarımız, e-posta, telefon ve çağrı merkezleri aracılığıyla,
Sözleşmeler, formlar, anketler, yüz yüze görüşmeler veya dijital platformlar üzerinden,
Kanuni yükümlülüklerimizi yerine getirmek amacıyla kamu kurumları ve diğer resmi mercilerden gelen bilgiler doğrultusunda.
Verileriniz KVKK’nın 5. ve 6. maddelerinde belirtilen hukuki sebepler çerçevesinde işlenmektedir.

4. Kişisel Verilerin Aktarılması
Kişisel verileriniz, KVKK’nın 8. ve 9. maddeleri kapsamında şu kişi ve kurumlara aktarılabilir:

Yetkili kamu kurum ve kuruluşlarına,
İş ortaklarımıza, tedarikçilerimize, bankalara ve ödeme kuruluşlarına,
Hukuki süreçlerin yürütülmesi için avukatlarımıza, danışmanlarımıza ve denetim firmalarına,
Kanunen yetkili kamu kurumları ve resmi mercilere.
5. KVKK Kapsamındaki Haklarınız
KVKK’nın 11. maddesi uyarınca, veri sahipleri olarak aşağıdaki haklara sahipsiniz:

Kişisel verilerinizin işlenip işlenmediğini öğrenme,
İşlenmişse buna ilişkin bilgi talep etme,
İşlenme amacını ve bunların amacına uygun kullanılıp kullanılmadığını öğrenme,
Verilerin yurt içinde veya yurt dışında aktarıldığı üçüncü kişileri bilme,
Eksik veya yanlış işlenmiş olması halinde düzeltilmesini isteme,
KVKK’da öngörülen şartlar çerçevesinde silinmesini veya yok edilmesini isteme,
İşlemenin yalnızca otomatik sistemler ile analiz edilmesi durumunda itiraz etme,
Kişisel verilerinizin hukuka aykırı işlenmesi nedeniyle zarara uğramanız halinde tazminat talep etme.
''';

const String userAgreementContent = '''
Bu kullanıcı sözleşmesi Muallim ile kullanıcı Kullanıcı arasında, depo uygulaması üzerinden sunulan hizmetlerin kullanımına ilişkin şartları belirlemek amacıyla düzenlenmiştir.

1. Taraflar ve Konu
Bu Sözleşme, Kullanıcı'nın Platform'a erişimini, hizmetleri kullanmasını ve Şirket tarafından sağlanan içeriklerden faydalanmasını düzenler. Kullanıcı, Platform'a erişim sağladığında veya bir hesap oluşturduğunda, işbu Sözleşme’yi kabul etmiş sayılır.

2. Kullanım Koşulları

Kullanıcı, Platform'u yalnızca hukuka uygun amaçlarla kullanacağını taahhüt eder.
Platform üzerinden sağlanan içerikler, hizmetler ve yazılımlar, yalnızca Kullanıcı'nın kişisel kullanımı içindir.
Kullanıcı, Platform’daki herhangi bir içeriği veya hizmeti kötüye kullanamaz, üçüncü kişilerle izinsiz paylaşamaz ve ticari amaçla kullanamaz.
Kullanıcı, Platform'a kaydolurken sağladığı bilgilerin doğru, eksiksiz ve güncel olduğunu kabul eder.
3. Kişisel Verilerin Korunması
Kullanıcı, Muallim tarafından sunulan hizmetleri kullanırken Kişisel Verilerin Korunması Kanunu (KVKK)'na uygun olarak kişisel verilerinin işlenebileceğini, saklanabileceğini ve gerekli durumlarda yetkili mercilerle paylaşılabileceğini kabul eder. KVKK’ya ilişkin detaylar KVKK Aydınlatma Metni içerisinde yer almaktadır.

4. Fikri ve Sınai Mülkiyet Hakları

Platform'da yer alan tüm içerikler, yazılımlar, marka, logo ve diğer bileşenler Muallim'e aittir veya lisans altında kullanılmaktadır.
Kullanıcı, Platform’daki herhangi bir içeriği kopyalayamaz, değiştiremez, dağıtamaz veya yeniden yayımlayamaz.
5. Sorumluluk Reddi ve Garanti

Şirket, Platform'da sunulan hizmetlerin kesintisiz, hatasız veya kesintiye uğramayacağını garanti etmez.
Kullanıcı, hizmetlerin kullanımından doğabilecek olası zararlardan, veri kayıplarından veya sistem hatalarından Şirket'in sorumlu olmadığını kabul eder.
6. Sözleşme Değişiklikleri

Muallim, işbu Sözleşme’nin içeriğini her zaman değiştirme hakkını saklı tutar.
Kullanıcı, yapılan değişiklikleri takip etmekle yükümlüdür ve hizmetleri kullanmaya devam etmesi halinde güncellenen Sözleşme'yi kabul etmiş sayılır.
7. Sözleşmenin Feshi
Şirket, Kullanıcı’nın işbu Sözleşme'ye aykırı davranması halinde, Kullanıcı’nın Platform’a erişimini kısıtlama veya tamamen engelleme hakkına sahiptir.

8. Uygulanacak Hukuk ve Yetkili Mahkeme
İşbu Sözleşme Türkiye Cumhuriyeti yasalarına tabidir. Taraflar arasında doğabilecek herhangi bir uyuşmazlık durumunda, Kocaeli Mahkemeleri ve İcra Daireleri yetkili olacaktır.

9. Onay ve Yürürlük
Kullanıcı, işbu Sözleşme’yi dikkatlice okuduğunu, tüm hükümlerini anladığını ve onay verdiğini kabul ve beyan eder. Kullanıcı’nın Platform’a erişmesi ve hizmetleri kullanmaya devam etmesi, işbu Sözleşme’ye onay verdiği anlamına gelir.
''';

const String commercialMessageContent = '''
1. Onay Beyanı
Muallim, 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) ve 6563 sayılı Elektronik Ticaretin Düzenlenmesi Hakkında Kanun kapsamında, Kullanıcı'ya ticari elektronik iletiler gönderebilmek için açık rızasını talep etmektedir.

Kullanıcı, bu onay metnini kabul ederek Şirket tarafından kendisine SMS, e-posta, telefon araması, mobil bildirimler ve diğer dijital iletişim kanalları aracılığıyla ticari elektronik iletiler gönderilmesini kabul ettiğini beyan eder.

2. Ticari Elektronik İletilerin İçeriği
Kullanıcı, Şirket tarafından kendisine aşağıdaki konularda ticari elektronik ileti gönderilebileceğini kabul eder:

Kampanya, indirim ve özel fırsatlar hakkında bilgilendirme,
Yeni ürün ve hizmetler hakkında duyurular,
Müşteri memnuniyet anketleri ve özel teklifler,
Şirket’in etkinlikleri, haberleri ve duyuruları hakkında bilgilendirme.
3. Kişisel Verilerin İşlenmesi ve Saklanması
Kullanıcı'nın iletişim bilgileri, KVKK ve ilgili diğer mevzuat kapsamında korunmakta olup, yalnızca Kullanıcı'ya ticari ileti göndermek amacıyla işlenecektir. Detaylı bilgi için [Şirket'in KVKK Aydınlatma Metni] adresini ziyaret edebilirsiniz.

4. İletişim Tercihlerinin Yönetilmesi
Kullanıcı, dilediği zaman gelen ticari iletilerde yer alan "İLETİMİ DURDUR" bağlantısına tıklayarak veya müşteri hizmetleri ile iletişime geçerek ticari elektronik ileti almayı reddedebilir.

5. Yürürlük ve Onay
Kullanıcı, işbu onay metnini okuyup anladığını ve ticari elektronik ileti almayı açık rızasıyla kabul ettiğini beyan eder. Kullanıcı, Platform’a kayıt olurken veya herhangi bir iletişim kanalını kullanarak verdiği bu onayı, dilediği zaman iptal etme hakkına sahiptir.
''';