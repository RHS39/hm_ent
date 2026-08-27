import 'dart:convert';
import 'dart:io';
void main() async {
  final endpoint='https://cloud.appwrite.io/v1';
  final project='6a8c0d2c001da8c48b83';
  final key='standard_c7da4f715463badc08c741ca78b1ebccee037d8698ac391549d9d9d02772a87c8e332deb577c8e7af417b6847a568d299891bde5d3ce140d2193c3779a548aaf7eb5f282064c14dc6a2c7579eb83d599ac5a7645ea942c58058b22bc43f4e84b2ab9c7cbd5c95c4103d7d316b2ffa98cc3d75b5118c282c26b972e81c5c84322';
  final c=HttpClient();
  Future req(String m,String p,{Map? b}) async {
    final uri=Uri.parse(endpoint+p);
    final r=await c.openUrl(m, uri);
    r.headers.set('X-Appwrite-Project', project);
    r.headers.set('X-Appwrite-Key', key);
    r.headers.set('Content-Type','application/json; charset=utf-8');
    if(b!=null) {
      final bytes = utf8.encode(jsonEncode(b));
      r.headers.set('Content-Length', bytes.length.toString());
      r.add(bytes);
    }
    final resp=await r.close();
    final t=await resp.transform(utf8.decoder).join();
    return {'code':resp.statusCode,'body':t};
  }
  // Check existing
  var res = await req('GET','/databases/hari_om_db/collections/products/documents');
  print('Existing check: ${res['code']} ${res['body'].toString().substring(0, res['body'].toString().length < 500 ? res['body'].toString().length : 500)}');
  try{
    final j=jsonDecode(res['body']);
    if(j['total']>0){
      print('Already ${j['total']} products, skipping seed. Documents:');
      for(var d in j['documents']){
        print(' - ${d['product_id']}: ${d['name']}');
      }
      c.close(); return;
    }
  }catch(_){}
  final demo = [
    {'product_id':'01','name':'Chocolaty Gud 700g','price':299.0,'description':'100% Natural • Unrefined • No Added Ingredients – Premium chocolaty jaggery chunks in glass jar by Hari Om Traders','icon':'grain','category':'Powder','stock_quantity':300,'moq':2,'image_url':'assets/img/products/gud_700g.png','is_active':true},
    {'product_id':'02','name':'Organic Jaggery Cubes 1kg','price':229.0,'description':'Traditional hand-cut cubes, rich iron & minerals','icon':'spa','category':'Cubes','stock_quantity':250,'moq':2,'image_url':'assets/img/products/organic-jaggery-cubes-1kg.png','is_active':true},
    {'product_id':'03','name':'Organic Liquid Jaggery Kakvi 500ml','price':349.0,'description':'Thick liquid jaggery (kakvi) – natural sweetener for tea & desserts','icon':'water_drop','category':'Liquid','stock_quantity':180,'moq':2,'image_url':'assets/img/products/organic-liquid-jaggery-kakvi-500ml.jpg','is_active':true},
    {'product_id':'04','name':'Organic Jaggery with Ginger 250g','price':249.0,'description':'Infused with sun-dried ginger – warming & digestive','icon':'eco','category':'Flavored','stock_quantity':200,'moq':2,'image_url':'assets/img/products/organic-jaggery-ginger-250g.png','is_active':true},
    {'product_id':'05','name':'Organic Jaggery with Moringa 250g','price':279.0,'description':'Enriched with moringa leaf powder – superfood blend','icon':'local_florist','category':'Flavored','stock_quantity':150,'moq':2,'image_url':'assets/img/products/organic-jaggery-moringa-250g.jpg','is_active':true},
    {'product_id':'06','name':'Organic Jaggery with Turmeric 250g','price':269.0,'description':'Golden turmeric blend – immunity boosting','icon':'spa','category':'Flavored','stock_quantity':170,'moq':2,'image_url':'assets/img/products/organic-jaggery-turmeric-250g.png','is_active':true},
    {'product_id':'07','name':'Organic Jaggery Block 1kg','price':249.0,'description':'Traditional solid block – directly from wood-pressed cane juice','icon':'square','category':'Block','stock_quantity':220,'moq':2,'image_url':'assets/img/products/organic-jaggery-block-1kg.png','is_active':true},
    {'product_id':'08','name':'Organic Granular Jaggery 1kg','price':229.0,'description':'Free-flowing granular – easy to spoon & dissolve','icon':'grain','category':'Granular','stock_quantity':260,'moq':2,'image_url':'assets/img/products/organic-granular-jaggery-1kg.png','is_active':true},
    {'product_id':'09','name':'Organic Jaggery Peanut Chikki 200g','price':179.0,'description':'Crunchy peanut brittle bound with organic jaggery','icon':'cookie','category':'Chikki','stock_quantity':400,'moq':2,'image_url':'assets/img/products/organic-jaggery-peanut-chikki-200g.png','is_active':true},
    {'product_id':'10','name':'Organic Jaggery Sesame Chikki 200g','price':189.0,'description':'Roasted sesame & jaggery – calcium rich','icon':'cookie','category':'Chikki','stock_quantity':380,'moq':2,'image_url':'assets/img/products/organic-jaggery-sesame-chikki-200g.jpg','is_active':true},
    {'product_id':'11','name':'Organic Jaggery Coconut Chikki 200g','price':199.0,'description':'Coconut flakes with jaggery – tropical treat','icon':'cookie','category':'Chikki','stock_quantity':350,'moq':2,'image_url':'assets/img/products/organic-jaggery-coconut-chikki-200g.png','is_active':true},
    {'product_id':'12','name':'Organic Jaggery Tea Blend 100g','price':299.0,'description':'Jaggery powder blended for chai – dissolves instantly','icon':'local_cafe','category':'Blend','stock_quantity':300,'moq':1,'image_url':'assets/img/products/organic-jaggery-tea-blend-100g.jpg','is_active':true},
    {'product_id':'13','name':'Organic Jaggery Syrup 500ml','price':329.0,'description':'Pourable syrup – perfect for pancakes & porridge','icon':'water_drop','category':'Syrup','stock_quantity':160,'moq':1,'image_url':'assets/img/products/organic-jaggery-syrup-500ml.png','is_active':true},
    {'product_id':'14','name':'Organic Jaggery with Cardamom 250g','price':289.0,'description':'Aromatic cardamom infusion – premium aroma','icon':'eco','category':'Flavored','stock_quantity':140,'moq':2,'image_url':'assets/img/products/organic-jaggery-cardamom-250g.png','is_active':true},
    {'product_id':'15','name':'Organic Jaggery Gift Hamper 1.5kg','price':899.0,'description':'Assorted hamper – powder, cubes, chikkis & syrup – festive gift','icon':'card_giftcard','category':'Hamper','stock_quantity':90,'moq':1,'image_url':'assets/img/products/organic-jaggery-gift-hamper-1-5kg.jpg','is_active':true},
  ];
  int ok=0;
  for(final p in demo){
    final r=await req('POST','/databases/hari_om_db/collections/products/documents', b:{'documentId':'unique()','data':p, 'permissions':['read(\"any\")']});
    if(r['code']==201){ ok++; print('✓ ${p['product_id']} ${p['name']}'); } else { print('✗ ${p['product_id']} -> ${r['code']}: ${r['body']}'); }
    await Future.delayed(Duration(milliseconds:300));
  }
  print('Seeded $ok / ${demo.length}');
  // verify
  var v=await req('GET','/databases/hari_om_db/collections/products/documents');
  print(v['body'].toString().substring(0, v['body'].toString().length < 800 ? v['body'].toString().length : 800));
  c.close();
}
