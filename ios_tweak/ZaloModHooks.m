//
//  ZaloModHooks.m
//  ZaloMod VIP - Runtime Method Swizzling & Tweak Injection
//  Thương hiệu: DucLamXNgBao
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "ZaloFloatingButton.h"
#import "ZaloModViewController.h"
#import "ZaloModFontHelper.h"

// =========================================================================
// 1. FLOATING WINDOW (CỤC MENU TRÒN CHẠM XUYÊN THẤU)
// =========================================================================
@interface ZaloFloatingWindow : UIWindow
@end

@implementation ZaloFloatingWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self || hitView == self.rootViewController.view) {
        return nil; // Cho phép chạm xuyên thấu xuống Zalo!
    }
    return hitView;
}
@end

static ZaloFloatingWindow *gFloatingWindow = nil;

@interface ZaloModManager : NSObject <ZaloFloatingButtonDelegate, ZaloModViewControllerDelegate>
+ (instancetype)sharedManager;
- (void)setupFloatingButton;
@end

@implementation ZaloModManager

+ (instancetype)sharedManager {
    static ZaloModManager *mgr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[ZaloModManager alloc] init];
    });
    return mgr;
}

- (void)setupFloatingButton {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if (gFloatingWindow && !gFloatingWindow.hidden && [ZaloFloatingButton sharedInstance].superview) {
                return;
            }

            UIWindowScene *scene = nil;
            if (@available(iOS 13.0, *)) {
                for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
                    if ([s isKindOfClass:[UIWindowScene class]]) {
                        scene = (UIWindowScene *)s;
                        if (s.activationState == UISceneActivationStateForegroundActive) {
                            break;
                        }
                    }
                }
            }

            if (!gFloatingWindow) {
                if (@available(iOS 13.0, *)) {
                    if (scene) {
                        gFloatingWindow = [[ZaloFloatingWindow alloc] initWithWindowScene:scene];
                    } else {
                        gFloatingWindow = [[ZaloFloatingWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                    }
                } else {
                    gFloatingWindow = [[ZaloFloatingWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                }
            } else {
                if (@available(iOS 13.0, *)) {
                    if (scene) {
                        gFloatingWindow.windowScene = scene;
                    }
                }
            }

            gFloatingWindow.windowLevel = UIWindowLevelAlert + 1000.0;
            gFloatingWindow.backgroundColor = [UIColor clearColor];
            gFloatingWindow.hidden = NO;

            if (!gFloatingWindow.rootViewController) {
                UIViewController *rootVC = [[UIViewController alloc] init];
                rootVC.view.backgroundColor = [UIColor clearColor];
                rootVC.view.userInteractionEnabled = YES;
                gFloatingWindow.rootViewController = rootVC;
            }

            ZaloFloatingButton *bubble = [ZaloFloatingButton sharedInstance];
            bubble.delegate = self;
            if (bubble.superview != gFloatingWindow.rootViewController.view) {
                [bubble removeFromSuperview];
                [gFloatingWindow.rootViewController.view addSubview:bubble];
            }
            [bubble show];

            NSLog(@"[DucLamXNgBao] Đã khởi tạo Cục Menu Tròn Zalo VIP Mod thành công!");
        } @catch (NSException *exception) {
            NSLog(@"[DucLamXNgBao] Exception initializing floating button: %@", exception);
        }
    });
}

#pragma mark - ZaloFloatingButtonDelegate
- (void)floatingButtonDidTap:(id)sender {
    UIViewController *rootVC = gFloatingWindow.rootViewController;
    if (!rootVC) return;

    ZaloModViewController *menuVC = [ZaloModViewController sharedInstance];
    menuVC.delegate = self;
    [menuVC showMenuFromViewController:rootVC];
}

- (void)modMenuDidDismiss {
}

@end

