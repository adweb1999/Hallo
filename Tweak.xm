// Tweak.xm - OneStateLogin (JSONBin - Fixed)

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
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, 70)];
    title.text = @"OneState Login";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:32];
    title.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:title];
    
    self.usernameField = [[UITextField alloc] initWithFrame:CGRectMake(40, 200, self.view.bounds.size.width-80, 55)];
    self.usernameField.placeholder = @"اسم المستخدم";
    self.usernameField.borderStyle = UITextBorderStyleRoundedRect;
    self.usernameField.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.usernameField];
    
    self.passwordField = [[UITextField alloc] initWithFrame:CGRectMake(40, 270, self.view.bounds.size.width-80, 55)];
    self.passwordField.placeholder = @"كلمة المرور";
    self.passwordField.secureTextEntry = YES;
    self.passwordField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordField.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.passwordField];
    
    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.loginButton.frame = CGRectMake(40, 350, self.view.bounds.size.width-80, 60);
    [self.loginButton setTitle:@"تسجيل الدخول" forState:UIControlStateNormal];
    self.loginButton.backgroundColor = [UIColor systemBlueColor];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [self.loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 430, self.view.bounds.size.width-80, 70)];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 3;
    self.statusLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:self.statusLabel];
}

- (NSString *)getDeviceID {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

- (void)loginTapped {
    NSString *user = [self.usernameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *pass = [self.passwordField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (user.length == 0 || pass.length == 0) {
        self.statusLabel.textColor = [UIColor redColor];
        self.statusLabel.text = @"يرجى ملء اسم المستخدم وكلمة المرور";
        return;
    }
    
    self.loginButton.enabled = NO;
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.text = @"جاري الاتصال بالخادم...";
    
    [self checkLogin:user password:pass];
}

- (void)checkLogin:(NSString *)username password:(NSString *)password {
    NSURL *url = [NSURL URLWithString:JSON_BIN_URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:MASTER_KEY forHTTPHeaderField:@"X-Master-Key"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.statusLabel.textColor = [UIColor redColor];
                self.statusLabel.text = [NSString stringWithFormat:@"خطأ في الاتصال: %@", error.localizedDescription];
                self.loginButton.enabled = YES;
                return;
            }
            
            if (!data) {
                self.statusLabel.text = @"لا يوجد رد من الخادم";
                self.loginButton.enabled = YES;
                return;
            }
            
            NSError *jsonError = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            
            if (jsonError || !json) {
                self.statusLabel.text = @"خطأ في البيانات المستلمة";
                self.loginButton.enabled = YES;
                return;
            }
            
            NSArray *users = json[@"record"][@"users"];
            if (!users) {
                self.statusLabel.text = @"هيكل البيانات غير صحيح";
                self.loginButton.enabled = YES;
                return;
            }
            
            for (NSDictionary *u in users) {
                if ([u[@"username"] isEqualToString:username] && [u[@"password"] isEqualToString:password]) {
                    
                    NSDateFormatter *f = [[NSDateFormatter alloc] init];
                    f.dateFormat = @"yyyy-MM-dd";
                    NSDate *expiry = [f dateFromString:u[@"expiry"]];
                    
                    if (!expiry || [[NSDate date] compare:expiry] == NSOrderedDescending) {
                        self.statusLabel.text = @"انتهت صلاحية الاشتراك";
                    } else if (![u[@"device_id"] isEqualToString:@"ALL"] && ![u[@"device_id"] isEqualToString:[self getDeviceID]]) {
                        self.statusLabel.text = @"هذا الجهاز غير مسجل";
                    } else {
                        self.statusLabel.textColor = [UIColor greenColor];
                        self.statusLabel.text = @"✅ تم تسجيل الدخول بنجاح!";
                        [self hideLoginScreen];
                        return;
                    }
                    self.loginButton.enabled = YES;
                    return;
                }
            }
            
            self.statusLabel.textColor = [UIColor redColor];
            self.statusLabel.text = @"اسم المستخدم أو كلمة المرور خاطئة";
            self.loginButton.enabled = YES;
        });
    }];
    
    [task resume];
}

- (void)hideLoginScreen {
    [UIView animateWithDuration:0.5 animations:^{
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];
}

@end

// ==================== Key Window & Hooks ====================
static UIWindow *getKeyWindow(void) {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) return window;
                }
            }
        }
        return nil;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return UIApplication.sharedApplication.keyWindow;
#pragma clang diagnostic pop
    }
}

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
    NSLog(@"[OneStateLogin] Fixed Version Loaded");
}
