package com.geodev.fitnessgo

import io.flutter.embedding.android.FlutterActivity
import com.yandex.mapkit.MapKitFactory
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        MapKitFactory.setApiKey("b112f7bd-840b-483e-a0f3-e2805145b468")
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
    
}
