import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/election.dart';
class ResultsScreen extends StatefulWidget {
  final ApiClient api;
  const ResultsScreen({super.key,required this.api});
  @override State<ResultsScreen> createState()=>_ResultsScreenState();
}
class _ResultsScreenState extends State<ResultsScreen> {
  ResultsData? results;
  String? error;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {try{final r=await widget.api.results();if(mounted)setState(()=>results=r);}catch(e){if(mounted)setState(()=>error=e.toString());}}
  @override Widget build(BuildContext context){
    return Scaffold(appBar:AppBar(title:const Text('Resultados oficiales')),
      body:results==null?(error==null?const Center(child:CircularProgressIndicator()):Center(child:Padding(padding:const EdgeInsets.all(28),child:Text(error!,textAlign:TextAlign.center))))
      :ListView(padding:const EdgeInsets.all(20),children:[
        Text(results!.election,style:Theme.of(context).textTheme.titleLarge),
        const SizedBox(height:12),
        const Text('Publicados después del cierre. No se muestran participaciones individuales.'),
        const SizedBox(height:20),
        ...results!.rows.map((r)=>Card(child:ListTile(title:Text(r.name),trailing:Text('${r.votes} votos',style:const TextStyle(fontWeight:FontWeight.bold))))),
        const SizedBox(height:10),
        Text('Total: ${results!.rows.fold<int>(0,(n,x)=>n+x.votes)} votos'),
      ]));
  }
}
