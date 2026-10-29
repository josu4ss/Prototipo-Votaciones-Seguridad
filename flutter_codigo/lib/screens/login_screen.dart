import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  final Future<void> Function(String,String) onLogin;
  const LoginScreen({super.key,required this.onLogin});
  @override State<LoginScreen> createState()=>_LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final email=TextEditingController(text:'socio1@example.com');
  final password=TextEditingController();
  final form=GlobalKey<FormState>();
  bool busy=false;
  bool obscure=true;
  String? error;
  @override void dispose(){email.dispose();password.dispose();super.dispose();}
  Future<void> _login() async {
    if(!(form.currentState?.validate()??false))return;
    setState((){busy=true;error=null;});
    try { await widget.onLogin(email.text,password.text); }
    catch(e){if(mounted)setState(()=>error=e.toString());}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context){
    return Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:460),child:Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Icon(Icons.how_to_vote_rounded,size:68,color:Color(0xFF126C6F)),
      const SizedBox(height:16),
      Text('Votación Segura',textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      const Text('Elección interna de la asociación',textAlign:TextAlign.center),
      const SizedBox(height:28),
      TextFormField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Correo registrado',prefixIcon:Icon(Icons.alternate_email)),validator:(x)=>(x==null||!x.contains('@'))?'Escribe un correo válido':null),
      const SizedBox(height:14),
      TextFormField(controller:password,obscureText:obscure,decoration:InputDecoration(labelText:'Contraseña',prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(onPressed:()=>setState(()=>obscure=!obscure),icon:Icon(obscure?Icons.visibility:Icons.visibility_off))),validator:(x)=>(x?.length??0)<8?'Mínimo 8 caracteres':null),
      if(error!=null)...[const SizedBox(height:14),Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error))],
      const SizedBox(height:22),
      FilledButton.icon(onPressed:busy?null:_login,icon:busy?const SizedBox(height:18,width:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.login),label:const Text('Iniciar sesión'),style:FilledButton.styleFrom(padding:const EdgeInsets.all(17))),
      const SizedBox(height:20),
      const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('PROTOTIPO ACADÉMICO: credenciales y datos ficticios. No utilizar en una elección real sin controles adicionales.',textAlign:TextAlign.center))),
    ])))))));
  }
}
