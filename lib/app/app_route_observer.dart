import 'package:flutter/material.dart';

/// Lets the map pause its native scroll handling while another page is open.
///
/// This is especially important on macOS, where a trackpad or mouse scroll
/// should operate the page in front of the map rather than zooming the map in
/// the background.
final RouteObserver<ModalRoute<dynamic>> appRouteObserver =
    RouteObserver<ModalRoute<dynamic>>();
