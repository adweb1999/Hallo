// Tweak.xm - OneStateLogin (JSONBin Version)

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==================== CONFIG ====================
#define JSON_BIN_URL @"https://api.jsonbin.io/v3/b/6a4071d6f5f4af5e293b11e4/latest"
#define MASTER_KEY @"$2a$10$0Z3J8lUjgst.0aESOMXKukNSTXEjRAcTUwzYeV5RS8r6N4HDCbg6"

// ==================== LOGIN VIEW ====================
@interface OneStateLoginViewController : UIViewController <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation OneStateLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 120, self.view.bounds.size.width, 60)];
    title.text = @"OneState Login";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:30];
    title.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:title];
    
    self.usernameField = [[UITextField alloc] initWithFrame:CGRectMake(40, 220, self.view.bounds.size.width-80, 50)];
    self.usernameField.placeholder = @"اسم المستخدم";
    self.usernameField.borderStyle = UITextBorderStyleRoundedRect;
    self.usernameField.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.usernameField];
    
    self.passwordField = [[UITextField alloc] initWithFrame:CGRectMake(40, 280, self.view.bounds.size.width-80, 50)];
    self.passwordField.placeholder = @"كلمة المرور";
    self.passwordField.secureTextEntry = YES;
    self.passwordField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordField.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.passwordField];
    
    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.loginButton.frame = CGRectMake(40, 350, self.view.bounds.size.width-80, 55);
    [self.loginButton setTitle:@"تسجيل الدخول" forState:UIControlStateNormal];
    self.loginButton.backgroundColor = [UIColor systemBlueColor];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 420, self.view.bounds.size.width-80, 60)];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 2;
    self.statusLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:self.statusLabel];
}

- (NSString *)getDeviceID {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

- (void)loginTapped {
    NSString *user = self.usernameField.text;
    NSString *pass = self.passwordField.text;
    
    if (user.length == 0 || pass.length == 0) {
        self.statusLabel.text = @"يرجى ملء الحقول";
        return;
    }
    
    self.loginButton.enabled = NO;
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.text = @"جاري التحقق...";
    
    [self checkLogin:user password:pass];
}

- (void)checkLogin:(NSString *)username password:(NSString *)password {
    NSURL *url = [NSURL URLWithString:JSON_BIN_URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:MASTER_KEY forHTTPHeaderField:@"X-Master-Key"];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data) {
                self.statusLabel.text = @"خطأ في الاتصال بالخادم";
                self.loginButton.enabled = YES;
                return;
            }
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray *users = json[@"record"][@"users"];
            
            for (NSDictionary *u in users) {
                if ([u[@"username"] isEqualToString:username] && [u[@"password"] isEqualToString:password]) {
                    
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    formatter.dateFormat = @"yyyy-MM-dd";
                    NSDate *expiryDate = [formatter dateFromString:u[@"expiry"]];
                    
                    if ([[NSDate date] compare:expiryDate] == NSOrderedDescending) {
                        self.statusLabel.text = @"انتهت صلاحية الاشتراك";
                    } else if (![u[@"device_id"] isEqualToString:@"ALL"] && ![u[@"device_id"] isEqualToString:[self getDeviceID]]) {
                        self.statusLabel.text = @"هذا الجهاز غير مسجل";
                    } else {
                        self.statusLabel.textColor = [UIColor greenColor];
                        self.statusLabel.text = @"تم تسجيل الدخول بنجاح!";
                        [self hideLogin];
                        return;
                    }
                    self.loginButton.enabled = YES;
                    return;
                }
            }
            self.statusLabel.text = @"اسم المستخدم أو كلمة المرور خاطئة";
            self.loginButton.enabled = YES;
        });
    }];
    [task resume];
}

- (void)hideLogin {
    [UIView animateWithDuration:0.6 animations:^{
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];
}

@end

// ==================== KeyWindow & Hooks (انسخ من الردود السابقة) ====================

static UIWindow *getKeyWindow(void) {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *w in scene.windows) if (w.isKeyWindow) return w;
            }
        }
        return nil;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [[UIApplication sharedApplication] keyWindow];
#pragma clang diagnostic pop
    }
}

// Hooks...
%hook UIApplication
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL orig = %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *kw = getKeyWindow();
        if (kw) {
            OneStateLoginViewController *vc = [[OneStateLoginViewController alloc] init];
            vc.view.frame = kw.bounds;
            [kw addSubview:vc.view];
            [kw bringSubviewToFront:vc.view];
        }
    });
    return orig;
}
%end

%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            UIWindow *kw = getKeyWindow();
            if (kw) {
                OneStateLoginViewController *vc = [[OneStateLoginViewController alloc] init];
                vc.view.frame = kw.bounds;
                [kw addSubview:vc.view];
                [kw bringSubviewToFront:vc.view];
            }
        });
    });
}
%end

%ctor {
    %init;
    NSLog(@"[OneStateLogin] JSONBin Version Loaded");
}
