import 'package:flutter/material.dart';
import "package:first_app/gradient_container.dart";

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: GradientContainer(
            Color.fromARGB(255, 20, 2, 61), Color.fromARGB(255, 213, 92, 83)),
      ),
    ),
  );
}
