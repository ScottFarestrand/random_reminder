import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/data.dart';
import '../constants/globals.dart';
import '../models/relationship_model.dart';

class Person extends StatefulWidget {
  static const id = "Person";
  final Data data;
  // const Person({Key? key}) : super(key: key);
  const Person({Key? key, required this.data}) : super(key: key);


  @override
  State<Person> createState() => _PersonState();
}

class _PersonState extends State<Person> {
  @override
  Widget build(BuildContext context) {
    if (widget.data.docID != "") {
      FirebaseFirestore.instance.collection('Relationships').
      doc(widget.data.docID).
      get().
      then((DocumentSnapshot documentSnapshot) {
          if (documentSnapshot.exists) {
            print('Document exists on the database');
            print(documentSnapshot.data());
            final ln = documentSnapshot.get(gLastName);
            print(ln);
            Relationship relationship = Relationship(
                firstName: documentSnapshot.get(gFirstName) ,
                lastName: documentSnapshot.get(gLastName),
                anniversaryType: documentSnapshot.get(gAnniversaryType),
                randomReminders: documentSnapshot.get(gRandomReminders),
                relationshipType: documentSnapshot.get(gRelationshipType),
                userId: documentSnapshot.get(gUserId),
                docId: documentSnapshot.id );
            print(relationship.docId);
            print(relationship.firstName);

            // Map<String, dynamic>? data = documentSnapshot.data();
            // snapshot.docs.map((doc) => Relationship.fromJson(doc.id, doc.data()))
            // Relationship relationship = map(Relationship.fromJson(widget.data.docID, documentSnapshot.data()));
            // Relationship relationship = Relationship.fromJson(widget.data.docID, documentSnapshot.data());
            // print(relationship.lastName);
            // print(data);
          }
          else
            {
              print("Doc Does not exist");
            }
    });


    }
    // if (widget.LastName != "") {
    print("HI");
    print(widget.data.docID);
      return MaterialApp(
        title: "Edit Relationship",
        home: Scaffold(
          appBar: AppBar(title: Text("Edit Relationship")),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(child: Column(children: [
              Text('HI'),
              Text("Hello"),
              Text(widget.data.docID!),
              IconButton(
                        icon:   Icon(Icons.exit_to_app),
                        onPressed: () {
                          {
                            print("Pop ME");
                            Navigator.pop(context);
                          }},
                      ),
            ],

            ),),
          ),
        ),


      );
      // return Scaffold(body: Container(child: Column(
    //     children: [
    //       Text(widget.data.docID!),
    //       // Text(widget.data.docID.toString()),
    //       IconButton(
    //         icon:   Icon(Icons.back_hand),
    //         onPressed: () {
    //           {
    //             print("Pop ME");
    //             Navigator.pop(context);
    //           }},
    //       ),
    //     ],
    //   ),),);
    //
    // // }
    // // return Scaffold(body: Container(child: Text("New Person"),),);
  }
}
