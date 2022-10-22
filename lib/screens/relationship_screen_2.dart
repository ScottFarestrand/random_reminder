// import 'dart:js';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/relationship_model.dart';
// import '../screens/person.dart';
// import '../services/navigation.dart';
class Relationships_Screen_2 extends StatelessWidget {
  static const id = "Relationships_Screen";

  const Relationships_Screen_2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

  int curIndex = 0;

    print("Building Container");
    if (curIndex == 0 ) {
      return Scaffold(body: Container(
        child: StreamBuilder<List<Relationship>>(
            stream: readRelationships(context),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              } else if (snapshot.hasData) {
                final relationships = snapshot.data!;
                return ListView(
                  children: relationships.map(buildRelationship).toList(),);
              } else {
                print(snapshot.error.toString());
                return Center(child: CircularProgressIndicator());
              }
            }),
      ),
      );
    } else {
      return Scaffold(body: Container(child: Text("you Pressed a button"),),);
    }
    }

  Widget buildRelationship( Relationship relationship) => ListTile(
    leading: Text(relationship.firstName),
    title: Text(relationship.lastName),
    subtitle: Text('WOW'),
    onTap: (){
      print(relationship.lastName);



      },
  );
  Stream<List<Relationship>> readRelationships(context) =>
      FirebaseFirestore.instance.
      collection('Relationships').
      snapshots().
      map((snapshot) =>
          snapshot.docs.map((doc) => Relationship.fromJson(doc.id, doc.data())).toList());

}
