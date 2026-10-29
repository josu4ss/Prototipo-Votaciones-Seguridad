import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/election.dart';
import 'receipt_screen.dart';
import 'results_screen.dart';

class ElectionScreen extends StatefulWidget {
  final ApiClient api;
  final String role;
  final Future<void> Function() onLogout;
  const ElectionScreen({super.key,required this.api,required this.role,required this.onLogout});
  @override State<ElectionScreen> createState()=>_ElectionScreenState();
}
class _ElectionScreenState extends State<ElectionScreen> {
  ElectionData? election;
  String? error;
  bool busy=false;
  Candidate? selected;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    try{final e=await widget.api.election();if(mounted)setState((){election=e;selected=null;error=null;});}
    catch(ex){if(mounted)setState(()=>error=ex.toString());}
  }
  Future<void> _vote() async {
    final c=selected;
    if(c==null||busy)return;
    final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Confirmar voto'),
      content:const Text('Confirma que deseas enviar tu selección. Después de registrar el voto no podrás cambiarlo.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Emitir voto'))],
    ));
    if(confirmed!=true||!mounted)return;
    setState(()=>busy=true);
    try{
      final receipt=await widget.api.vote(c.id);
      if(!mounted)return;
      await Navigator.push(context,MaterialPageRoute(builder:(_)=>ReceiptScreen(receipt:receipt)));
      await _load();
    }catch(ex){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(ex.toString())));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> _close() async {
    final confirmed=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Cerrar elección'),
      content:const Text('Esta acción es irreversible en la demostración. ¿Deseas cerrar y publicar los resultados?'),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Cerrar'))],
    ));
    if(confirmed!=true||!mounted)return;
    setState(()=>busy=true);
    try{await widget.api.close();await _load();}
    catch(ex){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(ex.toString())));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context){
    final e=election;
    return Scaffold(
      appBar:AppBar(title:const Text('Elección de directiva'),actions:[IconButton(tooltip:'Cerrar sesión',onPressed:widget.onLogout,icon:const Icon(Icons.logout))]),
      body: e==null ? Center(child:error==null?const CircularProgressIndicator():Column(mainAxisSize:MainAxisSize.min,children:[Text(error!),TextButton(onPressed:_load,child:const Text('Reintentar'))]))
      :RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.all(18),children:[
        Text(e.title,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w700)),
        const SizedBox(height:12),
        Card(color:e.status=='OPEN'?const Color(0xFFE0F3EF):const Color(0xFFFFF0D7),child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[
          Icon(e.status=='OPEN'?Icons.lock_open:Icons.lock_outline),const SizedBox(width:12),
          Expanded(child:Text(e.status=='OPEN'?'Jornada abierta':'Jornada cerrada',style:const TextStyle(fontWeight:FontWeight.bold))),
        ]))),
        const SizedBox(height:14),
        Text('Candidaturas',style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:8),
        ...e.candidates.map((c)=>Card(child:RadioListTile<String>(
          title:Text(c.name,style:const TextStyle(fontWeight:FontWeight.w600)),
          subtitle:Text(c.proposal),value:c.id,
          groupValue:selected?.id,
          onChanged:e.status=='OPEN'&&!e.alreadyVoted&&widget.role=='VOTER'&&!busy ? (x)=>setState(()=>selected=c) : null,
        ))),
        const SizedBox(height:12),
        if(e.alreadyVoted)...[
          const Card(child:ListTile(leading:Icon(Icons.verified,color:Color(0xFF126C6F)),title:Text('Ya participaste'),subtitle:Text('No se permite emitir un segundo voto.'))),
          if(e.receipt!=null)OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ReceiptScreen(receipt:e.receipt!))),icon:const Icon(Icons.receipt_long),label:const Text('Ver comprobante')),
        ]else if(e.status=='OPEN'&&widget.role=='VOTER')
          FilledButton.icon(onPressed:selected==null||busy?null:_vote,icon:const Icon(Icons.how_to_vote),label:Text(busy?'Procesando...':'Confirmar y votar'),style:FilledButton.styleFrom(padding:const EdgeInsets.all(17)))
        else const Text('La emisión del voto no está disponible para esta cuenta o jornada.'),
        const SizedBox(height:12),
        OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ResultsScreen(api:widget.api))),icon:const Icon(Icons.bar_chart),label:const Text('Consultar resultados')),
        if(widget.role=='ADMIN'&&e.status=='OPEN')...[
          const SizedBox(height:12),
          OutlinedButton.icon(onPressed:busy?null:_close,icon:const Icon(Icons.lock),label:const Text('Cerrar elección (administrador)')),
        ],
        const SizedBox(height:24),
        const Text('Prototipo académico. No ofrece verificación criptográfica extremo a extremo.',textAlign:TextAlign.center,style:TextStyle(color:Colors.black54)),
        const SizedBox(height:22),
      ])),
    );
  }
}
