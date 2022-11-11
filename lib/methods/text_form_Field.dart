import 'package:flutter/material.dart';
TextFormField buildTextFormField(TextEditingController tec, String lbl) {
  return TextFormField(
      controller: tec,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: lbl,
        labelStyle: TextStyle(fontStyle: FontStyle.italic),
      ),
      style: TextStyle(fontSize: 20),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter /$lbl";
        }
        return null;
      }
  );
}
