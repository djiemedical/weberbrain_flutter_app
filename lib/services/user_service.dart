import 'dart:async';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import '../models/user.dart';

class UserService {
  final userPool = CognitoUserPool(
    'ap-southeast-1_gr84OWPCx', // Your Cognito User Pool ID
    '56qctkq30uenjdsgc9n1fv1ru4', // Your Cognito App Client ID
  );

  Future<User> getCurrentUser() async {
    try {
      final cognitoUser = await userPool.getCurrentUser();
      if (cognitoUser == null) {
        throw Exception('No current user found');
      }

      final session = await cognitoUser.getSession();
      if (session == null || !session.isValid()) {
        throw Exception('Invalid session');
      }

      final attributes = await cognitoUser.getUserAttributes();
      if (attributes == null) {
        throw Exception('Unable to fetch user attributes');
      }

      String? name;
      String? email;
      String? sub;

      for (var attribute in attributes) {
        switch (attribute.getName()) {
          case 'name':
            name = attribute.getValue();
            break;
          case 'email':
            email = attribute.getValue();
            break;
          case 'sub':
            sub = attribute.getValue();
            break;
        }
      }

      if (name == null || email == null || sub == null) {
        throw Exception('Required user attributes not found');
      }

      String? avatarUrl;
      for (var attribute in attributes) {
        if (attribute.getName() == 'custom:avatar_url') {
          avatarUrl = attribute.getValue();
          break;
        }
      }

      return User(
        id: sub,
        name: name,
        email: email,
        avatarUrl: avatarUrl,
      );
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;
    }
  }

  // TODO: Implement method to update avatar URL in Cognito and your backend
}
