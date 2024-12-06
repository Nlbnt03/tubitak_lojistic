import 'package:flutter/material.dart';
import 'package:lojistik/add_item_name.dart';
import 'package:lojistik/listed_product.dart';

class AddedSucces extends StatelessWidget {
  const AddedSucces({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back),onPressed: (){
          Navigator.pop(context);
        },),
        title: const Text("İsim İle Ürün Yükle"),
        centerTitle: true,
      ),
      body:Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("images/success.png"),
          SizedBox(
            width: 343,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
              ),
                onPressed: (){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ListedProduct(),));
                },
                child: Text("Ürün Listesine Git",style: TextStyle(color: Colors.black,fontSize: 17),)
            ),
          ),
          const SizedBox(height: 10,),
          SizedBox(
            width: 343,
            height: 45,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                onPressed: (){
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AddItemName(),));
                },
                child: Text("Yeni Ürün Yükle",style: TextStyle(color : Colors.black,fontSize: 17),)
            ),
          ),
        ],
      ),
    );
  }
}
