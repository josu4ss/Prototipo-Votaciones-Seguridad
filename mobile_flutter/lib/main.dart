import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'core/session_store.dart';
import 'screens/login_screen.dart';
import 'screens/election_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VotingApp());
}

class VotingApp extends StatelessWidget {
  const VotingApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:'Votación Segura',debugShowCheckedModeBanner:false,
      theme:ThemeData(
        useMaterial3:true,
        colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF126C6F)),
        scaffoldBackgroundColor:const Color(0xFFF6FAFB),
        appBarTheme:const AppBarTheme(backgroundColor:Color(0xFFF6FAFB)),
        inputDecorationTheme:InputDecorationTheme(
          filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14)),
        ),
      ),
      home:const SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});
  @override
  State<SessionGate> createState()=>_SessionGateState();
}
class _SessionGateState extends State<SessionGate> {
  final SessionStore store=SessionStore();
  late final ApiClient api=ApiClient(store);
  bool loading=true;
  String? role;
  @override void initState(){super.initState();_restore();}
  Future<void> _restore() async {
    final token=await store.token;
    final savedRole=await store.role;
    if(!mounted)return;
    setState((){role=token==null?null:savedRole;loading=false;});
  }
  Future<void> _login(String email,String password) async {
    final nextRole=await api.login(email,password);
    if(mounted)setState(()=>role=nextRole);
  }
  Future<void> _logout() async {
    await store.clear();
    if(mounted)setState(()=>role=null);
  }
  @override void dispose(){api.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    return role==null ? LoginScreen(onLogin:_login) : ElectionScreen(api:api,role:role!,onLogout:_logout);
  }
}
