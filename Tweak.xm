#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static BOOL g_loginShown = NO;
static BOOL g_loginSuccess = NO;

// Forward declaration
@interface UIWindow (Login)
- (void)showLoginAlert;
@end

BOOL checkAPI(NSString *username, NSString *password, NSString *deviceID) {
    return [username isEqualToString:@"admin"] && [password isEqualToString:@"123456"];
}

%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!g_loginShown && !g_loginSuccess) {
            [self showLoginAlert];
        }
    });
}

%new
- (void)showLoginAlert {
    if (g_loginSuccess) return;
    g_loginShown = YES;

    NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];

    NSString *msg = [NSString stringWithFormat:@"App: %@ | Device: %@", appName, deviceID];

    UIAlertController *alert = [UIAlertController 
        alertControllerWithTitle:@"Login Required" 
        message:msg 
        preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Username";
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Password";
        textField.secureTextEntry = YES;
    }];

    UIAlertAction *loginAction = [UIAlertAction 
        actionWithTitle:@"Login" 
        style:UIAlertActionStyleDefault 
        handler:^(UIAlertAction *action) {
            NSString *username = alert.textFields[0].text;
            NSString *password = alert.textFields[1].text;

            if ([username length] == 0 || [password length] == 0) {
                g_loginShown = NO;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self showLoginAlert];
                });
                return;
            }

            BOOL success = checkAPI(username, password, deviceID);

            if (success) {
                g_loginSuccess = YES;

                UIAlertController *successAlert = [UIAlertController 
                    alertControllerWithTitle:@"Welcome" 
                    message:@"Login successful!" 
                    preferredStyle:UIAlertControllerStyleAlert];

                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                [successAlert addAction:ok];

                UIViewController *rootVC = [self rootViewController];
                [rootVC presentViewController:successAlert animated:YES completion:nil];

            } else {
                g_loginShown = NO;

                UIAlertController *errorAlert = [UIAlertController 
                    alertControllerWithTitle:@"Error" 
                    message:@"Invalid username or password" 
                    preferredStyle:UIAlertControllerStyleAlert];

                UIAlertAction *retry = [UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self showLoginAlert];
                }];

                [errorAlert addAction:retry];

                UIViewController *rootVC = [self rootViewController];
                [rootVC presentViewController:errorAlert animated:YES completion:nil];
            }
        }];

    UIAlertAction *cancelAction = [UIAlertAction 
        actionWithTitle:@"Cancel" 
        style:UIAlertActionStyleCancel 
        handler:^(UIAlertAction *action) {
            g_loginShown = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self showLoginAlert];
            });
        }];

    [alert addAction:loginAction];
    [alert addAction:cancelAction];

    UIViewController *rootVC = [self rootViewController];
    if (rootVC) {
        [rootVC presentViewController:alert animated:YES completion:nil];
    }
}

%end

%ctor {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];

    NSLog(@"[OneStateLogin] ============================");
    NSLog(@"[OneStateLogin] dylib loaded!");
    NSLog(@"[OneStateLogin] App: %@", appName);
    NSLog(@"[OneStateLogin] Bundle: %@", bundleID);
    NSLog(@"[OneStateLogin] Works on ANY app!");
    NSLog(@"[OneStateLogin] ============================");
}
