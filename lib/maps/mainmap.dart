import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<MapObject> mapObjects = [];
  late YandexMapController _controller;
  String _selectedCenterName = '';
  String _selectedCenterAddress = '';
  String _selectedCenterLogo = '';
  double _selectedCenterLogoSize = 40;
  Point? _selectedLocation;

  final MapObjectId clusterizedPlacemarkCollectionId = const MapObjectId('clusterized_placemark_collection');

  @override
  void initState() {
    super.initState();
    _initializePlacemarks();
    
  }

  Future<Uint8List> _buildClusterAppearance(Cluster cluster) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(200, 200);
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    const radius = 60.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: cluster.size.toString(),
        style: const TextStyle(color: Colors.black, fontSize: 50),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(minWidth: 0, maxWidth: size.width);

    final textOffset = Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2);
    final circleOffset = Offset(size.height / 2, size.width / 2);

    canvas.drawCircle(circleOffset, radius, fillPaint);
    canvas.drawCircle(circleOffset, radius, strokePaint);
    textPainter.paint(canvas, textOffset);

    final image = await recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final pngBytes = await image.toByteData(format: ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }

  void _initializePlacemarks() {
    final List<PlacemarkMapObject> placemarks = [];

    final List<Map<String, dynamic>> fitnessCenters = [ 
      { 
        'name': 'DDX Fitness', 
        'points': [ 
          {'point': Point(latitude: 55.808974, longitude: 37.730233), 'address': 'Открытое ш., 4, стр. 1, Москва'}, 
          {'point': Point(latitude: 55.868817, longitude: 37.677358), 'address': 'ул. Лётчика Бабушкина, 26, Москва'}, 
          {'point': Point(latitude: 55.840827, longitude: 37.485559), 'address': 'Кронштадтский бул., 3А, Москва'}, 
          {'point': Point(latitude: 55.777560, longitude: 37.524711), 'address': 'Хорошёвское ш., 27, Москва'}, 
          {'point': Point(latitude: 55.792424, longitude: 37.671447), 'address': 'ул. Сокольнический Вал, 1Б, Москва'}, 
          {'point': Point(latitude: 55.846070, longitude: 37.659419), 'address': 'просп. Мира, 211, корп. 2, Москва'}, 
          {'point': Point(latitude: 55.868817, longitude: 37.677358), 'address': 'ул. Лётчика Бабушкина, 26, Москва'}, 
          {'point': Point(latitude: 55.864812, longitude: 37.604784), 'address': 'ул. Декабристов, 17, Москва'}, 
          {'point': Point(latitude: 55.897218, longitude: 37.604676), 'address': 'ул. Лескова, 14, Москва'}, 
          {'point': Point(latitude: 55.809736, longitude: 37.465119), 'address': 'Щукинская ул., 42, Москва'}, 
          {'point': Point(latitude: 55.789172, longitude: 37.533491), 'address': 'Ходынский бул., 4, Москва'}, 
          {'point': Point(latitude: 55.671250, longitude: 37.449596), 'address': 'Озёрная ул., 33, Москва'}, 
          {'point': Point(latitude: 55.640374, longitude: 37.532670), 'address': 'ул. Миклухо-Маклая, 36А, Москва'}, 
          {'point': Point(latitude: 55.809736, longitude: 37.465119), 'address': 'Профсоюзная ул., 126, корп. 2, Москва'}, 
          {'point': Point(latitude: 55.607084, longitude: 37.536466), 'address': 'Новоясеневский просп., 11, Москва'}, 
          {'point': Point(latitude: 55.651270, longitude: 37.612444), 'address': 'Чонгарский бул., 7, Москва'}, 
          {'point': Point(latitude: 55.653153, longitude: 37.645624), 'address': 'Каширское ш., 26, Москва'}, 
          {'point': Point(latitude: 55.579599, longitude: 37.649030), 'address': 'Булатниковская ул., 9А, Москва'}, 
          {'point': Point(latitude: 55.676307, longitude: 37.665541), 'address': 'просп. Андропова, 27, Москва'}, 
          {'point': Point(latitude: 55.647968, longitude: 37.727592), 'address': 'Новочеркасский бул., 21А, Москва'}, 
          {'point': Point(latitude: 55.639234, longitude: 37.759439), 'address': 'ул. Борисовские Пруды, 26, корп. 2, Москва'}, 
          {'point': Point(latitude: 55.703412, longitude: 37.764741), 'address': 'ул. Маршала Чуйкова, 3, Москва'}, 
          {'point': Point(latitude: 55.686843, longitude: 37.852027), 'address': 'ул. Авиаконструктора Миля, 3А, Москва'}, 
          {'point': Point(latitude: 55.724124, longitude: 37.825155), 'address': 'Вешняковская ул., 18, Москва, Москва'}, 
          {'point': Point(latitude: 55.751625, longitude: 37.820551), 'address': 'Зелёный просп., 81, Москва'}, 
          {'point': Point(latitude: 55.710191, longitude: 37.672709), 'address': '7-я Кожуховская ул., 9, Москва'}, 
          {'point': Point(latitude: 55.803560, longitude: 37.799709), 'address': 'Сиреневый бул., 31, Москва'}, 
          {'point': Point(latitude: 55.744249, longitude: 37.630646), 'address': 'Большой Овчинниковский пер., 16, Москва'}, 
        ],
        'icon': 'assets/orange.png',
        'logo': 'assets/ddx_logo.png',
        'logoSize': 20.0
      },
      {
        'name': 'Spirit Fitness',
        'points': [ 
          {'point': Point(latitude: 55.705912, longitude: 37.593764), 'address': 'ул. Вавилова, 3, Москва'}, 
          {'point': Point(latitude: 55.689580, longitude: 37.603496), 'address': 'Большая Черёмушкинская ул., 1, Москва'}, 
          {'point': Point(latitude: 55.664747, longitude: 37.578115), 'address': 'Севастопольский просп., 28, корп. 2, Москва'}, 
          {'point': Point(latitude: 55.642022, longitude: 37.603721), 'address': 'Балаклавский просп., 16А, Москва'}, 
          {'point': Point(latitude: 55.644745, longitude: 37.519704), 'address': 'ул. Миклухо-Маклая, 18, корп. 2, Москва'}, 
          {'point': Point(latitude: 55.608589, longitude: 37.537405), 'address': 'Ясногорская ул., 7А, Москва'}, 
          {'point': Point(latitude: 55.624388, longitude: 37.709682), 'address': 'Каширское ш., 80, Москва'}, 
          {'point': Point(latitude: 55.649174, longitude: 37.745114), 'address': 'Люблинская ул., 169, корп. 2, Москва'}, 
          {'point': Point(latitude: 55.718295, longitude: 37.783752), 'address': 'Рязанский просп., 30, корп. 2, Москва'}, 
          {'point': Point(latitude: 55.782900, longitude: 37.721787), 'address': 'Семёновская площадь, 1, Москва'}, 
          {'point': Point(latitude: 55.794766, longitude: 37.616689), 'address': 'Шереметьевская ул., 6, корп. 1, Москва'}, 
          {'point': Point(latitude: 55.869322, longitude: 37.637122), 'address': 'пр. Дежнёва, 23, Москва'}, 
          {'point': Point(latitude: 55.862933, longitude: 37.547502), 'address': 'Дмитровское ш., 85, Москва'}, 
          {'point': Point(latitude: 55.824109, longitude: 37.500058), 'address': 'Старопетровский пр., 1, стр. 5, Москва'}, 
          {'point': Point(latitude: 55.809742, longitude: 37.459753), 'address': 'Авиационная ул., 66, Москва'}, 
          {'point': Point(latitude: 55.806019, longitude: 37.395461), 'address': 'Строгинский бул., 1, Москва'}, 
          {'point': Point(latitude: 55.755467, longitude: 37.402393), 'address': 'Рублёвское ш., 52А, Москва'}, 
          {'point': Point(latitude: 55.749407, longitude: 37.536828), 'address': 'Пресненская наб., 12, Москва'}, 
          {'point': Point(latitude: 55.697406, longitude: 37.500231), 'address': 'Мичуринский просп., вл27, Москва'}, 
          {'point': Point(latitude: 55.662648, longitude: 37.481115), 'address': 'просп. Вернадского, 86А, Москва'}, 
          {'point': Point(latitude: 55.741169, longitude: 37.674259), 'address': 'ул. Рогожский Вал, 10, Москва'}, 
        ],
        'icon': 'assets/green.png',
        'logo': 'assets/spirit_logo.png',
        'logoSize': 50.0,
      },
      {
        'name': 'World Class', 
        'points': [ 
          {'point': Point(latitude: 55.810969, longitude: 37.799655), 'address': 'Щёлковское ш., 75, Москва'}, 
          {'point': Point(latitude: 55.834949, longitude: 37.657905), 'address': 'просп. Мира, 188Б, корп. 2, Москва'}, 
          {'point': Point(latitude: 55.844989, longitude: 37.635091), 'address': 'ул. Вильгельма Пика, 16, Москва'}, 
          {'point': Point(latitude: 55.804460, longitude: 37.617823), 'address': '12-й пр. Марьиной Рощи, 9, стр. 2, Москва'}, 
          {'point': Point(latitude: 55.878210, longitude: 37.479165), 'address': 'ул. Дыбенко, 7/1, Москва'}, 
          {'point': Point(latitude: 55.846070, longitude: 37.659419), 'address': 'Флотская ул., 7, стр. 1, Москва'}, 
          {'point': Point(latitude: 55.842573, longitude: 37.460967), 'address': 'Лодочная ул., 43, Москва'}, 
          {'point': Point(latitude: 55.823860, longitude: 37.496025), 'address': 'Ленинградское ш., 16А, стр. 8, Москва'}, 
          {'point': Point(latitude: 55.803200, longitude: 37.389967), 'address': 'ул. Кулакова, 20, корп. 1, Москва'}, 
          {'point': Point(latitude: 55.739171, longitude: 37.411243), 'address': 'Ярцевская ул., 19, Москва'}, 
          {'point': Point(latitude: 55.707666, longitude: 37.456648), 'address': 'Аминьевское ш., 6, Москва'}, 
          {'point': Point(latitude: 55.673516, longitude: 37.519655), 'address': 'Ленинский просп., 90/3, Москва'}, 
          {'point': Point(latitude: 55.663595, longitude: 37.549647), 'address': 'ул. Намёткина, 6, корп. 1, Москва'}, 
          {'point': Point(latitude: 55.725897, longitude: 37.572508), 'address': 'ул. Усачёва, 13, корп. Г, Москва'}, 
          {'point': Point(latitude: 55.629425, longitude: 37.616454), 'address': 'Варшавское ш., 122А, Москва'}, 
          {'point': Point(latitude: 55.622006, longitude: 37.714185), 'address': 'Каширское ш., 61Г, Москва'}, 
          {'point': Point(latitude: 55.750844, longitude: 37.706622), 'address': 'ул. Крузенштерна, 12, корп. 3, Москва'}, 
          {'point': Point(latitude: 55.747075, longitude: 37.657680), 'address': 'Николоямская ул., 36, стр. 1, Москва'}, 
          {'point': Point(latitude: 55.762050, longitude: 37.658637), 'address': 'ул. Земляной Вал, 9, Москва'}, 
          {'point': Point(latitude: 55.773717, longitude: 37.606420), 'address': 'Оружейный пер., 41, Москва'}, 
          {'point': Point(latitude: 55.754928, longitude: 37.609754), 'address': 'Романов пер., 4, стр. 2, Москва'}, 
          {'point': Point(latitude: 55.731644, longitude: 37.615993), 'address': 'Житная ул., 14, стр. 2, Москва'}, 
          {'point': Point(latitude: 55.746918, longitude: 37.539177), 'address': 'Пресненская наб., 8, стр. 1, Москва'}, 
          {'point': Point(latitude: 55.718389, longitude: 37.524249), 'address': 'Мосфильмовская ул., 1Б, Москва'}, 
          {'point': Point(latitude: 55.769922, longitude: 37.489742), 'address': 'ул. Демьяна Бедного, 4, корп. 2, Москва'}, 
          {'point': Point(latitude: 55.728317, longitude: 37.438629), 'address': 'ул. Ивана Франко, 16, Москва'}, 
          {'point': Point(latitude: 55.719156, longitude: 37.426948), 'address': 'Рябиновая ул., 3, стр. 6, Москва'}, 
          {'point': Point(latitude: 55.669983, longitude: 37.542531), 'address': 'ул. Архитектора Власова, 22, Москва'}, 
        ],
        'icon': 'assets/red.png',
        'logo': 'assets/world_logo.png',
        'logoSize': 60.0,
      }
    ];

    for (var center in fitnessCenters) {
      for (var pointData in center['points']) {
        placemarks.add(
          PlacemarkMapObject(
            mapId: MapObjectId('${center['name']}_${pointData['point'].latitude}_${pointData['point'].longitude}'),
            point: pointData['point'],
            onTap: (PlacemarkMapObject self, Point point) {
              _showBottomSheet(center['name'], pointData['address'], center['logo'], center['logoSize'], point);
            },
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(
                image: BitmapDescriptor.fromAssetImage(center ['icon']),
                scale: 4.0,
              ),
            ),
          ),
        );
      }
    }

    final clusterizedPlacemarkCollection = ClusterizedPlacemarkCollection(
      mapId: clusterizedPlacemarkCollectionId,
      radius: 30,
      minZoom: 15,
      onClusterAdded: (ClusterizedPlacemarkCollection self, Cluster cluster) async {
        return cluster.copyWith(
          appearance: cluster.appearance.copyWith(
            icon: PlacemarkIcon.single(PlacemarkIconStyle(
              image: BitmapDescriptor.fromBytes(await _buildClusterAppearance(cluster)),
              scale: 1
            ))
          )
        );
      },
      onClusterTap: (ClusterizedPlacemarkCollection self, Cluster cluster) {
        print('Tapped cluster');
      },
      placemarks: placemarks,
      onTap: (ClusterizedPlacemarkCollection self, Point point) => print('Tapped me at $point'),
    );

    setState(() {
      mapObjects.add(clusterizedPlacemarkCollection);
    });
  }