// =========================================================================
// 2. HELPER SWIZZLING
// =========================================================================
static void swizzleInstanceMethod(Class cls, SEL origSel, SEL swizSel) {
    if (!cls) return;
    Method origMethod = class_getInstanceMethod(cls, origSel);
    Method swizMethod = class_getInstanceMethod(cls, swizSel);
    if (origMethod && swizMethod) {
        if (class_addMethod(cls, origSel, method_getImplementation(swizMethod), method_getTypeEncoding(swizMethod))) {
            class_replaceMethod(cls, swizSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
        } else {
            method_exchangeImplementations(origMethod, swizMethod);
        }
    }
}

static void swizzleClassMethod(Class cls, SEL origSel, SEL swizSel) {
    if (!cls) return;
    Method origMethod = class_getClassMethod(cls, origSel);
    Method swizMethod = class_getClassMethod(cls, swizSel);
    if (origMethod && swizMethod) {
        method_exchangeImplementations(origMethod, swizMethod);
    }
}

// =========================================================================
// 3. FONT HOOK (12 FONT CHỮ NGHỆ THUẬT KHI NHẬP VÀ GỬI TIN NHẮN)
// =========================================================================
@interface UITextView (ZaloModFontHook)
@end

@implementation UITextView (ZaloModFontHook)
- (void)zaloMod_insertText:(NSString *)text {
    NSString *selectedFont = [[NSUserDefaults standardUserDefaults] stringForKey:@"ZaloMod_SelectedFont"];
    if (selectedFont && ![selectedFont isEqualToString:@"Tắt"] && text.length > 0) {
        NSString *converted = [ZaloModFontHelper convertText:text toStyle:selectedFont];
        [self zaloMod_insertText:converted];
    } else {
        [self zaloMod_insertText:text];
    }
}
@end

@interface UITextField (ZaloModFontHook)
@end

@implementation UITextField (ZaloModFontHook)
- (void)zaloMod_insertText:(NSString *)text {
    NSString *selectedFont = [[NSUserDefaults standardUserDefaults] stringForKey:@"ZaloMod_SelectedFont"];
    if (selectedFont && ![selectedFont isEqualToString:@"Tắt"] && text.length > 0) {
        NSString *converted = [ZaloModFontHelper convertText:text toStyle:selectedFont];
        [self zaloMod_insertText:converted];
    } else {
        [self zaloMod_insertText:text];
    }
}
@end

// =========================================================================
// 4. BUG API is_original = 1 (ẢNH GỐC HD) & TỰ ĐỘNG GÁN TTL KHI GỬI TIN
// =========================================================================
@interface NSJSONSerialization (ZaloModHook)
@end

@implementation NSJSONSerialization (ZaloModHook)
+ (NSData *)zaloMod_dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error {
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [obj mutableCopy];
        BOOL modified = NO;

        // Bug 1: Ép is_original = 1 khi gửi ảnh
        if ([ZaloModViewController isBugOriginalEnabled]) {
            if (dict[@"thumb"] || dict[@"photo"] || dict[@"photo_url"] || dict[@"total_size"] || dict[@"width"] || dict[@"height"] || dict[@"media"]) {
                dict[@"is_original"] = @(1);
                if ([dict[@"media"] isKindOfClass:[NSDictionary class]]) {
                    NSMutableDictionary *media = [dict[@"media"] mutableCopy];
                    media[@"is_original"] = @(1);
                    dict[@"media"] = media;
                }
                modified = YES;
                NSLog(@"[DucLamXNgBao] Đã ép is_original = 1 cho gói tin ảnh gửi đi!");
            }
        }

        // Bug 2: Tự động gán Custom TTL vào mọi tin nhắn gửi đi
        NSInteger ttlSecs = [ZaloModViewController customTTLSeconds];
        if (ttlSecs > 0) {
            if (dict[@"text"] || dict[@"msg"] || dict[@"cmsg"] || dict[@"cmsg_id"] || dict[@"content"] || dict[@"quote"]) {
                dict[@"ttl"] = @(ttlSecs * 1000);
                dict[@"ttl_ms"] = @(ttlSecs * 1000);
                modified = YES;
                NSLog(@"[DucLamXNgBao] Đã tự động gắn TTL = %ld giây cho tin nhắn!", (long)ttlSecs);
            }
        }

        if (modified) {
            return [self zaloMod_dataWithJSONObject:dict options:opt error:error];
        }
    }
    return [self zaloMod_dataWithJSONObject:obj options:opt error:error];
}
@end

// =========================================================================
// 5. ANTI-UNDO (CHỐNG THU HỒI TIN NHẮN TỪ SERVER)
// =========================================================================
static NSMutableSet *gRevokedMessageIds = nil;

static void hook_recallHandler(id self, SEL _cmd, id arg1, id arg2) {
    if ([ZaloModViewController isAntiUndoEnabled]) {
        NSLog(@"[DucLamXNgBao Anti-Undo] Đã chặn lệnh thu hồi tin nhắn từ đối phương!");
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ZaloFloatingButton sharedInstance] incrementBadge];
        });
        return; // Triệt tiêu lệnh thu hồi, tin nhắn vẫn còn nguyên vẹn trên màn hình!
    }
}

