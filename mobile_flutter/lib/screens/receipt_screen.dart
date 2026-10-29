import 'package:flutter/material.dart';
class ReceiptScreen extends StatelessWidget {
  final String receipt;
  const ReceiptScreen({super.key,required this.receipt});
  @override Widget build(BuildContext context){
    return Scaffold(appBar:AppBar(title:const Text('Comprobante de participación')),
      body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:480),child:ListView(padding:const EdgeInsets.all(24),children:[
        const Icon(Icons.verified_outlined,size:80,color:Color(0xFF126C6F)),
        const SizedBox(height:20),
        Text('Tu participación fue registrada',textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height:20),
        SelectableText(receipt,textAlign:TextAlign.center,style:const TextStyle(fontSize:16,fontWeight:FontWeight.bold)),
        const SizedBox(height:16),
        const Text('Este código confirma la participación, pero NO indica la candidatura seleccionada. Guárdalo para eventuales reclamos.',textAlign:TextAlign.center),
        const SizedBox(height:24),
        FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('Volver a la elección')),
      ]))));
  }
}
