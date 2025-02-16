import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Uygulama Hakkında'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uygulama Hakkında',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Bu uygulama, lojistik süreçlerini yönetmek ve takip etmek amacıyla geliştirilmiştir. '
                    'Uygulama, ürünlerin barkod ile takibini, stok yönetimini ve depo konumlarını kolayca yönetmenizi sağlar.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Uygulama Amacı',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Bu uygulama, lojistik süreçlerini daha verimli hale getirmek ve kullanıcıların ürünlerini kolayca yönetmelerini sağlamak amacıyla geliştirilmiştir. '
                    'Uygulama, kullanıcı dostu arayüzü ve gelişmiş özellikleri ile lojistik yönetimini kolaylaştırır.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Özellikler',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '- Barkod ile ürün takibi\n'
                    '- Stok yönetimi\n'
                    '- Depo konum yönetimi\n'
                    '- Ürün bilgilerini güncelleme ve düzenleme\n'
                    '- Kullanıcı dostu arayüz',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Teşekkürler',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Bu uygulamayı kullandığınız için teşekkür ederiz. Herhangi bir geri bildirim veya öneriniz varsa, lütfen bizimle iletişime geçin.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}