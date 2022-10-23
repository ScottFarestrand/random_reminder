
// import 'dart:js';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/relationship_model.dart';
import '../screens/person.dart';
import '../services/navigation.dart';
import '../models/data.dart';
class Relationships_Screen extends StatelessWidget {
  static const id = "Relationships_Screen";
  Function? Doit2(){

    print("2");
  }

  Relationships_Screen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Function? DoIt(String id) {
    //   print('I am here');
    //   // Navigator.pushNamed(context, Person());
    // }

    int curIndex = 0;

    print("Building Container");
    final user = FirebaseAuth.instance.currentUser;
    print(user!.uid.toString());

    if (curIndex == 0 ) {
      return Scaffold(body: Container(
        child: StreamBuilder<List<Relationship>>(
            stream: readRelationships(context),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              } else if (snapshot.hasData) {
                final relationships = snapshot.data!;
                return ListView.separated(
                    itemBuilder: (BuildContext context, int index) {
                      Relationship relationship = relationships[index];
                      print(relationship.firstName);
                      return ListTile(
                        leading: Text(relationship.firstName),
                        title: Text(relationship.firstName),
                        subtitle: Text(relationship.relationshipType),

                        onTap: (){
                          final data = Data(docID: relationship.docId);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Person(
                              data:  data,
                            )),
                          );
                        }
                      );
                    },
                    separatorBuilder: (context, index) => Divider(color: Colors.black),
                    itemCount: relationships.length);

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
    subtitle: Text(relationship.docId),
    onTap: (){
      print(relationship.docId);
      print('called');

    },
    // subtitle: Text('ugh'),
    // onTap: DoIt(relationship.docId),
  );


  Stream<List<Relationship>> readRelationships( context) =>
      FirebaseFirestore.instance.
      collection('Relationships').
      where('userid', isEqualTo: FirebaseAuth.instance.currentUser!.uid).
      snapshots().
      map((snapshot) =>
          // snapshot.docs.map((doc) => Relationship.fromJson(doc.id, doc.data())).toList());
          snapshot.docs.map((doc) => Relationship.fromJson(doc.id, doc.data())).toList());
}