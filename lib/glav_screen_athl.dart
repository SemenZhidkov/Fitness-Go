// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:fitnessgo/calendar_screen.dart';
import 'package:fitnessgo/chats_screen.dart';
import 'package:fitnessgo/createpost_screen.dart';
import 'package:fitnessgo/glav_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fitnessgo/training_screen.dart';
import 'package:fitnessgo/myprofile_screen.dart';
import 'package:fitnessgo/notify_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:theme_provider/theme_provider.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';





class AthleteProfileScreen extends StatefulWidget {
  @override
  _AthleteProfileScreenState createState() => _AthleteProfileScreenState();

}

class _AthleteProfileScreenState extends State<AthleteProfileScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
   ChatScreen(),
    ScheduleScreen(),
    MainMenuScreen(),
    UserWorkoutScreen(),
    ProfileScreen(),
  ];

  static List<String> _appBarTitles = [
    'Чаты',
    'Расписание',
    'Главная',
    'Тренировки',
    'Профиль'
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  AppBar _buildAppBar() {
    String title = _appBarTitles[_selectedIndex];

    List<Widget> actions = [];

    if (_selectedIndex == 0) {
      actions.add(
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () {
            // Add your notification action here
          },
        ),
      );
    } else if (_selectedIndex == 1) {
      
      actions.add(
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () {
            // Add your notification action here
          },
        ),
      );
    } else if (_selectedIndex == 2) {
      actions.add(
        IconButton(
          icon: Icon(Icons.create),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreatePostScreen()),
            );
          },
        ),
      );
      actions.add(
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () {
            // Add your notification action here
          },
        ),
      );
    } else if (_selectedIndex == 3) {
      
      actions.add(
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () {
            // Add your notification action here
          },
        ),
      );
    } else if (_selectedIndex == 4) {
      actions.add(
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {
           Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsScreen()),
           );
          },
        ),
      );
    }

    return AppBar(
      title: Text(title),
      actions: actions,
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    var backgroundColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;

    return Scaffold(
      appBar: _buildAppBar(),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items:  <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/Chat.svg', width: 34,),
            label: 'Чаты',
            backgroundColor: backgroundColor,
            
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/Calendar.svg', width: 34,),
            label: 'календарь',
            backgroundColor: backgroundColor,
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/logo.svg', width: 34,),
            label: 'Главная',
            backgroundColor:backgroundColor,
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/Weight.svg', width: 34,),
            label: 'Тренировки',
            backgroundColor:backgroundColor,
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/3User.svg', width: 34,),
            label: 'Личное',
            backgroundColor: backgroundColor,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: textColor,
        onTap: _onItemTapped,
      ),
    );
  }
}


