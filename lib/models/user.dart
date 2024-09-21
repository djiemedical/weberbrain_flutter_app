// File: lib/models/user.dart

import 'package:flutter/material.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
    );
  }

  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase();
    } else {
      return name.substring(0, min(2, name.length)).toUpperCase();
    }
  }

  Color get avatarColor {
    return Colors.primaries[id.hashCode % Colors.primaries.length];
  }
}

int min(int a, int b) => a < b ? a : b;
