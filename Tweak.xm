// Tweak.xm - OneStateLogin (بدون API وبدون Device ID)

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==================== CONFIG ====================
#define CORRECT_USERNAME @"admin"
#define CORRECT_PASSWORD @"123456"

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
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 120, self.view.bounds.size.width, 60)];
    titleLabel.text = @"OneState Login";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:32];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:titleLabel];
    
    self.usernameField = [[UITextField alloc] initWithFrame:CGRectMake(40, 220, self.view.bounds.size.width - 80, 55)];
    self.usernameField.placeholder = @"Username";
    self.usernameField.borderStyle = UITextBorderStyleRoundedRect;
    self.usernameField.backgroundColor = [UIColor whiteColor];
    self.usernameField.font = [UIFont systemFontOfSize:18];
    self.usernameField.delegate = self;
    [self.view addSubview:self.usernameField];
    
    self.passwordField = [[UITextField alloc] initWithFrame:CGRectMake(40, 290, self.view.bounds.size.width - 80, 55)];
    self.passwordField.placeholder = @"Password";
    self.passwordField.secureTextEntry = YES;
    self.passwordField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordField.backgroundColor = [UIColor whiteColor];
    self.passwordField.font = [UIFont systemFontOfSize:18];
    self.passwordField.delegate = self;
    [self.view addSubview:self.passwordField];
    
    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.loginButton.frame = CGRectMake(40, 380, self.view.bounds.size.width - 80, 60);
    [self.loginButton setTitle:@"تسجيل الدخول" forState:UIControlStateNormal];
    self.loginButton.backgroundColor = [UIColor systemBlueColor];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.loginButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [self.loginButton addTarget:self action:@selector(loginButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 460, self.view.bounds.size.width - 80, 40)];
    self.statusLabel.textColor = [UIColor redColor];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:self.statusLabel];
}

- (void)loginButtonTapped {
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    if (username.length == 0 || password.length == 0) {
        self.statusLabel.text = @"يرجى ملء جميع الحقول";
        return;
    }
    
    self.loginButton.enabled = NO;
    self.statusLabel.text = @"جاري التحقق...";
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([username isEqualToString:CORRECT_USERNAME] && [password isEqualToString:CORRECT_PASSWORD]) {
            self.statusLabel.textColor = [UIColor greenColor];
            self.statusLabel.text = @"تم تسجيل الدخول بنجاح!";
            
            [UIView animateWithDuration:0.6 animations:^{
                self.view.alpha = 0.0;
            } completion:^(BOOL finished) {
                [self.view removeFromSuperview];
                [self removeFromParentViewController];
            }];
        } else {
            self.statusLabel.text = @"اسم المستخدم أو كلمة المرور خاطئة";
            self.loginButton.enabled = YES;
        }
    });
}

@end

// ==================== Helper Function to Get Key Window ====================
static UIWindow *getKeyWindow(void) {
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
        return nil;
    } else {
        return [[UIApplication sharedApplication] keyWindow];
    }
}

// ==================== HOOKS ====================

%hook UIApplication

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL orig = %orig;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = getKeyWindow();
        if (keyWindow) {
            OneStateLoginViewController *loginVC = [[OneStateLoginViewController alloc] init];
            loginVC.view.frame = keyWindow.bounds;
            [keyWindow addSubview:loginVC.view];
            [keyWindow bringSubviewToFront:loginVC.view];
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
                OneStateLoginViewController *loginVC = [[OneStateLoginViewController alloc] init];
                loginVC.view.frame = keyWindow.bounds;
                [keyWindow addSubview:loginVC.view];
                [keyWindow bringSubviewToFront:loginVC.view];
            }
        });
    });
}

%end

%ctor {
    %init;
    NSLog(@"[OneStateLogin] Tweak Loaded Successfully");
}