void _showBottomSheet(String centerName, String address, String logo, double logoSize, Point location) {
  setState(() {
    _selectedCenterName = centerName;
    _selectedCenterAddress = address;
    _selectedCenterLogo = logo;
    _selectedCenterLogoSize = logoSize;
    _selectedLocation = location; // Save the location of the selected center
  });
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      var theme = Theme.of(context);
    var textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    var backgroundColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.25,
            color: backgroundColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      _selectedCenterLogo,
                      height: _selectedCenterLogoSize,
                    ),
                    SizedBox(width: 10),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  _selectedCenterName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color: textColor ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  _selectedCenterAddress,
                  style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w200, color: textColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {'name': _selectedCenterName, 'address': _selectedCenterAddress, 'logo': _selectedCenterLogo, 'location': _selectedLocation});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Клуб выбран: $_selectedCenterName'), backgroundColor: backgroundColor,),
                    );
                  },
                  child: Text('Выбрать клуб'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  ).then((value) {
    if (value != null) {
      Navigator.pop(context, value); // Возвращаем данные на предыдущий экран
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Выберите клуб'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            
            child: YandexMap(
              mapObjects: mapObjects,
              onMapCreated: (YandexMapController yandexMapController) async {
                _controller = yandexMapController;
                const MapAnimation(duration: 0.0);
                // Переместить камеру на Москву после инициализации карты
                 _controller.moveCamera(
                  CameraUpdate.newCameraPosition(
                    const CameraPosition(
                      target: Point(latitude: 55.751244, longitude: 37.618423),
                      zoom: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
