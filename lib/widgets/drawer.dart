import 'package:flutter/material.dart';
import '../screens/personal_info_screen.dart';
// import '../services/navigation.dart';

class NavDrawer extends StatelessWidget {

  const NavDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Build Drawer');
    return Drawer(
      child: Material(
        color: Color.fromRGBO(50, 75, 205, 1),
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 40),
            buildMenuItem(
                icon: Icons.people,
                text: 'Relationships',
                onClicked: () => selectedItem(context, 0),
            ),
            buildMenuItem(
                text: 'My Profile',
                icon: Icons.person,
                onClicked: () => selectedItem(context, 1),
            ),
            const SizedBox(height: 6),
            Divider(color: Colors.white70,),
            const SizedBox(height: 6),
            buildMenuItem(
                text: "Log out",
                icon: Icons.logout,
                // onClicked: selectedItem(context, 2),
                onClicked: () => selectedItem(context, 2),
            ),
        ],),
      ),

    );
  }
  Widget buildMenuItem({
    required String text,
    required IconData icon,
    VoidCallback? onClicked,
  }
  ){
    final color  = Colors.white;
    final hoverColor = Colors.white70;
    return ListTile(
    leading: Icon(icon, color: color),
    title: Text(text, style: TextStyle(color: color),),
    hoverColor: hoverColor,
    onTap: onClicked,
    );
  }
  void selectedItem(BuildContext context, int index){
    print("Something happened");
    switch (index) {
      case 0:
        print("0");
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => PersonalInfoScreen()));
        break;
      case 1:
        print("1");

        break;
      case 2:
        print("2");
        break;

    }
  }
}