// Hook vào UILabel để hiển thị nhãn "( đã thu hồi )" cho tin nhắn bị thu hồi
@interface UILabel (ZaloModAntiUndo)
@end

@implementation UILabel (ZaloModAntiUndo)
- (void)zaloMod_setText:(NSString *)text {
    if ([ZaloModViewController isAntiUndoEnabled] && text && text.length > 0) {
        if ([text containsString:@"Tin nhắn đã được thu hồi"] || [text containsString:@"Message recalled"] || [text containsString:@"đã thu hồi một tin nhắn"]) {
            text = [NSString stringWithFormat:@"%@ ( đã thu hồi )", text];
        }
    }
    [self zaloMod_setText:text];
}
@end

// =========================================================================
// 6. BUG ZLSTYLE & NHÃN DOANH NGHIỆP ZBUSINESS (CLIENT-SIDE)
// =========================================================================
@interface UIViewController (ZaloModProfileSpoof)
@end

@implementation UIViewController (ZaloModProfileSpoof)

- (void)zaloMod_viewDidAppear:(BOOL)animated {
    [self zaloMod_viewDidAppear:animated];
    if ([ZaloModViewController isBugZBusinessEnabled]) {
        [self injectZBusinessBadgeAndFrame];
    }
}

- (void)zaloMod_viewDidLayoutSubviews {
    [self zaloMod_viewDidLayoutSubviews];
    if ([ZaloModViewController isBugZBusinessEnabled]) {
        [self injectZBusinessBadgeAndFrame];
    }
}

- (UILabel *)findNameLabelInViewHierarchy:(UIView *)rootView {
    if ([rootView isKindOfClass:[UILabel class]]) {
        UILabel *lbl = (UILabel *)rootView;
        if (lbl.tag != 888999 && lbl.text.length > 0 && lbl.font.pointSize >= 15.0 && !lbl.hidden) {
            if (![lbl.text containsString:@":"] && ![lbl.text isEqualToString:@"Business"] && ![lbl.text containsString:@"Đang hoạt động"]) {
                return lbl;
            }
        }
    }
    for (UIView *sub in rootView.subviews) {
        UILabel *found = [self findNameLabelInViewHierarchy:sub];
        if (found) return found;
    }
    return nil;
}

