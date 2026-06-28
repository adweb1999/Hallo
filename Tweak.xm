#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static const void *kCodeFieldAssociatedKey = &kCodeFieldAssociatedKey;

@interface LoginOverlay : NSObject
+ (void)showLoginScreen;
@end

@implementation LoginOverlay

// دالة جلب النافذة الرئيسية للتطبيق
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

// دالة لتجهيز الطلب وإضافة الكوكي (__test) لتخطي حماية السيرفر المجاني
+ (NSMutableURLRequest *)createSecureRequestWithURL:(NSString *)urlString jsonDict:(NSDictionary *)jsonDict {
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // محاكاة المتصفح بالكامل لتجنب الحجب
    [request setValue:@"Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1" forHTTPHeaderField:@"User-Agent"];
    
    // القيمة الناتجة عن فك تشفير كود الـ AES الخاص بسيرفرك (تتغير كل بضعة أشهر من الاستضافة تلقائياً)
    // إذا توقف التفعيل فجأة، ستحتاج فقط لتحديث هذه القيمة بناءً على كود المتصفح الجديد
    NSString *cookieValue = @"b6d4949219e1f5ec13b351336fa09bf4"; 
    [request setValue:[NSString stringWithFormat:@"__test=%@;", cookieValue] forHTTPHeaderField:@"Cookie"];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
    [request setHTTPBody:jsonData];
    
    return request;
}

+ (void)showLoginScreen {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [self getAppWindow];
        if (!window) return;

        if ([window viewWithTag:9999]) {
            return;
        }

        // إنشاء شاشة الحجب الكاملة وتدعم الدوران تلقائياً
        UIView *loginView = [[UIView alloc] initWithFrame:window.bounds];
        loginView.backgroundColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.07 alpha:0.98];
        loginView.tag = 9999; 
        loginView.userInteractionEnabled = YES;
        loginView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
        containerView.center = CGPointMake(loginView.bounds.size.width / 2, loginView.bounds.size.height / 2);
        containerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [loginView addSubview:containerView];

        // حقل إدخال الكود
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

        // زر التفعيل
        UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
        loginButton.frame = CGRectMake(0, 95, 320, 55);
        loginButton.backgroundColor = [UIColor systemBlueColor];
        [loginButton setTitle:@"تفعيل التطبيق" forState:UIControlStateNormal];
        [loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        loginButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        loginButton.layer.cornerRadius = 12;
        
        [loginButton addTarget:self action:@selector(activateCode:) forControlEvents:UIControlEventTouchUpInside];
        [containerView addSubview:loginButton];

        [window addSubview:loginView];
        [window bringSubviewToFront:loginView];
        
        objc_setAssociatedObject(loginButton, kCodeFieldAssociatedKey, codeField, OBJC_ASSOCIATION_ASSIGN);
    });
}

// دالة التفعيل (تستدعي activate.php مع الكوكي المخترق)
+ (void)activateCode:(UIButton *)sender {
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

    [sender setTitle:@"جاري التفعيل..." forState:UIControlStateNormal];
    sender.backgroundColor = [UIColor darkGrayColor];
    sender.enabled = NO;

    // تجهيز الطلب الآمن عبر الدالة الجديدة لكسر الحماية لقسم تفعيل الكود
    NSDictionary *jsonDict = @{@"code": enteredCode, @"device_id": deviceId};
    NSMutableURLRequest *request = [self createSecureRequestWithURL:@"https://spin.zya.me/api/license/activate.php" jsonDict:jsonDict];

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
        
        if (jsonResponse && [jsonResponse[@"status"] isEqualToString:@"success"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSUserDefaults standardUserDefaults] setObject:enteredCode forKey:@"SavedLicenseCode"];
                [[NSUserDefaults standardUserDefaults] setObject:deviceId forKey:@"SavedDeviceID"];
                [[NSUserDefaults standardUserDefaults] synchronize];

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
                NSString *errorMessage = jsonResponse[@"message"] ? jsonResponse[@"message"] : @"فشل التفعيل أو السيرفر محجوب!";
                [sender setTitle:errorMessage forState:UIControlStateNormal];
                sender.backgroundColor = [UIColor systemRedColor];
                sender.enabled = YES;
            });
        }
    }];
    [task resume];
}

// دالة صامتة لفحص حالة الكود عند فتح التطبيق مجدداً (تستدعي check.php مع الكوكي)
+ (void)checkSavedLicenseStatus {
    NSString *savedCode = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedLicenseCode"];
    NSString *savedDevice = [[NSUserDefaults standardUserDefaults] stringForKey:@"SavedDeviceID"];
    
    if (!savedCode || !savedDevice) {
        [LoginOverlay showLoginScreen];
        return;
    }
    
    NSDictionary *jsonDict = @{@"code": savedCode, @"device_id": savedDevice};
    NSMutableURLRequest *request = [self createSecureRequestWithURL:@"https://spin.zya.me/api/license/check.php" jsonDict:jsonDict];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data) {
            return;
        }
        
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        if (jsonResponse && ![jsonResponse[@"status"] isEqualToString:@"success"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SavedLicenseCode"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [LoginOverlay showLoginScreen];
            });
        }
    }];
    [task resume];
}

@end

static __attribute__((constructor)) void initialize() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [LoginOverlay checkSavedLicenseStatus];
    });
}
