
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:animated_button/animated_button.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sub4sub_2023/config/warna.dart';
import 'package:sub4sub_2023/model/user_model.dart';
import 'package:sub4sub_2023/providers/setting_provider.dart';

import '../../config/url.dart';
import '../../config/void.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  GoogleSignInAccount? _currentUser;
  TextEditingController _email = TextEditingController();
  TextEditingController _password = TextEditingController();

  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
    ],
  );

  void _login() async {
    if(_email.text.isEmpty) return alertError(context, 'Email cannot be empty');
    if(_password.text.isEmpty) return alertError(context, 'Password cannot be empty');
    Dio dio = Dio();
    Map formData = {
      'email': _email.text,
      'password': _password.text,
      'signature': generateMd5('login${_email.text}${_password.text}')
    };
    Response response = await dio.post("$apiUrl/login",
      data: formData,
    );
    if(response.data['status']) {
      UserModel model = UserModel.fromMap(response.data['akun']);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('user', jsonEncode(model.toMap()));
      prefs.setBool('isLogin', true);
      prefs.setBool('with_google', false);
      context.goNamed('cek_login');
    }else{
      alertError(context, 'Incorrect email and password combination');
    }
  }

  _loginWithApple(UserCredential user) async {
    Dio dio = Dio();
    Map formData = {
      'email': user.user!.email,
      'nama': user.user!.displayName ?? user.user!.email,
      'avatar': "https://sub4sub.annora.id/img/logo.png",
      'signature': generateMd5('akun_with_google${user.user!.email}')
    };
    Response response = await dio.post("$apiUrl/akun_with_google",
      data: formData,
    );
    if(response.data['status']) {
      UserModel model = UserModel.fromMap(response.data['akun']);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('user', jsonEncode(model.toMap()));
      prefs.setBool('isLogin', true);
      prefs.setBool('with_google', true);
      context.goNamed('cek_login');
    }
  }

  _loginWithGoogle() async {
    Dio dio = Dio();
    Map formData = {
      'email': _currentUser!.email,
      'nama': _currentUser!.displayName,
      'avatar': _currentUser!.photoUrl,
      'signature': generateMd5('akun_with_google${_currentUser!.email}')
    };
    Response response = await dio.post("$apiUrl/akun_with_google",
      data: formData,
    );
    if(response.data['status']) {
      UserModel model = UserModel.fromMap(response.data['akun']);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('user', jsonEncode(model.toMap()));
      prefs.setBool('isLogin', true);
      prefs.setBool('with_google', true);
      context.goNamed('cek_login');
    }
  }

  Future<void> _handleSignIn() async {
    try {
      await googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  //----------------------------------------------------------------------------

  String generateNonce([int length = 32]) {
    final charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserCredential> signInWithApple() async {
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  //----------------------------------------------------------------------------

  @override
  void initState() {
    context.read<SettingProvider>().getData();
    super.initState();
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
        _loginWithGoogle();
      });
    });
    googleSignIn.signInSilently();
  }

  @override
  Widget build(BuildContext context) {
    final GoogleSignInAccount? user = _currentUser;
    return Scaffold(
      body: ListView(
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'logo',
                      child: SizedBox(
                          width: 300,
                          child: Image.asset('assets/img/icon/logo.png')),
                    ),
                    SizedBox(height: 10,),
                    Text('More like, view and subscribe for your channel', style: TextStyle(
                        color: textHitam,
                        fontWeight: FontWeight.bold,
                        height: 1
                    ),),
                    SizedBox(height: 50,),
                    TextField(
                      controller: _email,
                      decoration: InputDecoration(
                        label: Text('Email'),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)
                        ),
                        hintText: 'Email',
                      ),
                    ),
                    SizedBox(height: 10,),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(
                        label: Text('Password'),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)
                        ),
                        hintText: 'Password',
                      ),
                    ),
                    SizedBox(height: 10,),
                    AnimatedButton(
                      color: merah,
                      height: 60,
                      width: MediaQuery.of(context).size.width - 60,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Center(
                          child: Text('Sign In',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      onPressed: () {
                        _login();
                      },
                    ),
                    SizedBox(height: 10,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: (){
                            context.goNamed('signup');
                          },
                          child: Text('Sign up',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textHitam
                          ),),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Text('or', style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textHitam,
                        fontSize: 22
                      ),),
                    ),
                    Consumer<SettingProvider>(
                      builder: (context,data,_) {
                        return (data.setting.isDev > 0)
                            ? SizedBox()
                            : AnimatedButton(
                                color: hijau,
                                height: 60,
                                width: MediaQuery.of(context).size.width - 60,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                            width: 30,
                                            height: 30,
                                            child: Image.asset('assets/img/icon/google_putih.png')),
                                        const SizedBox(width: 10,),
                                        Text((user != null) ? 'Hi, ${user.displayName}' : 'Sign in with Google',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  if(user == null){
                                    _handleSignIn();
                                  }
                                },
                              );
                      }
                    ),
                    SizedBox(height: 10,),
                    if(Platform.isIOS) AnimatedButton(
                            color: Colors.black,
                            height: 60,
                            width: MediaQuery.of(context).size.width - 60,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: Image.asset('assets/img/icon/apple.png')),
                                    const SizedBox(width: 10,),
                                    Text('Sign in with Apple',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            onPressed: () async {
                              try{
                                UserCredential user = await signInWithApple();
                                _loginWithApple(user);
                              }catch(e){
                                print(e);
                              }
                            },
                          )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