- (void)injectZBusinessBadgeAndFrame {
    NSString *className = NSStringFromClass([self class]);
    BOOL isTargetVC = [className containsString:@"Profile"] || 
                      [className containsString:@"UserDetail"] || 
                      [className containsString:@"Account"] ||
                      [className containsString:@"Chat"] ||
                      [className containsString:@"Navigation"];

    if (!isTargetVC && self.view.bounds.size.height < 500) return;

    UILabel *nameLabel = [self findNameLabelInViewHierarchy:self.view];
    if (!nameLabel || !nameLabel.superview) return;

    UIView *parent = nameLabel.superview;
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    BOOL isCenteredProfile = fabs(nameLabel.center.x - screenW / 2.0) < 60.0 || [className containsString:@"Profile"] || [className containsString:@"UserDetail"];

    UIView *container = [parent viewWithTag:888999];
    if (isCenteredProfile) {
        // --- CHẾ ĐỘ 1: TRANG CÁ NHÂN (FULL PROFILE) ---
        // Chỉ hiện duy nhất nhãn [Business] nằm ngay dưới tên (căn giữa)
        if (!container) {
            container = [[UIView alloc] init];
            container.tag = 888999;
            container.backgroundColor = [UIColor clearColor];

            UILabel *pill = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 58, 20)];
            pill.tag = 101;
            pill.text = @"Business";
            pill.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightMedium];
            pill.textColor = [UIColor colorWithRed:0.29 green:0.64 blue:0.89 alpha:1.0]; // #4ba3e3
            pill.backgroundColor = [UIColor colorWithRed:0.05 green:0.20 blue:0.29 alpha:0.95]; // #0e334a
            pill.textAlignment = NSTextAlignmentCenter;
            pill.layer.cornerRadius = 4.0;
            pill.clipsToBounds = YES;
            [container addSubview:pill];

            [parent addSubview:container];
        }

        CGFloat badgeW = 58.0;
        CGFloat badgeH = 20.0;
        CGFloat containerX = (parent.bounds.size.width - badgeW) / 2.0;
        CGFloat containerY = nameLabel.frame.origin.y + nameLabel.frame.size.height + 5.0;
        container.frame = CGRectMake(containerX, containerY, badgeW, badgeH);
        container.hidden = ![ZaloModViewController isBugZBusinessEnabled];

    } else {
        // --- CHẾ ĐỘ 2: THANH HEADER CHAT (INLINE) ---
        // Nằm ngay cạnh bên phải tên tài khoản
        if (!container) {
            container = [[UIView alloc] init];
            container.tag = 888999;
            container.backgroundColor = [UIColor clearColor];

            UILabel *pill = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 56, 19)];
            pill.tag = 101;
            pill.text = @"Business";
            pill.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightMedium];
            pill.textColor = [UIColor colorWithRed:0.29 green:0.64 blue:0.89 alpha:1.0];
            pill.backgroundColor = [UIColor colorWithRed:0.05 green:0.20 blue:0.29 alpha:0.95];
            pill.textAlignment = NSTextAlignmentCenter;
            pill.layer.cornerRadius = 4.0;
            pill.clipsToBounds = YES;
            [container addSubview:pill];

            [parent addSubview:container];
        }

        CGSize nameSize = [nameLabel.text sizeWithAttributes:@{NSFontAttributeName: nameLabel.font ?: [UIFont systemFontOfSize:17.0]}];
        CGFloat actualW = MIN(nameLabel.bounds.size.width, nameSize.width);
        CGFloat badgeX = nameLabel.frame.origin.x + actualW + 7.0;
        CGFloat badgeY = nameLabel.frame.origin.y + (nameLabel.frame.size.height - 19.0) / 2.0;
        container.frame = CGRectMake(badgeX, badgeY, 56, 19);
        container.hidden = ![ZaloModViewController isBugZBusinessEnabled];
    }

    // 3. Khung & Sticker zStyle trên Avatar tròn (Hình Người Tuyết ⛄ / Vương Miện)
    for (UIView *sub in parent.subviews) {
        if ([sub isKindOfClass:[UIImageView class]] && sub.bounds.size.width >= 50 && sub.bounds.size.width <= 140) {
            // Viền phát sáng ánh kim
            sub.layer.borderColor = [UIColor colorWithRed:0.3 green:0.75 blue:1.0 alpha:0.8].CGColor;
            sub.layer.borderWidth = 2.5;

            // Sticker zStyle góc trên bên trái của Avatar
            UILabel *sticker = (UILabel *)[parent viewWithTag:777666];
            if (!sticker) {
                sticker = [[UILabel alloc] init];
                sticker.tag = 777666;
                sticker.text = @"⛄"; // Người tuyết zStyle y chang ảnh
                sticker.font = [UIFont systemFontOfSize:26.0];
                sticker.textAlignment = NSTextAlignmentCenter;
                [parent addSubview:sticker];
            }
            sticker.frame = CGRectMake(sub.frame.origin.x - 6, sub.frame.origin.y - 6, 34, 34);
            sticker.hidden = ![ZaloModViewController isBugZBusinessEnabled];
            break;
        }
    }
}
@end

// =========================================================================
// 7. SIRIKIT ENTITLEMENT BYPASS (Chống văng app khi Sideload qua ESign/Scarlet)
// =========================================================================
@interface FakeIntentsBypass : NSObject
+ (id)sharedPreferences;
+ (id)sharedVocabulary;
+ (id)siriLanguageCode;
@end

@implementation FakeIntentsBypass
+ (id)sharedPreferences { return nil; }
+ (id)sharedVocabulary { return nil; }
+ (id)siriLanguageCode { return @"vi-VN"; }
+ (void)requestSiriAuthorization:(void(^)(NSInteger status))handler {
    if (handler) handler(0);
}
@end

