import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<UserModel>> getUsers() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    final querySnapshot = await _firestore.collection('Users').get();
    return querySnapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
  }

  Future<void> likeUser(String likedUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore.collection('Users').doc(currentUser.uid).update({
      'likes': FieldValue.arrayUnion([likedUserId]),
    });

    await _firestore.collection('Users').doc(likedUserId).update({
      'likedBy': FieldValue.arrayUnion([currentUser.uid]),
    });
  }

  Future<void> skipUser(String skippedUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore.collection('Users').doc(currentUser.uid).update({
      'skips': FieldValue.arrayUnion([skippedUserId]),
    });
  }

  Future<List<UserModel>> getUsersWhoLikedMe() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    final userDoc = await _firestore.collection('Users').doc(currentUser.uid).get();
    List<String> likedByUserIds = List<String>.from(userDoc.data()?['likedBy'] ?? []);

    if (likedByUserIds.isEmpty) return [];

    final querySnapshot = await _firestore.collection('Users').where(FieldPath.documentId, whereIn: likedByUserIds).get();
    return querySnapshot.docs.map((doc) => UserModel.fromDocument(doc)).toList();
  }
}




class UserModel {
  final String id;
  final String name;
  final String surname;
  final String photoURL;
  final String role;
  final Map<String, dynamic> choose;
  final DateTime birthday;

  UserModel({
    required this.id,
    required this.name,
    required this.surname,
    required this.photoURL,
    required this.role,
    required this.choose,
    required this.birthday,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month || (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime birthday;

    if (data['birthday'] is Timestamp) {
      birthday = (data['birthday'] as Timestamp).toDate();
    } else if (data['birthday'] is String) {
      birthday = DateFormat('dd.MM.yyyy').parse(data['birthday']);
    } else {
      birthday = DateTime.now();
    }

    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      surname: data['surname'] ?? '',
      photoURL: data['photoURL'] ?? '',
      role: data['role'] ?? '',
      choose: data['choose'] is Map<String, dynamic> ? data['choose'] as Map<String, dynamic> : {},
      birthday: birthday,
    );
  }
}