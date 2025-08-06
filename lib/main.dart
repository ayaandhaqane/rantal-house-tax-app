import 'package:flutter/material.dart';
// import 'package:rental_house_taxation_flutter/screens/home.dart';
import 'package:rental_house_taxation_flutter/screens/singin.dart';
// import 'package:rental_house_taxation_flutter/screens/payment.dart';
// import 'package:rental_house_taxation_flutter/screens/splash_screen.dart';

void main() {
  runApp ( MaterialApp(
      title: 'Rental House Taxation',
      debugShowCheckedModeBanner: false,
      // theme: ThemeData(
      //   primarySwatch: Colors.blue,
      // ),
      home: const SignInScreen(),
    ),
    );
}
