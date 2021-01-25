import Flutter
import plugin_scaffold
import UIKit
import AWSMobileClient

let pkgName = "com.pycampers.flutter_cognito_plugin"

open class CognitoPluginAppDelegate: FlutterAppDelegate {
    public static var navigationController: UINavigationController?

    open override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let navigationController = UINavigationController(rootViewController: window.rootViewController!)
        navigationController.isNavigationBarHidden = true
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        CognitoPluginAppDelegate.navigationController = navigationController
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    open override func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        AWSMobileClient.default().handleAuthResponse(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
        return true
    }
}

public class SwiftFlutterCognitoPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let plugin = Cognito()
        let channel = createPluginScaffold(
            messenger: registrar.messenger(),
            channelName: "com.pycampers.flutter_cognito_plugin",
            methodMap: [
                "initialize": plugin.initialize,
                "signUp": plugin.signUp,
                "confirmSignUp": plugin.confirmSignUp,
                "resendSignUp": plugin.resendSignUp,
                "signIn": plugin.signIn,
                "confirmSignIn": plugin.confirmSignIn,
                "changePassword": plugin.changePassword,
                "forgotPassword": plugin.forgotPassword,
                "confirmForgotPassword": plugin.confirmForgotPassword,
                "signOut": plugin.signOut,
                "getUsername": plugin.getUsername,
                "isSignedIn": plugin.isSignedIn,
                "getIdentityId": plugin.getIdentityId,
                "currentUserState": plugin.currentUserState,
                "getUserAttributes": plugin.getUserAttributes,
                "updateUserAttributes": plugin.updateUserAttributes,
                "confirmUpdateUserAttribute": plugin.confirmUpdateUserAttribute,
                "getTokens": plugin.getTokens,
                "getCredentials": plugin.getCredentials,
                "federatedSignIn": plugin.federatedSignIn,
                "showSignIn": plugin.showSignIn,
            ]
        )
        plugin.userStateCallback = { userState, _ in
            channel.invokeMethod("userStateCallback", arguments: dumpUserState(userState))
        }
    }
}
