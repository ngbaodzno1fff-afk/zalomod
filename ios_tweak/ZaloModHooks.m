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
            }
        }

        // Bug 2: Tự động gán Custom TTL vào mọi tin nhắn gửi đi
        NSInteger ttlSecs = [ZaloModViewController customTTLSeconds];
        if (ttlSecs > 0) {
            if (dict[@"text"] || dict[@"msg"] || dict[@"cmsg"] || dict[@"cmsg_id"] || dict[@"content"] || dict[@"quote"]) {
                dict[@"ttl"] = @(ttlSecs * 1000);
                dict[@"ttl_ms"] = @(ttlSecs * 1000);
                modified = YES;
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
@interface UILabel (ZaloModAntiUndo)
@end

@implementation UILabel (ZaloModAntiUndo)
- (void)zaloMod_setText:(NSString *)text {
    if ([ZaloModViewController isAntiUndoEnabled] && text && text.length > 0) {
        if ([text containsString:@"Tin nhắn đã được thu hồi"] || [text containsString:@"Message recalled"] || [text containsString:@"đã thu hồi một tin nhắn"]) {
            text = [NSString stringWithFormat:@"%@ ( đã thu hồi )", text];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[ZaloFloatingButton sharedInstance] incrementBadge];
            });
        }
    }
    [self zaloMod_setText:text];
}
@end

// =========================================================================
// 6. NATIVE ZALO BUSINESS ACCOUNT HOOK (CORBiz11BALabelInfo)
// =========================================================================
static BOOL hook_hasTitleBadge(id self, SEL _cmd) {
    return [ZaloModViewController isBugZBusinessEnabled];
}

static id hook_titleBadge(id self, SEL _cmd) {
    return [ZaloModViewController isBugZBusinessEnabled] ? @"Business" : nil;
}

static id hook_textColorBadge(id self, SEL _cmd) {
    return [ZaloModViewController isBugZBusinessEnabled] ? [UIColor colorWithRed:0.29 green:0.64 blue:0.89 alpha:1.0] : nil;
}

static id hook_backgroundColorBadge(id self, SEL _cmd) {
    return [ZaloModViewController isBugZBusinessEnabled] ? [UIColor colorWithRed:0.05 green:0.20 blue:0.29 alpha:0.95] : nil;
}

// =========================================================================
// 7. GIAO DIỆN TRANG CÁ NHÂN PROFILE (NHÃN BUSINESS & ZLSTYLE AVATAR)
// =========================================================================
@interface UIViewController (ZaloModProfileSpoof)
@end

@implementation UIViewController (ZaloModProfileSpoof)

- (void)zaloMod_viewDidAppear:(BOOL)animated {
    [self zaloMod_viewDidAppear:animated];

    if (![ZaloModViewController isBugZBusinessEnabled]) return;

    NSString *className = NSStringFromClass([self class]);
    // CHỈ CHẠY DUY NHẤT KHI VÀO TRANG PROFILE (Tuyệt đối không chạy trên màn hình Tin Nhắn)
    if ([className containsString:@"Profile"] || [className containsString:@"UserDetail"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self injectZBusinessBadgeAndFrame];
        });
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
    UILabel *nameLabel = [self findNameLabelInViewHierarchy:self.view];
    if (!nameLabel || !nameLabel.superview) return;

    UIView *parent = nameLabel.superview;

    // 1. Nhãn [Business] bo tròn chuẩn xịn
    UIView *container = [parent viewWithTag:888999];
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

    // Xóa bỏ hoàn toàn sticker Người tuyết trên Avatar
    UIView *existingSticker = [parent viewWithTag:777666];
    if (existingSticker) {
        [existingSticker removeFromSuperview];
    }
}
@end

// =========================================================================
// 8. SIRIKIT ENTITLEMENT BYPASS (Chống văng app khi Sideload qua ESign/Scarlet)
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
// 9. KÍCH HOẠT TOÀN BỘ HOOKS (KHÔNG GÂY ĐƠ APP, SIÊU MƯỢT)
// =========================================================================
static void installAllZaloModHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[DucLamXNgBao] Đang cài đặt Hook tối ưu cho Zalo Mod VIP...");

        // 1. Hook Font Chữ vào UITextView và UITextField
        swizzleInstanceMethod([UITextView class], @selector(insertText:), @selector(zaloMod_insertText:));
        swizzleInstanceMethod([UITextField class], @selector(insertText:), @selector(zaloMod_insertText:));

        // 2. Hook is_original = 1 và Custom TTL vào NSJSONSerialization
        Method origJSON = class_getClassMethod([NSJSONSerialization class], @selector(dataWithJSONObject:options:error:));
        Method swizJSON = class_getClassMethod([NSJSONSerialization class], @selector(zaloMod_dataWithJSONObject:options:error:));
        if (origJSON && swizJSON) {
            method_exchangeImplementations(origJSON, swizJSON);
            NSLog(@"[DucLamXNgBao Hook] Đã móc nối is_original=1 & Custom TTL!");
        }

        // 3. Hook Anti-Undo vào UILabel setText:
        swizzleInstanceMethod([UILabel class], @selector(setText:), @selector(zaloMod_setText:));

        // 4. Hook Native Zalo Business Model (CORBiz11BALabelInfo)
        Class baInfoCls = objc_getClass("_TtC6CORBiz11BALabelInfo") ?: objc_getClass("CORBiz11BALabelInfo");
        if (baInfoCls) {
            Method m1 = class_getInstanceMethod(baInfoCls, sel_registerName("hasTitleBadge"));
            if (m1) method_setImplementation(m1, (IMP)hook_hasTitleBadge);

            Method m2 = class_getInstanceMethod(baInfoCls, sel_registerName("titleBadge"));
            if (m2) method_setImplementation(m2, (IMP)hook_titleBadge);

            Method m3 = class_getInstanceMethod(baInfoCls, sel_registerName("textColorBadge"));
            if (m3) method_setImplementation(m3, (IMP)hook_textColorBadge);

            Method m4 = class_getInstanceMethod(baInfoCls, sel_registerName("backgroundColorBadge"));
            if (m4) method_setImplementation(m4, (IMP)hook_backgroundColorBadge);

            NSLog(@"[DucLamXNgBao Hook] Đã kích hoạt nhãn Business chuẩn Native trong Zalo!");
        }

        // 5. Hook Profile hiển thị ZBusiness & ZLStyle (Chỉ chạy trên Profile screen)
        swizzleInstanceMethod([UIViewController class], @selector(viewDidAppear:), @selector(zaloMod_viewDidAppear:));

        NSLog(@"[DucLamXNgBao] HOÀN TẤT KÍCH HOẠT HOOKS - SIÊU MƯỢT, KHÔNG ĐƠ APP!");
    });
}

// Constructor Tweak
__attribute__((constructor))
static void initZaloModVIP(void) {
    patchSiriKitCrash();

    // Kích hoạt runtime hooks tối ưu
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

    // Fallback timers
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZaloModManager sharedManager] setupFloatingButton];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZaloModManager sharedManager] setupFloatingButton];
    });
}
