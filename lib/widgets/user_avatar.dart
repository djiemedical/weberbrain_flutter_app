// File: lib/widgets/user_avatar.dart

import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final User user;
  final double radius;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 50,
  });

  @override
  Widget build(BuildContext context) {
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(user.avatarUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          print('Error loading avatar: $exception');
        },
        child: _buildInitialsAvatar(),
      );
    } else {
      return _buildInitialsAvatar();
    }
  }

  Widget _buildInitialsAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: user.avatarColor,
      child: Text(
        user.initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
