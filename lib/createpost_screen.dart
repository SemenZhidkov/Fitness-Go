import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  List<String> _selectedHashtags = [];

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> _createPost() async {
    if (_postController.text.isEmpty && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter some content or select an image.')));
      return;
    }

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImage(_imageFile!);
    }

    User? user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('MainBoard').add({
      'content': _postController.text,
      'uid': user?.uid,
      'imageUrl': imageUrl ?? '',
      'hashtags': _selectedHashtags,
      'timestamp': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
  }

  Future<String> _uploadImage(File image) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference = FirebaseStorage.instance.ref().child('posts/$fileName');
    UploadTask uploadTask = storageReference.putFile(image);
    await uploadTask.whenComplete(() => null);
    return await storageReference.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    List<String> hashtags = ['#отзыв', '#рецепт', '#занятие', '#курс'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Создать пост'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _createPost,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _postController,
              decoration: InputDecoration(hintText: 'Что у вас нового?'),
              maxLines: null,
            ),
            SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: _pickImage,
                ),
                _imageFile == null
                    ? Text('Нет изображения.')
                    : Image.file(_imageFile!, height: 100, width: 100, fit: BoxFit.cover),
              ],
            ),
            Wrap(
              children: List<Widget>.generate(hashtags.length, (index) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: FilterChip(
                    label: Text(hashtags[index]),
                    selected: _selectedHashtags.contains(hashtags[index]),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedHashtags.add(hashtags[index]);
                        } else {
                          _selectedHashtags.removeWhere((String name) {
                            return name == hashtags[index];
                          });
                        }
                      });
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
