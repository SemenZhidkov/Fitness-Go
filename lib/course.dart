import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  String id;
  String title;
  String description;
  List<Stage> stages;
  String uid;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.stages,
    required this.uid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'stages': stages.map((stage) => stage.toMap()).toList(),
      'uid': uid,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      stages: List<Stage>.from(map['stages']?.map((x) => Stage.fromMap(x))),
      uid: map['uid'],
    );
  }
}

class Stage {
  String name;
  int sets;
  int duration;
  String videoUrl;

  Stage({
    required this.name,
    required this.sets,
    required this.duration,
    required this.videoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'duration': duration,
      'videoUrl': videoUrl,
    };
  }

  factory Stage.fromMap(Map<String, dynamic> map) {
    return Stage(
      name: map['name'],
      sets: map['sets'],
      duration: map['duration'],
      videoUrl: map['videoUrl'],
    );
  }
}
