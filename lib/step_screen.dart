import 'package:flutter/material.dart';
import 'create_course_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;

class StepScreen extends StatefulWidget {
  @override
  _StepScreenState createState() => _StepScreenState();
}

class _StepScreenState extends State<StepScreen> {
  final _formKey = GlobalKey<FormState>();
  String stepName = '';
  int sets = 0;
  int time = 0;
  File? _videoFile;

  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _videoUrl;

  void saveStep() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isUploading = true;
      });

      if (_videoFile != null) {
        _videoUrl = await _uploadVideo(_videoFile!);
      }

      final newStep = StepInfo(
        name: stepName,
        sets: sets,
        time: time,
        videoUrl: _videoUrl,
      );

      Navigator.pop(context, newStep);
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

  Future<void> _recordVideo() async {
    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.camera);
      setState(() {
        if (pickedFile != null) {
          _videoFile = File(pickedFile.path);
          print('Video recorded: ${pickedFile.path}');
        } else {
          print('No video recorded.');
        }
      });
    } catch (e) {
      print('Error recording video: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Добавить этап'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Наименование упражнения'),
                onSaved: (value) => stepName = value!,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите наименование';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Количество подходов'),
                keyboardType: TextInputType.number,
                onSaved: (value) => sets = int.parse(value!),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите количество подходов';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Время (мин)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => time = int.parse(value!),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите время';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  print('Upload video tapped');
                  _pickVideo();
                },
                child: Column(
                  children: [
                    Icon(Icons.attach_file, size: 50),
                    Text('Вы также можете добавить видео'),
                  ],
                ),
              ),
              SizedBox(height: 80),
              _videoFile == null
                  ? Text('Видео не выбрано.')
                  : Text('Видео выбрано: ${_videoFile!.path}'),
              ElevatedButton(
                onPressed: () {
                  print('Record video tapped');
                  _recordVideo();
                },
                child: Text('Записать видео'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUploading ? null : saveStep,
                child: _isUploading ? CircularProgressIndicator() : Text('Сохранить этап'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StepInfo {
  final String name;
  final int sets;
  final int time;
  final String? videoUrl;

  StepInfo({
    required this.name,
    required this.sets,
    required this.time,
    this.videoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'time': time,
      'videoUrl': videoUrl,
    };
  }
}
