import 'package:amazon_cognito_identity_dart_2/cognito.dart';

class AuthService {
  final userPool = CognitoUserPool(
    'ap-southeast-1_gr84OWPCx',
    '56qctkq30uenjdsgc9n1fv1ru4',
  );

  Future<bool> signUp(
      String email, String password, Map<String, String> attributes) async {
    try {
      final userAttributes = attributes.entries
          .map((e) => AttributeArg(name: e.key, value: e.value))
          .toList();

      final signUpResult = await userPool.signUp(
        email,
        password,
        userAttributes: userAttributes,
      );
      return signUpResult.userConfirmed ?? false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> confirmSignUp(String email, String confirmationCode) async {
    final cognitoUser = CognitoUser(email, userPool);
    try {
      return await cognitoUser.confirmRegistration(confirmationCode);
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<CognitoUserSession?> signIn(String email, String password) async {
    final cognitoUser = CognitoUser(email, userPool);
    final authDetails = AuthenticationDetails(
      username: email,
      password: password,
    );

    try {
      return await cognitoUser.authenticateUser(authDetails);
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<bool> forgotPassword(String email) async {
    final cognitoUser = CognitoUser(email, userPool);
    try {
      await cognitoUser.forgotPassword();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> confirmNewPassword(
      String email, String confirmationCode, String newPassword) async {
    final cognitoUser = CognitoUser(email, userPool);
    try {
      return await cognitoUser.confirmPassword(confirmationCode, newPassword);
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> signOut(String email) async {
    final cognitoUser = CognitoUser(email, userPool);
    try {
      await cognitoUser.signOut();
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
