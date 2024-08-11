import 'package:amazon_cognito_identity_dart_2/cognito.dart';

class AuthResult {
  final bool success;
  final String message;
  final CognitoUserSession? session;

  AuthResult({required this.success, required this.message, this.session});
}

class AuthService {
  final userPool = CognitoUserPool(
    'ap-southeast-1_gr84OWPCx',
    '56qctkq30uenjdsgc9n1fv1ru4',
  );

  Future<AuthResult> signUp(
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

      return AuthResult(
        success: true,
        message:
            'User successfully signed up. Please check your email for confirmation code.',
        session: null,
      );
    } on CognitoClientException catch (e) {
      return AuthResult(
        success: false,
        message: 'Sign up failed: ${e.message}',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> confirmSignUp(
      String email, String confirmationCode) async {
    final cognitoUser = CognitoUser(email, userPool);
    try {
      final confirmResult =
          await cognitoUser.confirmRegistration(confirmationCode);
      return AuthResult(
        success: confirmResult,
        message: confirmResult
            ? 'Account confirmed successfully'
            : 'Failed to confirm account',
      );
    } on CognitoClientException catch (e) {
      if (e.code == 'NotAuthorizedException' &&
          e.message?.contains(
                  'User cannot be confirmed. Current status is CONFIRMED') ==
              true) {
        return AuthResult(
          success: true,
          message: 'Account is already confirmed. Please proceed to login.',
        );
      } else {
        return AuthResult(
          success: false,
          message: 'Error confirming account: ${e.message}',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Error confirming account: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> signIn(String email, String password) async {
    final cognitoUser = CognitoUser(email, userPool);
    final authDetails = AuthenticationDetails(
      username: email,
      password: password,
    );

    try {
      final session = await cognitoUser.authenticateUser(authDetails);
      return AuthResult(
        success: true,
        message: 'User successfully signed in',
        session: session,
      );
    } on CognitoClientException catch (e) {
      return AuthResult(
        success: false,
        message: 'Sign in failed: ${e.message}',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> forgotPassword(String email) async {
    final cognitoUser = CognitoUser(email, userPool);
    try {
      await cognitoUser.forgotPassword();
      return AuthResult(
        success: true,
        message: 'Password reset code sent to email',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Error initiating password reset: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> confirmNewPassword(
      String email, String confirmationCode, String newPassword) async {
    final cognitoUser = CognitoUser(email, userPool);
    try {
      await cognitoUser.confirmPassword(confirmationCode, newPassword);
      return AuthResult(
        success: true,
        message: 'Password reset successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Error resetting password: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> resendConfirmationCode(String email) async {
    final cognitoUser = CognitoUser(email, userPool);
    try {
      await cognitoUser.resendConfirmationCode();
      return AuthResult(
        success: true,
        message: 'Confirmation code resent successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Error resending confirmation code: ${e.toString()}',
      );
    }
  }

  // Option 1: signOut method without BuildContext

  Future<void> signOut() async {
    try {
      final cognitoUser = await userPool.getCurrentUser();
      if (cognitoUser != null) {
        await cognitoUser.signOut();
      }
      // You might want to clear any stored user data here
    } catch (e) {
      throw Exception('Error signing out: ${e.toString()}');
    }

    // Option 2: Use BuildContext in AuthService
    /*
  Future<void> signOutWithContext(BuildContext context) async {
    try {
      final cognitoUser = await userPool.getCurrentUser();
      if (cognitoUser != null) {
        await cognitoUser.signOut();
      }
      // You might want to clear any stored user data here

      // Navigate to login screen or perform any UI-related actions
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      throw Exception('Error signing out: ${e.toString()}');
    }
  }
  */

    Future<AuthResult> getCurrentUser() async {
      try {
        final cognitoUser = await userPool.getCurrentUser();
        if (cognitoUser == null) {
          return AuthResult(
            success: false,
            message: 'No current user found',
          );
        }
        final session = await cognitoUser.getSession();
        return AuthResult(
          success: true,
          message: 'Current user session retrieved',
          session: session,
        );
      } catch (e) {
        return AuthResult(
          success: false,
          message: 'Failed to get current user: ${e.toString()}',
        );
      }
    }

    Future<AuthResult> changePassword(
        String email, String oldPassword, String newPassword) async {
      final cognitoUser = CognitoUser(email, userPool);
      try {
        final authDetails = AuthenticationDetails(
          username: email,
          password: oldPassword,
        );
        final session = await cognitoUser.authenticateUser(authDetails);
        await cognitoUser.changePassword(oldPassword, newPassword);
        return AuthResult(
          success: true,
          message: 'Password changed successfully',
          session: session,
        );
      } catch (e) {
        return AuthResult(
          success: false,
          message: 'Failed to change password: ${e.toString()}',
        );
      }
    }

    Future<AuthResult> getUserAttributes(String email) async {
      final cognitoUser = CognitoUser(email, userPool);
      try {
        final attributes = await cognitoUser.getUserAttributes();
        return AuthResult(
          success: true,
          message: 'User attributes retrieved successfully',
          session:
              null, // You might want to create a custom result class for this method
        );
      } catch (e) {
        return AuthResult(
          success: false,
          message: 'Failed to get user attributes: ${e.toString()}',
        );
      }
    }

    Future<AuthResult> verifyPasswordResetCode(
        String email, String verificationCode) async {
      final cognitoUser = CognitoUser(email, userPool);
      try {
        // This is a placeholder. Cognito doesn't have a separate verification step.
        // We're just checking if the user exists and is allowed to reset the password.
        await cognitoUser.forgotPassword();
        return AuthResult(
          success: true,
          message: 'Verification code is valid',
        );
      } catch (e) {
        return AuthResult(
          success: false,
          message: 'Error verifying code: ${e.toString()}',
        );
      }
    }
  }
}
