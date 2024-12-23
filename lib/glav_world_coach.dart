import 'package:fitnessgo/TrainersList_screen.dart';
import 'package:fitnessgo/createpost_screen.dart';
import 'package:fitnessgo/dating_screen.dart';
import 'package:fitnessgo/requests_screen.dart';
import 'package:fitnessgo/view_courses_screen.dart';
import 'package:fitnessgo/mentees_screen.dart'; // Импортируем экран подопечных
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoachMainMenuScreen extends StatefulWidget {
  @override
  _CoachMainMenuScreenState createState() => _CoachMainMenuScreenState();
}

class _CoachMainMenuScreenState extends State<CoachMainMenuScreen> {
  String _selectedHashtag = '';

  void _filterPostsByHashtag(String hashtag) {
    setState(() {
      _selectedHashtag = hashtag;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildCategoriesSection(context),
          ),
          SliverToBoxAdapter(
            child: _buildHashtagFilter(context),
          ),
          _buildPostsSection(context),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    return Container(
      height: 150,
      child: GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: <Widget>[
          _buildCategoryItem(context, 'Запросы', Icons.search),
          _buildCategoryItem(context, 'Курсы', Icons.book),
          _buildCategoryItem(context, 'Подопечные', Icons.people),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String title, IconData icon) {
    return Card(
      child: InkWell(
        onTap: () {
          if (title == 'Курсы') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CoursesScreen()),
            );
          }
          if (title == 'Запросы') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TrainerRequestsScreen()),
            );
          }
          if (title == 'Подопечные') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MenteesScreen()), // Переход на экран подопечных
            );
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _buildHashtagFilter(BuildContext context) {
    List<String> hashtags = ['#отзыв', '#рецепт', '#занятие', '#курс'];
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hashtags.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: FilterChip(
              label: Text(hashtags[index]),
              selected: _selectedHashtag == hashtags[index],
              onSelected: (bool selected) {
                _filterPostsByHashtag(selected ? hashtags[index] : '');
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostsSection(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return StreamBuilder(
            stream: FirebaseFirestore.instance.collection('MainBoard').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              var posts = snapshot.data!.docs;
              if (_selectedHashtag.isNotEmpty) {
                posts = posts.where((post) {
                  List hashtags = post['hashtags'];
                  return hashtags.contains(_selectedHashtag);
                }).toList();
              }
              return Column(
                children: List.generate(posts.length, (index) {
                  var post = posts[index];
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('Users').doc(post['uid']).get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return ListTile(
                          title: Text(post['content']),
                        );
                      }
                      var userData = userSnapshot.data?.data() as Map<String, dynamic>?; // добавил проверку на null
                      if (userData == null) {
                        return ListTile(
                          title: Text('Пользователь не найден'),
                        );
                      }
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(userData['photoURL'] ?? ''),
                          ),
                          title: Text('${userData['name']} ${userData['surname']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (post['imageUrl'] != null && post['imageUrl'].isNotEmpty)
                                Image.network(post['imageUrl'], height: 150, width: double.infinity, fit: BoxFit.cover),
                              Text(post['content']),
                              Wrap(
                                children: List<Widget>.generate(post['hashtags'].length, (index) {
                                  return Chip(label: Text(post['hashtags'][index]));
                                }),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              );
            },
          );
        },
        childCount: 1, // This is to make sure the SliverChildBuilderDelegate works correctly.
      ),
    );
  }
}