// Tweak.xm - OneStateLogin (نسخة نظيفة ومستقرة)

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==================== CONFIG ====================
#define JSON_BIN_URL @"https://api.jsonbin.io/v3/b/6a4071d6f5f4af5e293b11e4/latest"
#define MASTER_KEY @"$2a$10$0Z3J8lUjgst.0aESOMXKukNSTXEjRAcTUwzYeV5RS8r6N4HDCbg6"

// ==================== LOGIN CONTROLLER ====================
@interface OneStateLoginViewController : UIViewController
@property (nonatomic, strong) UITextField *usernameField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation OneStateLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    
    // Title
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, self.view.frame.size.width, 60)];
    title.text = @"OneState Login";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:30];
    title.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:title];
    
    // Username
    self.usernameField = [[UITextField alloc] initWithFrame:CGRectMake(40, 180, self.view.frame.size.width - 80, 50)];
    self.usernameField.placeholder = @"اسم المستخدم";
    self.usernameField.borderStyle = UITextBorderStyleRoundedRect;
    self.usernameField.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.usernameField];
    
    // Password
    self.passwordField = [[UITextField alloc] initWithFrame:CGRectMake(40, 250, self.view.frame.size.width - 80, 50)];
    self.passwordField.placeholder = @"كلمة المرور";
    self.passwordField.secureTextEntry = YES;
    self.passwordField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordField.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.passwordField];
    
    // Login Button
    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.loginButton.frame = CGRectMake(40, 330, self.view.frame.size.width - 80, 55);
    [self.loginButton setTitle:@"تسجيل الدخول" forState:UIControlStateNormal];
    self.loginButton.backgroundColor = [UIColor systemBlueColor];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.loginButton addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton];
    
    // Status
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 410, self.view.frame.size.width - 80, 80)];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.statusLabel];
}

- (void)loginTapped {
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    if (username.length == 0 || password.length == 0) {
        self.statusLabel.textColor = [UIColor redColor];
        self.statusLabel.text = @"يرجى ملء الحقول";
        return;
    }
    
    self.loginButton.enabled = NO;
    self.statusLabel.textColor = [UIColor yellowColor];
    self.statusLabel.text = @"جاري التحقق...";
    
    [self verifyLogin:username password:password];
}

- (void)verifyLogin:(NSString *)username password:(NSString *)password {
    NSURL *url = [NSURL URLWithString:JSON_BIN_URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:MASTER_KEY forHTTPHeaderField:@"X-Master-Key"];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.statusLabel.textColor = [UIColor redColor];
                self.statusLabel.text = @"خطأ في الاتصال";
                self.loginButton.enabled = YES;
                return;
            }
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray *users = json[@"record"][@"users"];
            
            for (NSDictionary *user in users) {
                if ([user[@"username"] isEqualToString:username] && [user[@"password"] isEqualToString:password]) {
                    self.statusLabel.textColor = [UIColor greenColor];
                    self.statusLabel.text = @"✅ تم تسجيل الدخول بنجاح";
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        [self hideLogin];
                    });
                    return;
                }
            }
            
            self.statusLabel.textColor = [UIColor redColor];
            self.statusLabel.text = @"بيانات خاطئة";
            self.loginButton.enabled = YES;
        });
    }];
    [task resume];
}

- (void)hideLogin {
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

@end

// ==================== HOOKS ====================
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

%hook UIApplication
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL orig = %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
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

%ctor {
    %init;
    NSLog(@"[OneStateLogin] Simple Stable Version Loaded");
}