static void patchSiriKitCrash(void) {
    @try {
        Class prefClass = objc_getClass("INPreferences");
        if (prefClass) {
            Method m1 = class_getClassMethod(prefClass, @selector(sharedPreferences));
            Method m2 = class_getClassMethod([FakeIntentsBypass class], @selector(sharedPreferences));
            if (m1 && m2) method_exchangeImplementations(m1, m2);

            Method m3 = class_getClassMethod(prefClass, @selector(siriLanguageCode));
            Method m4 = class_getClassMethod([FakeIntentsBypass class], @selector(siriLanguageCode));
            if (m3 && m4) method_exchangeImplementations(m3, m4);
        }

        Class vocabClass = objc_getClass("INVocabulary");
        if (vocabClass) {
            Method v1 = class_getClassMethod(vocabClass, @selector(sharedVocabulary));
            Method v2 = class_getClassMethod([FakeIntentsBypass class], @selector(sharedVocabulary));
            if (v1 && v2) method_exchangeImplementations(v1, v2);
        }
    } @catch (NSException *e) {
        NSLog(@"[DucLamXNgBao] Siri bypass error: %@", e);
    }
}

// =========================================================================
// 8. TỔNG HỢP VÀ KÍCH HOẠT TẤT CẢ CÁC HOOK
// =========================================================================
static void installAllZaloModHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[DucLamXNgBao] Đang cài đặt toàn bộ Hook cho Zalo Mod VIP...");

        // 1. Hook Font Chữ vào UITextView và UITextField
        swizzleInstanceMethod([UITextView class], @selector(insertText:), @selector(zaloMod_insertText:));
        swizzleInstanceMethod([UITextField class], @selector(insertText:), @selector(zaloMod_insertText:));

        // 2. Hook is_original = 1 và Custom TTL vào NSJSONSerialization
        Method origJSON = class_getClassMethod([NSJSONSerialization class], @selector(dataWithJSONObject:options:error:));
        Method swizJSON = class_getClassMethod([NSJSONSerialization class], @selector(zaloMod_dataWithJSONObject:options:error:));
        if (origJSON && swizJSON) {
            method_exchangeImplementations(origJSON, swizJSON);
            NSLog(@"[DucLamXNgBao Hook] Đã móc nối thành công is_original=1 & Custom TTL!");
        }

        // 3. Hook Anti-Undo vào UILabel setText:
        swizzleInstanceMethod([UILabel class], @selector(setText:), @selector(zaloMod_setText:));

        // 4. Hook Anti-Undo vào các class xử lý recall tin nhắn của Zalo
        int numClasses = objc_getClassList(NULL, 0);
        if (numClasses > 0) {
            Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
            numClasses = objc_getClassList(classes, numClasses);
            SEL recallSel1 = sel_registerName("ms_dataCoordinator:didReceiveRecallRequest:");
            SEL recallSel2 = sel_registerName("didReceiveRecallRequest:");
            for (int i = 0; i < numClasses; i++) {
                Class c = classes[i];
                if (class_getInstanceMethod(c, recallSel1)) {
                    class_replaceMethod(c, recallSel1, (IMP)hook_recallHandler, "v@:@@");
                    NSLog(@"[DucLamXNgBao Hook] Đã chặn recall thành công trên class: %s", class_getName(c));
                }
                if (class_getInstanceMethod(c, recallSel2)) {
                    class_replaceMethod(c, recallSel2, (IMP)hook_recallHandler, "v@:@");
                    NSLog(@"[DucLamXNgBao Hook] Đã chặn recall thành công trên class: %s", class_getName(c));
                }
            }
            free(classes);
        }

        // 5. Hook Profile hiển thị ZBusiness & ZLStyle
        swizzleInstanceMethod([UIViewController class], @selector(viewDidAppear:), @selector(zaloMod_viewDidAppear:));
        swizzleInstanceMethod([UIViewController class], @selector(viewDidLayoutSubviews), @selector(zaloMod_viewDidLayoutSubviews));

        NSLog(@"[DucLamXNgBao] ĐÃ KÍCH HOẠT TOÀN BỘ HOOKS THÀNH CÔNG 100%!");
    });
}

// Constructor Tweak
__attribute__((constructor))
static void initZaloModVIP(void) {
    patchSiriKitCrash();
    gRevokedMessageIds = [[NSMutableSet alloc] init];

    // Cài đặt tất cả runtime hooks ngay khi nạp dylib
    installAllZaloModHooks();

    void (^setupBlock)(NSNotification *) = ^(NSNotification * _Nonnull note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[ZaloModManager sharedManager] setupFloatingButton];
        });
    };

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:setupBlock];

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:setupBlock];

    if (@available(iOS 13.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserverForName:UISceneDidActivateNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:setupBlock];
    }

    // Fallback timers đảm bảo nút tròn luôn xuất hiện
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZaloModManager sharedManager] setupFloatingButton];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZaloModManager sharedManager] setupFloatingButton];
    });
}
