import 'package:flutter/material.dart';

class NeonStyles {
  static const Color neonGreen = Color(0xFF00FFC6);
  static const Color neonBlue = Color(0xFF00B4D8);
  static const Color darkBg = Color(0xFF181A20);
  static const Color surface = Color(0xFF232526);
  static const Color galaxyBlue = Color(0xFF232526);
  static const Color galaxyPurple = Color(0xFF1a2980);
  static const Color galaxyCyan = Color(0xFF26d0ce);
  static const Color neonPurple = Color(0xFFa259ff);
  static const Color neonCyan = Color(0xFF00e5ff);

  static BoxDecoration neonCard({Color? color}) => BoxDecoration(
    gradient: LinearGradient(
      colors: [surface, color ?? neonGreen],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: (color ?? neonGreen).withOpacity(0.7),
        blurRadius: 32,
        spreadRadius: 4,
        offset: Offset(0, 0),
      ),
    ],
    border: Border.all(
      color: color ?? neonGreen,
      width: 3,
      style: BorderStyle.solid,
    ),
  );

  static TextStyle neonTitle({Color? color, double fontSize = 20}) => TextStyle(
    color: color ?? neonGreen,
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        color: (color ?? neonGreen).withOpacity(0.7),
        blurRadius: 10,
      ),
    ],
  );

  static TextStyle neonText({Color? color, double fontSize = 16}) => TextStyle(
    color: color ?? Colors.white,
    fontSize: fontSize,
    fontWeight: FontWeight.w500,
    shadows: [
      Shadow(
        color: (color ?? neonGreen).withOpacity(0.5),
        blurRadius: 6,
      ),
    ],
  );

  static TextStyle neonWhite({double fontSize = 16, FontWeight fontWeight = FontWeight.bold}) => TextStyle(
    color: Colors.white,
    fontSize: fontSize,
    fontWeight: fontWeight,
    shadows: [
      Shadow(
        color: neonCyan.withOpacity(0.5),
        blurRadius: 4,
      ),
    ],
  );

  static BoxDecoration neonBackground() => BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF181A20), Color(0xFF232526)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static BoxDecoration neonContentBackground() => BoxDecoration(
    color: Color(0xFF232526),
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(30),
      topRight: Radius.circular(30),
    ),
  );

  static LinearGradient neonGalaxyGradient() => LinearGradient(
    colors: [
      Color(0xFF232526),
      Color(0xFF1a2980),
      neonPurple,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration neonGalaxyBackground() => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFF181A20),
        Color(0xFF232526),
        Color(0xFF1a2980),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static LinearGradient silkGalaxyGradient() => LinearGradient(
    colors: [
      Color(0xFF2d0736), // tím đậm
      Color(0xFF6d2e8a), // tím trung
      Color(0xFFa259ff), // tím neon
      Color(0xFF000000), // đen huyền bí
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient galaxyEmeraldGradient() => LinearGradient(
    colors: [
      Color(0xFF0f3d2e), // xanh đen
      Color(0xFF1de9b6), // xanh ngọc lục bảo
      Color(0xFF00b894), // xanh lục bảo
      Color(0xFF003300), // xanh đen đậm
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration galaxyEmeraldBackground() => BoxDecoration(
    gradient: galaxyEmeraldGradient(),
  );

  static BoxDecoration neonCardDecoration({required List<Color> colors, required Color borderColor}) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: borderColor.withOpacity(0.7),
          blurRadius: 36,
          spreadRadius: 6,
          offset: Offset(0, 0),
        ),
        BoxShadow(
          color: borderColor.withOpacity(0.3),
          blurRadius: 60,
          spreadRadius: 16,
          offset: Offset(0, 0),
        ),
      ],
      border: Border.all(
        color: borderColor.withOpacity(0.9),
        width: 3,
      ),
    );
  }
} 