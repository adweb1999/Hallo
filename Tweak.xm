#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static const void *kCodeFieldAssociatedKey = &kCodeFieldAssociatedKey;

@interface LoginOverlay : NSObject
+ (void)showLoginScreen;
@end

@implementation LoginOverlay

+ (UIWindow *)getAppWindow {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        return window;
                    }
                }
            }
        }
    }
    
    NSArray *windows = [UIApplication sharedApplication].windows;
    if (windows.count > 0) {
        return windows.firstObject;
    }
    
    return nil;
}

+ (void)showLoginScreen {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [self getAppWindow];
        if (!window) return;

        if ([window viewWithTag:9999]) {
            return;
        }

        // 1. إنشاء شاشة الحجب الكاملة مع خاصية التمدد التلقائي عند الدوران
        UIView *loginView = [[UIView alloc] initWithFrame:window.bounds];
        loginView.backgroundColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.07 alpha:0.98];
        loginView.tag = 9999; 
        loginView.userInteractionEnabled = YES;
        
        // يجعل الخلفية تأخذ كامل مساحة الشاشة تلقائياً عند الدوران
        loginView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        // حاوية داخلية (Container) لوضع العناصر بداخلها لتبقى دائماً في المنتصف
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
        containerView.center = CGPointMake(loginView.bounds.size.width / 2, loginView.bounds.size.height / 2);
        
        // تجعل الحاوية تحافظ على موقعها في منتصف الشاشة تماماً عند تدوير الجهاز
        containerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [loginView addSubview:containerView];

        // 2. حقل إدخال الكود (داخل الحاوية)
        UITextField *codeField = [[UITextField alloc] initWithFrame:CGRectMake(0, 20, 320, 55)];
        codeField.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        codeField.textColor = [UIColor whiteColor];
        codeField.placeholder = @"أدخل كود التفعيل الخاص بك...";
        codeField.textAlignment = NSTextAlignmentCenter;
        codeField.layer.cornerRadius = 12;
        codeField.layer.borderWidth = 1.0;
        codeField.layer.borderColor = [UIColor darkGrayColor].CGColor;
        codeField.keyboardType = UIKeyboardTypeASCIICapable;
        codeField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:codeField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
        [containerView addSubview:codeField];

        // 3. زر التفعيل (داخل الحاوية)
        UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
        loginButton.frame = CGRectMake(0, 95, 320, 55);
        loginButton.backgroundColor = [UIColor systemBlueColor];
        [loginButton setTitle:@"تفعيل التطبيق" forState:UIControlStateNormal];
        [loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        loginButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        loginButton.layer.cornerRadius = 12;
        
        [loginButton addTarget:self action:@selector(verifyCodeAndDevice:) forControlEvents:UIControlEventTouchUpInside];
        [containerView addSubview:loginButton];

        [window addSubview:loginView];
        [window bringSubviewToFront:loginView];
        
        objc_setAssociatedObject(loginButton, kCodeFieldAssociatedKey, codeField, OBJC_ASSOCIATION_ASSIGN);
    });
}

+ (void)verifyCodeAndDevice:(UIButton *)sender {
    UITextField *codeField = objc_getAssociatedObject(sender, kCodeFieldAssociatedKey);
    if (!codeField) return;

    NSString *enteredCode = [codeField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (enteredCode.length == 0) {
        [sender setTitle:@"الرجاء كتابة الكود أولاً!" forState:UIControlStateNormal];
        sender.backgroundColor = [UIColor systemOrangeColor];
        return;
    }

    NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    if (!deviceId) deviceId = @"unknown_device_id";

    [sender setTitle:@"جاري التحقق من الجهاز والكود..." forState:UIControlStateNormal];
    sender.backgroundColor = [UIColor darkGrayColor];
    sender.enabled = NO;

    NSURL *url = [NSURL URLWithString:@"https://your-domain.com/api/verify.php"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSString *postString = [NSString stringWithFormat:@"code=%@&device_id=%@", enteredCode, deviceId];
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setTitle:@"خطأ في الاتصال بالخادم!" forState:UIControlStateNormal];
                sender.backgroundColor = [UIColor systemRedColor];
                sender.enabled = YES;
            });
            return;
        }

        NSError *jsonError;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if ([jsonResponse[@"status"] isEqualToString:@"success"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIWindow *window = [LoginOverlay getAppWindow];
                if (window) {
                    UIView *loginView = [window viewWithTag:9999];
                    if (loginView) {
                        [UIView animateWithDuration:0.3 animations:^{
                            loginView.alpha = 0.0;
                        } completion:^(BOOL finished) {
                            [loginView removeFromSuperview];
                        }];
                    }
                }
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *errorMessage = jsonResponse[@"message"] ? jsonResponse[@"message"] : @"فشل التحقق!";
                [sender setTitle:errorMessage forState:UIControlStateNormal];
                sender.backgroundColor = [UIColor systemRedColor];
                sender.enabled = YES;
            });
        }
    }];
    [task resume];
}

@end

static __attribute__((constructor)) void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [LoginOverlay showLoginScreen];
    });
}
