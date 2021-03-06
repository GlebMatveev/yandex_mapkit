import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'map_animation.dart';
import 'placemark.dart';
import 'point.dart';

class YandexMapController extends ChangeNotifier {
  static const double kTilt = 0.0;
  static const double kAzimuth = 0.0;
  static const double kZoom = 15.0;

  final MethodChannel _channel;

  final List<Placemark> placemarks = [];

  final int _id;

  YandexMapController._(this._id,  channel)
      : _channel = channel {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static YandexMapController init(int id) {
    final MethodChannel methodChannel = MethodChannel('yandex_mapkit/yandex_map_$id');

    return YandexMapController._(id, methodChannel);
  }

  /// Shows an icon at current user location
  ///
  /// Requires location permissions:
  ///
  /// `NSLocationWhenInUseUsageDescription`
  ///
  /// `android.permission.ACCESS_FINE_LOCATION`
  ///
  /// Does nothing if these permissions where denied
  Future<void> showUserLayer({@required String iconName}) async {
    await _channel.invokeMethod(
      'showUserLayer',
      {
        'iconName': iconName
      }
    );
  }

  /// Hides an icon at current user location
  ///
  /// Requires location permissions:
  ///
  /// `NSLocationWhenInUseUsageDescription`
  ///
  /// `android.permission.ACCESS_FINE_LOCATION`
  ///
  /// Does nothing if these permissions where denied
  Future<void> hideUserLayer() async {
    await _channel.invokeMethod('hideUserLayer');
  }

  Future<void> move({
    @required Point point,
    double zoom = kZoom,
    double azimuth = kAzimuth,
    double tilt = kTilt,
    MapAnimation animation
  }) async {
    await _channel.invokeMethod(
      'move',
      {
        'latitude': point.latitude,
        'longitude': point.longitude,
        'zoom': zoom,
        'azimuth': azimuth,
        'tilt': tilt,
        'animate': animation != null,
        'smoothAnimation': animation?.smooth,
        'animationDuration': animation?.duration
      }
    );
  }

  Future<void> setBounds({
    @required Point southWestPoint,
    @required Point northEastPoint,
    MapAnimation animation
  }) async {
    await _channel.invokeMethod(
      'setBounds',
      {
        'southWestLatitude': southWestPoint.latitude,
        'southWestLongitude': southWestPoint.longitude,
        'northEastLatitude': northEastPoint.latitude,
        'northEastLongitude': northEastPoint.longitude,
        'animate': animation != null,
        'smoothAnimation': animation?.smooth,
        'animationDuration': animation?.duration
      }
    );
  }

  /// Does nothing if passed `Placemark` is `null`
  Future<void> addPlacemark(Placemark placemark) async {
    if (placemark != null) {
      await _channel.invokeMethod('addPlacemark', _placemarkParams(placemark));
      placemarks.add(placemark);
    }
  }

  // Does nothing if passed `Placemark` wasn't added before
  Future<void> removePlacemark(Placemark placemark) async {
    if (placemarks.remove(placemark)) {
      await _channel.invokeMethod(
        'removePlacemark',
        {
          'hashCode': placemark.hashCode
        }
      );
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onMapObjectTap':
        _onMapObjectTap(call.arguments);
        break;
      default:
        throw MissingPluginException();
    }
  }

  void _onMapObjectTap(dynamic arguments) {
    int hashCode = arguments['hashCode'];
    double latitude = arguments['latitude'];
    double longitude = arguments['longitude'];

    Placemark placemark = placemarks.
      firstWhere((Placemark placemark) => placemark.hashCode == hashCode, orElse: () => null);

    if (placemark != null) {
      placemark.onTap(latitude, longitude);
    }
  }

  Map<String, dynamic> _placemarkParams(Placemark placemark) {
    return {
      'latitude': placemark.point.latitude,
      'longitude': placemark.point.longitude,
      'opacity': placemark.opacity,
      'isDraggable': placemark.isDraggable,
      'iconName': placemark.iconName,
      'hashCode': placemark.hashCode
    };
  }
}
