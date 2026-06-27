// Tweak.xm - OneStateLogin Online Version

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==================== CONFIG ====================
// ←←← غير هذين السطرين فقط ←←←

#define API_ENDPOINT @"https://script.google.com/macros/s/YOUR_WEB_APP_URL_HERE/exec"

#define SHARED_SECRET @"your-secret-key-here"     // ←← يجب أن يكون نفس المفتاح في Google Apps Script

// ==================== LOGIN VIEW CONTROLLER ====================
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
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, 70)];
    titleLabel.text = @"OneState Login";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:32];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];
    
    self.usernameField = [[UITextField alloc] initWithFrame:CGRectMake(40, 200, self.view.bounds.size.width - 80, 55)];
    self.usernameField.placeholder = @"اسم المستخدم";
    self.usernameField.borderStyle = UITextBorderStyleRoundedRect;
    self.usernameField.backgroundColor = [UIColor whiteColor];
    self.usernameField.font = [UIFont systemFontOfSize:18];
    self.usernameField.delegate = self;
    [self.view addSubview:self.usernameField];
    
    self.passwordField = [[UITextField alloc] initWithFrame:CGRectMake(40, 270, self.view.bounds.size.width - 80, 55)];
    self.passwordField.placeholder = @"كلمة المرور";
    self.passwordField.secureTextEntry = YES;
    self.passwordField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordField.backgroundColor = [UIColor whiteColor];
    self.passwordField.font = [UIFont systemFontOfSize:18];
    self.passwordField.delegate = self;
    [self.view addSubview:self.passwordField];
    
    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.loginButton.frame = CGRectMake(40, 350, self.view.bounds.size.width - 80, 60);
    [self.loginButton setTitle:@"تسجيل الدخول" forState:UIControlStateNormal];
    self.loginButton.backgroundColor = [UIColor systemBlueColor];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [self.loginButton addTarget:self action:@selector(loginButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 430, self.view.bounds.size.width - 80, 50)];
    self.statusLabel.textColor = [UIColor redColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 2;
    self.statusLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:self.statusLabel];
}

- (NSString *)getDeviceID {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

- (void)loginButtonTapped {
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    if (username.length == 0 || password.length == 0) {
        self.statusLabel.text = @"يرجى ملء جميع الحقول";
        return;
    }
    
    self.loginButton.enabled = NO;
    self.statusLabel.textColor = [UIColor whiteColor];
    self.statusLabel.text = @"جاري التحقق من الخادم...";
    
    [self verifyWithAPI:username password:password];
}

- (void)verifyWithAPI:(NSString *)username password:(NSString *)password {
    NSURL *url = [NSURL URLWithString:API_ENDPOINT];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *body = @{
        @"username": username,
        @"password": password,
        @"device_id": [self getDeviceID],
        @"secret": SHARED_SECRET
    };
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    request.HTTPBody = jsonData;
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data) {
                self.statusLabel.text = @"خطأ في الاتصال بالخادم";
                self.loginButton.enabled = YES;
                return;
            }
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            BOOL success = [json[@"success"] boolValue];
            
            if (success) {
                self.statusLabel.textColor = [UIColor greenColor];
                self.statusLabel.text = @"تم تسجيل الدخول بنجاح!";
                
                [UIView animateWithDuration:0.6 animations:^{
                    self.view.alpha = 0.0;
                } completion:^(BOOL finished) {
                    [self.view removeFromSuperview];
                    [self removeFromParentViewController];
                }];
            } else {
                self.statusLabel.textColor = [UIColor redColor];
                self.statusLabel.text = json[@"message"] ?: @"فشل التحقق";
                self.loginButton.enabled = YES;
            }
        });
    }];
    
    [task resume];
}

@end

// ==================== Safe Key Window ====================
static UIWindow *getKeyWindow(void) {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
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
        return [[UIApplication sharedApplication] keyWindow];
#pragma clang diagnostic pop
    }
}

// ==================== HOOKS ====================

%hook UIApplication
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL orig = %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = getKeyWindow();
        if (keyWindow) {
            OneStateLoginViewController *vc = [[OneStateLoginViewController alloc] init];
            vc.view.frame = keyWindow.bounds;
            [keyWindow addSubview:vc.view];
            [keyWindow bringSubviewToFront:vc.view];
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIWindow *keyWindow = getKeyWindow();
            if (keyWindow) {
                OneStateLoginViewController *vc = [[OneStateLoginViewController alloc] init];
                vc.view.frame = keyWindow.bounds;
                [keyWindow addSubview:vc.view];
                [keyWindow bringSubviewToFront:vc.view];
            }
        });
    });
}
%end

%ctor {
    %init;
    NSLog(@"[OneStateLogin] Online Version Loaded");
}
