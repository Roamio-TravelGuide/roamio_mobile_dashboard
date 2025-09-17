import 'package:flutter/material.dart';

class Destination {
  final String name;
  final String image;
  final String location;
  final double rating;
  final String? price;
  final String? duration;
  final bool isCompleted;
  final String? completedDate;

  const Destination({
    required this.name,
    required this.image,
    required this.location,
    required this.rating,
    this.price,
    this.duration,
    this.isCompleted = false,
    this.completedDate,
  });
}

class Category {
  final IconData icon;
  final String name;

  const Category({
    required this.icon,
    required this.name,
  });
}
