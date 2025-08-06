import 'package:flutter/material.dart';
import 'package:rental_house_taxation_flutter/screens/citizen_profile_page.dart';
import 'package:rental_house_taxation_flutter/screens/compliance_page.dart';
import 'package:rental_house_taxation_flutter/screens/home.dart';
import 'package:rental_house_taxation_flutter/screens/transactions_page.dart';


class BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  final String userName;
  final String taxAmount;
  final String authToken;
  final String citizenId;

  const BottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
    required this.userName,
    required this.taxAmount,
    required this.authToken,
    required this.citizenId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color navBg = const Color.fromARGB(255, 18, 20, 68);

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: navBg,
      child: SafeArea(
        child: SizedBox(
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, Icons.home, 'Home', 0, selectedIndex, onTap),
              _buildNavItem(context, Icons.list_alt, 'Transactions', 1, selectedIndex, onTap),
              const SizedBox(width: 40), // For the FAB gap
              _buildNavItem(context, Icons.document_scanner, 'Compliance', 3, selectedIndex, onTap),
              _buildNavItem(context, Icons.person, 'Profile', 4, selectedIndex, onTap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    int selectedIndex,
    ValueChanged<int> onTap,
  ) {
    final bool isSelected = selectedIndex == index;

    IconData displayedIcon;
    if (label == 'Home') {
      displayedIcon = isSelected ? Icons.home : Icons.home_outlined;
    } else if (label == 'Transactions') {
      displayedIcon = isSelected ? Icons.list_alt : Icons.list_alt_outlined;
    } else if (label == 'Compliance') {
      displayedIcon = isSelected ? Icons.document_scanner : Icons.document_scanner_outlined;
    } else if (label == 'Profile') {
      displayedIcon = isSelected ? Icons.person : Icons.person_outline;
    } else {
      displayedIcon = icon;
    }

    return GestureDetector(
      onTap: () {
        onTap(index);

        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  userName: userName,
                 
                  authToken: authToken,
                  citizenId: citizenId,
                ),
              ),
            );
            break;
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionsPage(citizenId: citizenId,),
              ),
            );            
            break;
          case 3:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CompliancePage()),
            );
            break;
          case 4:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(citizenId: citizenId, authToken: authToken,),
              ),
            );
            break;
           

        }
      },
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              displayedIcon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color.fromARGB(240, 233, 230, 230),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
