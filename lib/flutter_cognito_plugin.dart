import 'package:flutter/services.dart';
import 'package:flutter_cognito_plugin/exception_serializer.dart';
import 'package:flutter_cognito_plugin/exceptions.dart';
import 'package:flutter_cognito_plugin/models.dart';

export 'package:flutter_cognito_plugin/exceptions.dart';
export 'package:flutter_cognito_plugin/models.dart';

const _platform = const MethodChannel('com.pycampers.flutter_cognito_plugin');

typedef OnUserStateChange(UserState userState);

var _retryExceptions = [
  ApolloException("Failed to parse http response"),
  ApolloException("Failed to execute http call"),
  AmazonClientException("Unable to execute HTTP request"),
];

bool _isRetryException(CognitoException e) {
  for (var rule in _retryExceptions) {
    if (e.runtimeType == rule.runtimeType &&
        e.message.toUpperCase().contains(rule.message.toUpperCase())) {
      return true;
    }
  }
  return false;
}

class Cognito {
  /// The number of times to automatically retry sending a request.
  ///
  /// Useful for cases where network is flaky.
  ///
  /// Takes extra care to retry only for a network related error,
  /// and not a client error, like OTP incorrect, etc.
  ///
  /// 0 -> No retry.
  /// Non-zero number -> Retry specified number of times.
  /// null -> Infinite retry.
  static int autoRetryLimit = 0;

  /// The delay before retrying.
  static Duration retryDelay = Duration();

  /// Invokes a method on specified [MethodChannel] (platform).
  ///
  /// This is useful for other plugins/apps that want
  /// to leverage the auto retry capabilities of this plugin.
  static Future invokeMethodWithPlatform(
    MethodChannel platform,
    String method, [
    dynamic arguments,
  ]) async {
    var tries = 0;
    while (true) {
      tries += 1;
      try {
        return await platform.invokeMethod(method, arguments);
      } catch (_e) {
        if (!(_e is PlatformException)) {
          rethrow;
        }

        var e = convertException(_e);
        if (autoRetryLimit != null && tries > autoRetryLimit) {
          throw e;
        }

        if (_isRetryException(e)) {
          print("[Cognito] Ignoring exception - $e");
          print(
            "[Cognito] Will retry after $retryDelay (tries: $tries, limit: $autoRetryLimit)",
          );
          await Future.delayed(retryDelay);
        } else {
          throw e;
        }
      }
    }
  }

  static invokeMethod(String method, [dynamic arguments]) {
    return invokeMethodWithPlatform(_platform, method, arguments);
  }

  /// Initializes the AWS mobile client.
  ///
  /// This MUST be called before using any other methods under this class.
  /// A good strategy might be to invoke this before [runApp()] in [main()], like so:
  ///
  /// ```
  /// void main() async {
  ///   UserStateDetails details = await Cognito.initialize();
  ///   print(details);
  ///
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<UserState> initialize() async {
    return UserState.values[await invokeMethod("initialize")];
  }

  /// Registers a callback that gets called every-time the UserState changes.
  ///
  /// Replaces existing callback, if any.
  ///
  /// If `null` is passed, then the existing callback will be removed, if any.
  static void registerCallback(OnUserStateChange onUserStateChange) {
    if (onUserStateChange == null) {
      _platform.setMethodCallHandler(null);
      return;
    }

    _platform.setMethodCallHandler((call) {
      onUserStateChange(UserState.values[call.arguments]);
    });
  }

  static Future<SignUpResult> signUp(
    String username,
    String password, [
    Map<String, String> userAttributes,
  ]) async {
    return SignUpResult.fromMsg(
      await invokeMethod("signUp", {
        "username": username ?? "",
        "password": password ?? "",
        "userAttributes": userAttributes ?? {},
      }),
    );
  }

  static Future<SignUpResult> confirmSignUp(
    String username,
    String confirmationCode,
  ) async {
    return SignUpResult.fromMsg(
      await invokeMethod("confirmSignUp", {
        "username": username ?? "",
        "confirmationCode": confirmationCode ?? "",
      }),
    );
  }

  static Future<SignUpResult> resendSignUp(String username) async {
    return SignUpResult.fromMsg(
      await invokeMethod("resendSignUp", {
        "username": username ?? "",
      }),
    );
  }

  static Future<SignInResult> signIn(String username, String password) async {
    return SignInResult.fromMsg(
      await invokeMethod("signIn", {
        "username": username ?? "",
        "password": password ?? "",
      }),
    );
  }

  static Future<SignInResult> confirmSignIn(String confirmationCode) async {
    return SignInResult.fromMsg(
      await invokeMethod("confirmSignIn", {
        "confirmationCode": confirmationCode ?? "",
      }),
    );
  }

  static Future<ForgotPasswordResult> forgotPassword(String username) async {
    return ForgotPasswordResult.fromMsg(
      await invokeMethod("forgotPassword", {"username": username ?? ""}),
    );
  }

  static Future<ForgotPasswordResult> confirmForgotPassword(
    String username,
    String newPassword,
    String confirmationCode,
  ) async {
    return ForgotPasswordResult.fromMsg(
      await invokeMethod("confirmForgotPassword", {
        "username": username ?? "",
        "newPassword": newPassword ?? "",
        "confirmationCode": confirmationCode ?? "",
      }),
    );
  }

  static Future<UserState> getCurrentUserState() async {
    return UserState.values[await invokeMethod("currentUserState")];
  }

  static Future<void> signOut() async {
    await invokeMethod("signOut");
  }

  static Future<String> getUsername() async {
    return await invokeMethod("getUsername");
  }

  static Future<bool> isSignedIn() async {
    return await invokeMethod("isSignedIn");
  }

  static Future<String> getIdentityId() async {
    return await invokeMethod("getIdentityId");
  }

  static Future<Tokens> getTokens() async {
    return Tokens.fromMsg(await invokeMethod("getTokens"));
  }

  static Future<Map<String, String>> getUserAttributes() async {
    return Map<String, String>.from(await invokeMethod("getUserAttributes"));
  }

  static Future<List<UserCodeDeliveryDetails>> updateUserAttributes(
    Map<String, String> userAttributes,
  ) async {
    List uL = await invokeMethod("updateUserAttributes", {
      "userAttributes": userAttributes ?? {},
    });
    return List<UserCodeDeliveryDetails>.from(
      uL.map((u) => UserCodeDeliveryDetails.fromMsg(u)),
    );
  }

  static Future<void> confirmUpdateUserAttribute(
    String attributeName,
    String confirmationCode,
  ) async {
    await invokeMethod("confirmUpdateUserAttribute", {
      "attributeName": attributeName,
      "confirmationCode": confirmationCode,
    });
  }
}
