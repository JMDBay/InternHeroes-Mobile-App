import 'package:InternHeroes/features/user_auth/presentation/pages/asdfasdf.dart';

import 'package:InternHeroes/features/user_auth/presentation/pages/knowledgeresourcepage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/login_page.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/sign_up_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBSviAfXdUfHWwjRXlP1BG9l_wWnQ0GtqM",
        appId: "1:679588831210:android:1a2400ed3b64f9091fdc93",
        messagingSenderId: "679588831210",
        projectId: "internheroes-49040",
        // Your web Firebase config options
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Create a custom MaterialColor from white
    MaterialColor whiteSwatch = MaterialColor(
      0xFFFFFFFF, // This value represents white
      <int, Color>{
        50: Colors.white,
        100: Colors.white,
        200: Colors.white,
        300: Colors.white,
        400: Colors.white,
        500: Colors.white,
        600: Colors.white,
        700: Colors.white,
        800: Colors.white,
        900: Colors.white,
      },
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InternHeroes',
      theme: ThemeData(
        primarySwatch: whiteSwatch, // Set primary swatch to white
        backgroundColor: Colors.white, // Set background color
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: whiteSwatch, // Set primary swatch to white
          backgroundColor: Colors.white, // Set background color
        ).copyWith(
          primary: Colors.yellow[800], // Set primary color
        ),
      ),
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginPage(),
        '/signUp': (context) => SignUpPage(),
        '/additional_information': (context) => AdditionalInformationPage(),
        '/home': (context) => ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid), // Route to your ProfileScreen
        '/knowledge_resource': (context) => KnowledgeResource(),
      },
    );
  }
}


class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return ProfileScreen(uid: user.uid);
    } else {
      return LoginPage();
    }
  }
}
