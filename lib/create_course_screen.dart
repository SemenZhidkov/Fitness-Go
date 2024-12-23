import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'step_screen.dart';
import 'course.dart';
import 'package:path/path.dart' as Path;

class CreateCourseScreen extends StatefulWidget {
  final Function onCourseCreated;

  CreateCourseScreen({required this.onCourseCreated});

  @override
  _CreateCourseScreenState createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  String courseTitle = '';
  String courseDescription = '';
  List<Stage> stages = [];

  void saveCourse() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Получаем текущего пользователя
      User? user = FirebaseAuth.instance.currentUser;

      // Создаем курс с необходимыми полями
      final newCourse = Course(
        id: '', // Firestore автоматически присвоит ID
        title: courseTitle,
        description: courseDescription,
        stages: stages,
        uid: user!.uid, // Сохраняем uid текущего пользователя
      );

      await FirebaseFirestore.instance
          .collection('courses')
          .add(newCourse.toMap())
          .then((DocumentReference doc) {
        print('Course added with ID: ${doc.id}');
        widget.onCourseCreated(); // Увеличиваем счетчик курсов
      }).catchError((error) {
        print('Error adding course: $error');
      });

      Navigator.pop(context);
    }
  }

  void addStage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateStageScreen(onStageAdded: (stage) {
        setState(() {
          stages.add(stage);
        });
      })),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создать курс'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: saveCourse,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Название курса'),
                onSaved: (value) => courseTitle = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Описание курса'),
                onSaved: (value) => courseDescription = value!,
              ),
              SizedBox(height: 20),
              ...stages.map((stage) => ListTile(
                    title: Text(stage.name),
                    subtitle: Text('Подходы: ${stage.sets}, Время: ${stage.duration} мин'),
                  )),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: addStage,
                child: Text('Добавить этап'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateStageScreen extends StatefulWidget {
  final Function(Stage) onStageAdded;

  CreateStageScreen({required this.onStageAdded});

  @override
  _CreateStageScreenState createState() => _CreateStageScreenState();
}

class _CreateStageScreenState extends State<CreateStageScreen> {
  final _formKey = GlobalKey<FormState>();
  String stageName = '';
  int sets = 0;
  int duration = 0;
  String videoUrl = '';
  
  File? _videoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  void saveStage() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newStage = Stage(
        name: stageName,
        sets: sets,
        duration: duration,
        videoUrl: videoUrl,
      );

      widget.onStageAdded(newStage);
      Navigator.pop(context);
    }
  }

   Future<String> _uploadVideo(File videoFile) async {
    String fileName = Path.basename(videoFile.path);
    Reference storageReference = FirebaseStorage.instance.ref().child('videos/$fileName');
    UploadTask uploadTask = storageReference.putFile(videoFile);
    await uploadTask.whenComplete(() => null);
    String videoUrl = await storageReference.getDownloadURL();
    return videoUrl;
  }
  Future<void> _pickVideo() async {
    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      setState(() {
        if (pickedFile != null) {
          _videoFile = File(pickedFile.path);
          print('Video selected: ${pickedFile.path}');
        } else {
          print('No video selected.');
        }
      });
    } catch (e) {
      print('Error picking video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Создать этап'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Название упражнения'),
                onSaved: (value) => stageName = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Количество подходов'),
                keyboardType: TextInputType.number,
                onSaved: (value) => sets = int.parse(value!),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Время (минуты)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => duration = int.parse(value!),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _pickVideo,
                child: Column(
                  children: [
                    Icon(Icons.attach_file, size: 50),
                    Text('Вы также можете добавить видео'),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _videoFile == null
                  ? Text('Видео не выбрано.')
                  : Text('Видео выбрано: ${_videoFile!.path}'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUploading ? null : saveStage,
                child: _isUploading ? CircularProgressIndicator() : Text('Сохранить этап'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
