import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hm_ent/pages/about_us_page.dart';
void main(){
  for(final s in [const Size(280,653),const Size(360,740),const Size(1280,800)]){
    testWidgets('AboutUs $s', (tester) async{
      tester.view.physicalSize=s;
      tester.view.devicePixelRatio=1;
      addTearDown((){
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final errs=<FlutterErrorDetails>[];
      final old=FlutterError.onError;
      FlutterError.onError=(d){ if(d.toString().contains('overflowed')) errs.add(d); };
      addTearDown(()=>FlutterError.onError=old);
      await tester.pumpWidget(const MaterialApp(home:Scaffold(body:AboutUsContent())));
      await tester.pump(const Duration(milliseconds:300));
      FlutterError.onError=old;
      expect(errs,isEmpty, reason:'overflow at $s');
      expect(find.textContaining('Rahul Kumar Singh', findRichText:true), findsWidgets);
      expect(find.textContaining('Proprietor', findRichText:true), findsWidgets);
      expect(find.textContaining('FSSAI Licensed', findRichText:true), findsWidgets);
      expect(find.textContaining('Farmer First', findRichText:true), findsWidgets);
      expect(find.textContaining('Started at Pure', findRichText:true), findsWidgets);
    });
  }
}
