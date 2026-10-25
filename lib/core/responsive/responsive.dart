import 'package:flutter/material.dart';

/// Au-delà de cette largeur d'écran (en pixels logiques), on considère
/// qu'on est sur une tablette plutôt qu'un téléphone.
class Responsive {
  static const double tabletBreakpoint = 600;

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
}