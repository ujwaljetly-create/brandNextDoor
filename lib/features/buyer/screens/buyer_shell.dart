import 'package:flutter/material.dart';

class BuyerShell extends StatefulWidget {
  const BuyerShell({super.key});

  @override
  State<BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends State<BuyerShell> {
  int index = 0;

  final screens = [
    Center(child: Text("Home")),
    Center(child: Text("Explore")),
    Center(child: Text("Orders")),
    Center(child: Text("Messages")),
    Center(child: Text("Profile")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() {
            index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: "Explore",
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag),
            label: "Orders",
          ),
          NavigationDestination(
            icon: Icon(Icons.chat),
            label: "Messages",
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}