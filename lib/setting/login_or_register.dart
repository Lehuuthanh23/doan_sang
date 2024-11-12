import 'package:game_do_vui/screen/login.dart';
import 'package:game_do_vui/screen/register.dart';
import 'package:flutter/src/widgets/framework.dart';

class Logon_or_register extends StatefulWidget {
  const Logon_or_register({super.key});

  @override
  State<Logon_or_register> createState() => _Logon_or_registerState();
}

class _Logon_or_registerState extends State<Logon_or_register> {
  bool showLogin= true;

  void togglePage(){
    setState(() {
       showLogin = !showLogin;
    });
   
  }
  @override
  Widget build(BuildContext context) {
    if(showLogin){
      return Login(onTap:  togglePage,);
    }else{
      return Register(onTap: togglePage,);
    }
  }
}