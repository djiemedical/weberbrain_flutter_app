import 'package:flutter/material.dart';

class CopyrightNotice extends StatelessWidget {
  const CopyrightNotice({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Text(
        '© 2024 Weber Medical GmbH',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
