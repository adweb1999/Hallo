// Tweak.xm - OneStateLogin (كود التفعيل + Device ID)

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface LoginOverlay : NSObject
+ (void)showLoginScreen;
@end

@implementation LoginOverlay

+ (void)showLoginScreen {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;
        
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        } else {
            window = [UIApplication sharedApplication].keyWindow;
        }
        
        if (!window) window = [[UIApplication sharedApplication].windows firstObject];
        if (!window) return;
        
        if ([window viewWithTag:9999]) return;
        
        UIView *loginView = [[UIView alloc] initWithFrame:window.bounds];
        loginView.backgroundColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.07 alpha:0.98];
        loginView.tag = 9999;
        loginView.userInteractionEnabled = YES;
        
        // Title
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, window.bounds.size.width, 60)];
        title.text = @"تفعيل OneState";
        title.textColor = [UIColor whiteColor];
        title.font = [UIFont boldSystemFontOfSize:32];
        title.textAlignment = NSTextAlignmentCenter;
        [loginView addSubview:title];
        
        // Code Field
        UITextField *codeField = [[UITextField alloc] initWithFrame:CGRectMake(40, window.bounds.size.height / 2 - 60, window.bounds.size.width - 80, 55)];
        codeField.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        codeField.textColor = [UIColor whiteColor];
        codeField.placeholder = @"أدخل كود التفعيل";
        codeField.textAlignment = NSTextAlignmentCenter;
        codeField.layer.cornerRadius = 12;
        codeField.layer.borderWidth = 1.0;
        codeField.layer.borderColor = [UIColor darkGrayColor].CGColor;
        codeField.keyboardType = UIKeyboardTypeASCIICapable;
        [loginView addSubview:codeField];
        
        // Activate Button
        UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
        loginButton.frame = CGRectMake(40, window.bounds.size.height / 2 + 20, window.bounds.size.width - 80, 55);
        loginButton.backgroundColor = [UIColor systemBlueColor];
        [loginButton setTitle:@"تفعيل التطبيق" forState:UIControlStateNormal];
        [loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        loginButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        loginButton.layer.cornerRadius = 12;
        
        [loginButton addTarget:self action:@selector(verifyCodeAndDevice:) forControlEvents:UIControlEventTouchUpInside];
        [loginView addSubview:loginButton];
        
        [window addSubview:loginView];
        [window bringSubviewToFront:loginView];
        
        objc_setAssociatedObject(loginButton, @"codeField", codeField, OBJC_ASSOCIATION_ASSIGN);
    });
}

+ (void)verifyCodeAndDevice:(UIButton *)sender {
    UITextField *codeField = objc_getAssociatedObject(sender, @"codeField");
    NSString *enteredCode = [codeField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (enteredCode.length == 0) {
        [sender setTitle:@"الرجاء إدخال الكود" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor systemOrangeColor];
        return;
    }
    
    NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString] ?: @"unknown";
    
    [sender setTitle:@"جاري التحقق..." forState:UIControlStateNormal];
    sender.backgroundColor = [UIColor darkGrayColor];
    sender.enabled = NO;
    
    // غير الرابط حسب سيرفرك
    NSURL *url = [NSURL URLWithString:@"https://your-domain.com/api/verify.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *postString = [NSString stringWithFormat:@"code=%@&device_id=%@", enteredCode, deviceId];
    request.HTTPBody = [postString dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data) {
                [sender setTitle:@"خطأ في الاتصال بالسيرفر" forState:UIControlStateNormal];
                sender.backgroundColor = [UIColor systemRedColor];
                sender.enabled = YES;
                return;
            }
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            if ([json[@"status"] isEqualToString:@"success"]) {
                UIView *loginView = [[UIApplication sharedApplication].keyWindow viewWithTag:9999];
                if (loginView) {
                    [UIView animateWithDuration:0.5 animations:^{
                        loginView.alpha = 0;
                    } completion:^(BOOL finished) {
                        [loginView removeFromSuperview];
                    }];
                }
            } else {
                NSString *msg = json[@"message"] ?: @"كود غير صحيح أو مستخدم";
                [sender setTitle:msg forState:UIControlStateNormal];
                sender.backgroundColor = [UIColor systemRedColor];
                sender.enabled = YES;
            }
        });
    }];
    [task resume];
}

@end

// ==================== INITIALIZER ====================
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [LoginOverlay showLoginScreen];
    });
    
    NSLog(@"[OneStateLogin] Activated - Code Login System");
}
