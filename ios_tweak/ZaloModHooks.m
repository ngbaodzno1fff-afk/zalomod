//
//  ZaloModHooks.m
//  ZaloMod VIP - Runtime Method Swizzling & Tweak Injection
//  Thương hiệu: DucLamXNgBao
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
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
// 3. FONT HOOK (12 FONT CHỮ NGHỆ THUẬT & MÀU SẮC KHI NHẬP VÀ GỬI TIN NHẮN)
// =========================================================================
@interface UITextView (ZaloModFontHook)
@end

@implementation UITextView (ZaloModFontHook)
- (void)zaloMod_insertText:(NSString *)text {
    CGFloat customSize = [ZaloModViewController customFontSize];
    if (customSize > 0) {
        self.font = [UIFont systemFontOfSize:customSize weight:UIFontWeightMedium];
    }
    UIColor *col = [ZaloModViewController selectedTextColor];
    if (col) {
        self.textColor = col;
    }

    NSString *selectedFont = [[NSUserDefaults standardUserDefaults] stringForKey:@"ZaloMod_SelectedFont"];
    if (selectedFont && ![selectedFont isEqualToString:@"Tắt"] && text.length > 0) {
        NSString *converted = [ZaloModFontHelper convertText:text toStyle:selectedFont];
        [self zaloMod_insertText:converted];
    } else {
        [self zaloMod_insertText:text];
    }
    if (col) {
        self.textColor = col;
    }
}

- (BOOL)zaloMod_becomeFirstResponder {
    CGFloat customSize = [ZaloModViewController customFontSize];
    if (customSize > 0) {
        self.font = [UIFont systemFontOfSize:customSize weight:UIFontWeightMedium];
    }
    UIColor *col = [ZaloModViewController selectedTextColor];
    if (col) {
        self.textColor = col;
    }
    return [self zaloMod_becomeFirstResponder];
}
@end

@interface UITextField (ZaloModFontHook)
@end

@implementation UITextField (ZaloModFontHook)
- (void)zaloMod_insertText:(NSString *)text {
    CGFloat customSize = [ZaloModViewController customFontSize];
    if (customSize > 0) {
        self.font = [UIFont systemFontOfSize:customSize weight:UIFontWeightMedium];
    }
    UIColor *col = [ZaloModViewController selectedTextColor];
    if (col) {
        self.textColor = col;
    }

    NSString *selectedFont = [[NSUserDefaults standardUserDefaults] stringForKey:@"ZaloMod_SelectedFont"];
    if (selectedFont && ![selectedFont isEqualToString:@"Tắt"] && text.length > 0) {
        NSString *converted = [ZaloModFontHelper convertText:text toStyle:selectedFont];
        [self zaloMod_insertText:converted];
    } else {
        [self zaloMod_insertText:text];
    }
    if (col) {
        self.textColor = col;
    }
}

- (BOOL)zaloMod_becomeFirstResponder {
    CGFloat customSize = [ZaloModViewController customFontSize];
    if (customSize > 0) {
        self.font = [UIFont systemFontOfSize:customSize weight:UIFontWeightMedium];
    }
    UIColor *col = [ZaloModViewController selectedTextColor];
    if (col) {
        self.textColor = col;
    }
    return [self zaloMod_becomeFirstResponder];
}
@end

// =========================================================================
// 4. CHỐNG THU HỒI TIN NHẮN (ANTI-UNDO) - GIỮ NGUYÊN NỘI DUNG VÀ BONG BÓNG CHAT
// =========================================================================
static void hook_UndoChatProcessor_updateUndoMessageContent(id self, SEL _cmd, id chat) {
    void (*orig)(id, SEL, id) = (void (*)(id, SEL, id))class_getMethodImplementation(object_getClass(self), sel_registerName("zaloMod_orig_updateUndoMessageContent:"));
    if (orig) orig(self, _cmd, chat);

    if ([ZaloModViewController isAntiUndoEnabled] && chat) {
        SEL origRecallSel = sel_registerName("_originTextRecallMsg");
        SEL msgSel = sel_registerName("message");
        SEL setMsgSel = sel_registerName("setMessage:");

        NSString *origText = nil;
        if ([chat respondsToSelector:origRecallSel]) {
            origText = ((id (*)(id, SEL))objc_msgSend)(chat, origRecallSel);
        }
        if (!origText || origText.length == 0) {
            if ([chat respondsToSelector:msgSel]) {
                origText = ((id (*)(id, SEL))objc_msgSend)(chat, msgSel);
            }
        }
        if (!origText || origText.length == 0) {
            origText = @"[Tin nhắn đã gửi]";
        }

        if (origText && origText.length > 0 && ![origText containsString:@"( đã thu hồi )"]) {
            NSString *annotatedMsg = [NSString stringWithFormat:@"%@ ( đã thu hồi )", origText];
            if ([chat respondsToSelector:setMsgSel]) {
                ((void (*)(id, SEL, id))objc_msgSend)(chat, setMsgSel, annotatedMsg);
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ZaloFloatingButton sharedInstance] incrementBadge];
        });
    }
}

// Hook hiển thị nhãn thu hồi trên UI (an toàn, không đụng vào CoreText calculation)
@interface UILabel (ZaloModAntiUndo)
@end

@implementation UILabel (ZaloModAntiUndo)
- (void)zaloMod_setText:(NSString *)text {
    if ([ZaloModViewController isAntiUndoEnabled] && text && text.length > 0) {
        if ([text containsString:@"Tin nhắn đã được thu hồi"] || [text containsString:@"Message recalled"]) {
            text = [NSString stringWithFormat:@"%@ ( đã chặn thu hồi )", text];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[ZaloFloatingButton sharedInstance] incrementBadge];
            });
        }
    }
    [self zaloMod_setText:text];
}
@end

// =========================================================================
// 5. MỞ KHÓA GỬI ẢNH GỐC & HD (KHÔNG BỊ BẮT MUA ZCLOUD, TỰ ĐỘNG GỬI ORIGINAL)
// =========================================================================
// Helper kiểm tra và ép chế độ Original cho ảnh mà không làm ảnh hưởng tin nhắn văn bản
static void markChatAsOriginalIfPhoto(id chat) {
    if (!chat || ![ZaloModViewController isBugOriginalEnabled]) return;
    @try {
        BOOL isPhoto = NO;
        if ([chat respondsToSelector:sel_registerName("isPhoto")] && ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isPhoto"))) {
            isPhoto = YES;
        } else if ([chat respondsToSelector:sel_registerName("isPhotoType")] && ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isPhotoType"))) {
            isPhoto = YES;
        } else if ([chat respondsToSelector:sel_registerName("isPhotoAttachment")] && ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isPhotoAttachment"))) {
            isPhoto = YES;
        } else if ([chat respondsToSelector:sel_registerName("isPhotoHD")]) {
            isPhoto = YES;
        }
        if (isPhoto) {
            if ([chat respondsToSelector:sel_registerName("setIsOriginal:")]) {
                ((void (*)(id, SEL, long long))objc_msgSend)(chat, sel_registerName("setIsOriginal:"), 1);
            }
            if ([chat respondsToSelector:sel_registerName("setIsPhotoHD:")]) {
                ((void (*)(id, SEL, BOOL))objc_msgSend)(chat, sel_registerName("setIsPhotoHD:"), YES);
            }
            if ([chat respondsToSelector:sel_registerName("set_isOrigin:")]) {
                ((void (*)(id, SEL, BOOL))objc_msgSend)(chat, sel_registerName("set_isOrigin:"), YES);
            }
        }
    } @catch (NSException *e) {}
}

// Hook QualityPickerViewController (Bảng chọn chế độ gửi ảnh)
static BOOL hook_enableShowOriginPhoto(id self, SEL _cmd) {
    return YES; // Cho phép hiển thị nút Original!
}

static NSInteger hook_originalBadgeType(id self, SEL _cmd) {
    return 0; // Bỏ huy hiệu khóa zCloud!
}

static id hook_originalBadge(id self, SEL _cmd) {
    return nil; // Xóa chữ zCloud!
}

static NSInteger hook_currentQuality_original(id self, SEL _cmd) {
    if ([ZaloModViewController isBugOriginalEnabled]) return 2; // Original quality
    return 2;
}

static float hook_originalCompressQuality(id self, SEL _cmd) {
    return 1.0f; // Chất lượng gốc 100% không nén!
}

static int hook_allowRememberQuality(id self, SEL _cmd) {
    return 1;
}

static long long hook_maxOriginalLimit(id self, SEL _cmd) {
    return 999999999LL;
}

// Hook RichMessageContent (Chỉ gán Original nếu message thực sự là ảnh/media)
static BOOL hook_RichMessageContent_isOriginal(id self, SEL _cmd) {
    if ([ZaloModViewController isBugOriginalEnabled]) {
        BOOL isMedia = NO;
        if ([self respondsToSelector:sel_registerName("isPhoto")] && ((BOOL (*)(id, SEL))objc_msgSend)(self, sel_registerName("isPhoto"))) {
            isMedia = YES;
        } else if ([self respondsToSelector:sel_registerName("isPhotoHD")] && ((BOOL (*)(id, SEL))objc_msgSend)(self, sel_registerName("isPhotoHD"))) {
            isMedia = YES;
        } else if ([self respondsToSelector:sel_registerName("photo")] && ((id (*)(id, SEL))objc_msgSend)(self, sel_registerName("photo")) != nil) {
            isMedia = YES;
        } else if ([self respondsToSelector:sel_registerName("thumb")] && ((id (*)(id, SEL))objc_msgSend)(self, sel_registerName("thumb")) != nil) {
            isMedia = YES;
        }
        if (isMedia) return YES;
    }
    BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(objc_getClass("RichMessageContent"), sel_registerName("zaloMod_orig_isOriginal:"));
    return orig ? orig(self, _cmd) : NO;
}

static BOOL hook_RichMessageContent_isPhotoHD(id self, SEL _cmd) {
    if ([ZaloModViewController isBugOriginalEnabled]) {
        BOOL isMedia = NO;
        if ([self respondsToSelector:sel_registerName("isPhoto")] && ((BOOL (*)(id, SEL))objc_msgSend)(self, sel_registerName("isPhoto"))) {
            isMedia = YES;
        } else if ([self respondsToSelector:sel_registerName("isPhotoHD")] && ((BOOL (*)(id, SEL))objc_msgSend)(self, sel_registerName("isPhotoHD"))) {
            isMedia = YES;
        } else if ([self respondsToSelector:sel_registerName("photo")] && ((id (*)(id, SEL))objc_msgSend)(self, sel_registerName("photo")) != nil) {
            isMedia = YES;
        } else if ([self respondsToSelector:sel_registerName("thumb")] && ((id (*)(id, SEL))objc_msgSend)(self, sel_registerName("thumb")) != nil) {
            isMedia = YES;
        }
        if (isMedia) return YES;
    }
    BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(objc_getClass("RichMessageContent"), sel_registerName("zaloMod_orig_isPhotoHD:"));
    return orig ? orig(self, _cmd) : NO;
}

// =========================================================================
// 5a. HELPER PHÂN BIỆT TIN NHẮN DO MÌNH GỬI vs TIN NHẮN NGƯỜI KHÁC GỬI ĐẾN
// =========================================================================
static BOOL isMessageFromMe(id chat) {
    if (!chat) return NO;
    @try {
        if ([chat respondsToSelector:sel_registerName("isMyMessage")]) {
            return ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isMyMessage"));
        }
        if ([chat respondsToSelector:sel_registerName("isOutgoing")]) {
            return ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isOutgoing"));
        }
        if ([chat respondsToSelector:sel_registerName("isSenderMe")]) {
            return ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isSenderMe"));
        }
    } @catch (NSException *e) {}
    return NO;
}

// Hook ZAChatSendingManager: Gửi tin nhắn tự động kèm TTL và tự động ép gửi ảnh Original
static void hook_sendChat_checkUpload(id self, SEL _cmd, id chat, BOOL check) {
    long long ttlMs = [ZaloModViewController customTTLMilliseconds];
    if (ttlMs > 0 && chat) {
        SEL setTtlSel = sel_registerName("setTtl:");
        if ([chat respondsToSelector:setTtlSel]) {
            ((void (*)(id, SEL, long long))objc_msgSend)(chat, setTtlSel, ttlMs);
        }
    }
    markChatAsOriginalIfPhoto(chat);

    void (*orig)(id, SEL, id, BOOL) = (void (*)(id, SEL, id, BOOL))class_getMethodImplementation(objc_getClass("ZAChatSendingManager"), sel_registerName("zaloMod_orig_sendChat_checkUpload:"));
    if (orig) orig(self, _cmd, chat, check);
}

static void hook_sendChat_destinations(id self, SEL _cmd, id chat, id dests, BOOL check, BOOL wait) {
    long long ttlMs = [ZaloModViewController customTTLMilliseconds];
    if (ttlMs > 0 && chat) {
        SEL setTtlSel = sel_registerName("setTtl:");
        if ([chat respondsToSelector:setTtlSel]) {
            ((void (*)(id, SEL, long long))objc_msgSend)(chat, setTtlSel, ttlMs);
        }
    }
    markChatAsOriginalIfPhoto(chat);

    void (*orig)(id, SEL, id, id, BOOL, BOOL) = (void (*)(id, SEL, id, id, BOOL, BOOL))class_getMethodImplementation(objc_getClass("ZAChatSendingManager"), sel_registerName("zaloMod_orig_sendChat_destinations:"));
    if (orig) orig(self, _cmd, chat, dests, check, wait);
}

// =========================================================================
// 5b. HOOK TỰ ĐỘNG GÁN TTL TÙY CHỈNH (s, h, d) VÀO TIN NHẮN (CHUẨN MILLISECONDS)
// =========================================================================
static id hook_syncMessageWithCurrentDisappearingTTLIfNeed(id self, SEL _cmd, id chat) {
    id (*orig)(id, SEL, id) = (id (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("ChatDataManager"), sel_registerName("zaloMod_orig_syncMessageWithCurrentDisappearingTTLIfNeed:"));
    id result = orig ? orig(self, _cmd, chat) : chat;
    if (!result) result = chat;

    // QUAN TRỌNG: CHỈ GÁN TTL CHO TIN NHẮN DO CHÍNH MÌNH GỬI ĐI!
    // Tuyệt đối không gán TTL cho tin nhắn của người khác gửi đến!
    if (isMessageFromMe(result) || isMessageFromMe(chat)) {
        long long ttlMs = [ZaloModViewController customTTLMilliseconds];
        if (ttlMs > 0) {
            SEL setTtlSel = sel_registerName("setTtl:");
            if ([result respondsToSelector:setTtlSel]) {
                ((void (*)(id, SEL, long long))objc_msgSend)(result, setTtlSel, ttlMs);
            }
            if (chat != result && [chat respondsToSelector:setTtlSel]) {
                ((void (*)(id, SEL, long long))objc_msgSend)(chat, setTtlSel, ttlMs);
            }
        }
        markChatAsOriginalIfPhoto(result);
        if (chat != result) markChatAsOriginalIfPhoto(chat);
    }
    return result;
}

static BOOL hook_attachTTLValueForMessageIfNeed(id self, SEL _cmd, id chat) {
    BOOL (*orig)(id, SEL, id) = (BOOL (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("ChatDataManager"), sel_registerName("zaloMod_orig_attachTTLValueForMessageIfNeed:"));
    BOOL res = orig ? orig(self, _cmd, chat) : NO;

    // CHỈ GÁN CHO TIN NHẮN DO CHÍNH MÌNH GỬI ĐI:
    if (!isMessageFromMe(chat)) {
        return res;
    }

    long long ttlMs = [ZaloModViewController customTTLMilliseconds];
    if (ttlMs > 0 && chat) {
        SEL setTtlSel = sel_registerName("setTtl:");
        if ([chat respondsToSelector:setTtlSel]) {
            ((void (*)(id, SEL, long long))objc_msgSend)(chat, setTtlSel, ttlMs);
        }
        res = YES;
    }
    markChatAsOriginalIfPhoto(chat);
    return res;
}

// Chống tin nhắn bị đếm ngược quá nhanh hoặc tự xóa trước khi đủ thời gian
static BOOL hook_ChatEntity_isExpiredMessage(id self, SEL _cmd) {
    // NGUYÊN TẮC: Tin nhắn của người khác thì giữ nguyên 100% logic gốc của Zalo!
    // Không bao giờ can thiệp hay tự hủy nhầm tin nhắn của đối phương!
    if (!isMessageFromMe(self)) {
        BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(objc_getClass("ChatEntity"), sel_registerName("zaloMod_orig_isExpiredMessage"));
        return orig ? orig(self, _cmd) : NO;
    }

    long long ttl = 0;
    SEL ttlSel = sel_registerName("ttl");
    if ([self respondsToSelector:ttlSel]) {
        ttl = ((long long (*)(id, SEL))objc_msgSend)(self, ttlSel);
    }
    if (ttl <= 0) return NO;

    // Tự động scale nếu ttl bị gán theo giây thay vì milliseconds
    if (ttl > 0 && ttl < 1000) {
        ttl = ttl * 1000LL;
        SEL setTtlSel = sel_registerName("setTtl:");
        if ([self respondsToSelector:setTtlSel]) {
            ((void (*)(id, SEL, long long))objc_msgSend)(self, setTtlSel, ttl);
        }
    }

    double createTime = 0;
    SEL tsSel = sel_registerName("ts");
    if ([self respondsToSelector:tsSel]) {
        createTime = ((double (*)(id, SEL))objc_msgSend)(self, tsSel);
    }
    if (createTime <= 0) {
        SEL timeSel = sel_registerName("time");
        if ([self respondsToSelector:timeSel]) {
            createTime = ((double (*)(id, SEL))objc_msgSend)(self, timeSel) * 1000.0;
        }
    }

    if (createTime > 0 && ttl > 0) {
        double nowMs = [[NSDate date] timeIntervalSince1970] * 1000.0;
        double expireAtMs = createTime + (double)ttl;
        if (nowMs < expireAtMs) {
            return NO; // Chưa đủ thời gian hết hạn -> Giữ nguyên tin nhắn!
        }
    }

    BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(objc_getClass("ChatEntity"), sel_registerName("zaloMod_orig_isExpiredMessage"));
    return orig ? orig(self, _cmd) : NO;
}

@interface NSJSONSerialization (ZaloModOriginalPhoto)
@end

@implementation NSJSONSerialization (ZaloModOriginalPhoto)
+ (NSData *)zaloMod_dataWithJSONObject:(id)obj options:(NSJSONWritingOptions)opt error:(NSError **)error {
    if ([ZaloModViewController isBugOriginalEnabled] && [obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)obj;
        if (dict[@"hd"] || dict[@"photo"] || dict[@"image"] || dict[@"thumb"] || dict[@"photo_url"] || dict[@"media"]) {
            NSMutableDictionary *mdict = [dict mutableCopy];
            mdict[@"is_original"] = @(1);
            mdict[@"is_photo_hd"] = @(1);
            return [self zaloMod_dataWithJSONObject:mdict options:opt error:error];
        }
    }
    return [self zaloMod_dataWithJSONObject:obj options:opt error:error];
}
@end

// =========================================================================
// 6. NATIVE ZALO BUSINESS ACCOUNT HOOK (CHUẨN CHÍNH HÃNG 100%, KHÔNG ĐÈ CHỮ)
// =========================================================================
static BOOL hook_alwaysTrue(id self, SEL _cmd) {
    return [ZaloModViewController isBugZBusinessEnabled];
}

static BOOL hook_checkUserIsBusinessAccount(id self, SEL _cmd, id user) {
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
// 6b. BUG ALL ZSTYLES & NHẠC NỀN CHAT / PROFILE (PILL PLAYER & UNLOCK ALL STYLES)
// =========================================================================
static NSDictionary *getZStyleVIPDictionary(void) {
    return @{
        @"zstyle_package_id": @(1),
        @"package_id": @(1),
        @"is_zstyle": @(1),
        @"is_subscribed": @(1),
        @"status": @(1),
        @"expired_time": @(4070908800ULL),
        @"zstyle_music": @(1),
        @"zstyle_avatar_frame": @(1),
        @"zstyle_cover": @(1),
        @"zstyle_namecard": @(1)
    };
}

@interface NSUserDefaults (ZaloModZStyle)
@end

@implementation NSUserDefaults (ZaloModZStyle)
- (id)zaloMod_objectForKey:(NSString *)defaultName {
    if ([ZaloModViewController isBugZLStyleEnabled] && defaultName && [defaultName containsString:@"kProfileSetting_ZStyleInfo"]) {
        return getZStyleVIPDictionary();
    }
    return [self zaloMod_objectForKey:defaultName];
}
@end

static BOOL hook_isZStyleSubscribed(id self, SEL _cmd, id userId) {
    if ([ZaloModViewController isBugZLStyleEnabled]) return YES;
    BOOL (*orig)(id, SEL, id) = (BOOL (*)(id, SEL, id))class_getMethodImplementation(object_getClass(self), sel_registerName("zaloMod_orig_isZStyleSubscribed:"));
    return orig ? orig(self, _cmd, userId) : NO;
}

static NSInteger hook_getZStylePackageId(id self, SEL _cmd, id userId) {
    if ([ZaloModViewController isBugZLStyleEnabled]) return 1; // Gói ZStyle VIP 1
    NSInteger (*orig)(id, SEL, id) = (NSInteger (*)(id, SEL, id))class_getMethodImplementation(object_getClass(self), sel_registerName("zaloMod_orig_getZStylePackageId:"));
    return orig ? orig(self, _cmd, userId) : 0;
}

static NSDictionary *hook_getZStyleDictOfUser(id self, SEL _cmd, id userId) {
    if ([ZaloModViewController isBugZLStyleEnabled]) return getZStyleVIPDictionary();
    NSDictionary * (*orig)(id, SEL, id) = (NSDictionary * (*)(id, SEL, id))class_getMethodImplementation(object_getClass(self), sel_registerName("zaloMod_orig_getZStyleDictOfUser:"));
    return orig ? orig(self, _cmd, userId) : nil;
}

static BOOL hook_zstyleAlwaysTrue(id self, SEL _cmd) {
    return [ZaloModViewController isBugZLStyleEnabled];
}

static BOOL hook_zstyleAlwaysFalse(id self, SEL _cmd) {
    if ([ZaloModViewController isBugZLStyleEnabled]) return NO;
    BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(object_getClass(self), sel_registerName("zaloMod_orig_zstyleFalse:"));
    return orig ? orig(self, _cmd) : NO;
}

static NSInteger hook_currentPillStatus(id self, SEL _cmd) {
    if ([ZaloModViewController isBugZLStyleEnabled]) return 4; // Active Pill Player
    NSInteger (*orig)(id, SEL) = (NSInteger (*)(id, SEL))class_getMethodImplementation(object_getClass(self), sel_registerName("zaloMod_orig_currentPillStatus"));
    return orig ? orig(self, _cmd) : 0;
}

static NSDictionary *hook_BuddyEntity_zstyleInfo(id self, SEL _cmd) {
    if ([ZaloModViewController isBugZLStyleEnabled]) return getZStyleVIPDictionary();
    NSDictionary * (*orig)(id, SEL) = (NSDictionary * (*)(id, SEL))class_getMethodImplementation(objc_getClass("BuddyEntity"), sel_registerName("zaloMod_orig_zstyleInfo"));
    return orig ? orig(self, _cmd) : nil;
}

static NSInteger hook_zstylePackageIdVIP(id self, SEL _cmd) {
    if ([ZaloModViewController isBugZLStyleEnabled]) return 1;
    return 0;
}

static long long hook_zeroPrice(id self, SEL _cmd) {
    return 0;
}

// Dọn dẹp triệt để các subview thừa cũ trên UIViewController
@interface UIViewController (ZaloModCleanupOldViews)
@end

@implementation UIViewController (ZaloModCleanupOldViews)
- (void)zaloMod_viewDidAppear:(BOOL)animated {
    [self zaloMod_viewDidAppear:animated];

    // Xóa bỏ tất cả subview tag 888999 (view fake Business cũ) và 777666 (sticker snowman)
    UIView *oldBadge = [self.view viewWithTag:888999];
    if (oldBadge) [oldBadge removeFromSuperview];

    UIView *oldSticker = [self.view viewWithTag:777666];
    if (oldSticker) [oldSticker removeFromSuperview];
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
// 8. KÍCH HOẠT TOÀN BỘ HOOKS (AN TOÀN TUYỆT ĐỐI, KHÔNG PHÁ HỎNG GIAO DIỆN CHAT)
// =========================================================================
static void installAllZaloModHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[DucLamXNgBao] Đang cài đặt Hook chuẩn xác cho Zalo Mod VIP...");

        // 1. Hook Font Chữ vào ô nhập liệu
        swizzleInstanceMethod([UITextView class], @selector(insertText:), @selector(zaloMod_insertText:));
        swizzleInstanceMethod([UITextView class], @selector(becomeFirstResponder), @selector(zaloMod_becomeFirstResponder));
        swizzleInstanceMethod([UITextField class], @selector(insertText:), @selector(zaloMod_insertText:));
        swizzleInstanceMethod([UITextField class], @selector(becomeFirstResponder), @selector(zaloMod_becomeFirstResponder));

        // 2. Hook Anti-Undo trên UndoChatProcessor (Giữ nguyên nội dung, hiện nhãn 'đã thu hồi' rõ ràng)
        Class undoProcCls = objc_getClass("UndoChatProcessor");
        if (undoProcCls) {
            Class metaCls = object_getClass(undoProcCls);
            Method mUndo = class_getClassMethod(undoProcCls, sel_registerName("updateUndoMessageContent:"));
            if (mUndo && metaCls) {
                IMP origImp = method_getImplementation(mUndo);
                class_addMethod(metaCls, sel_registerName("zaloMod_orig_updateUndoMessageContent:"), origImp, method_getTypeEncoding(mUndo));
                method_setImplementation(mUndo, (IMP)hook_UndoChatProcessor_updateUndoMessageContent);
                NSLog(@"[DucLamXNgBao] Hook UndoChatProcessor updateUndoMessageContent thành công!");
            }
        }

        swizzleInstanceMethod([UILabel class], @selector(setText:), @selector(zaloMod_setText:));

        // 3. Mở khóa giao diện và cấu hình gửi ảnh Original & HD không bị nén
        Class pickerVCCls = objc_getClass("_TtC19CommFeatureBusiness27QualityPickerViewController") ?: objc_getClass("QualityPickerViewController");
        if (pickerVCCls) {
            Method mShow = class_getInstanceMethod(pickerVCCls, sel_registerName("enableShowOriginPhoto"));
            if (mShow) method_setImplementation(mShow, (IMP)hook_enableShowOriginPhoto);

            Method mBadgeType = class_getInstanceMethod(pickerVCCls, sel_registerName("originalBadgeType"));
            if (mBadgeType) method_setImplementation(mBadgeType, (IMP)hook_originalBadgeType);

            Method mBadge = class_getInstanceMethod(pickerVCCls, sel_registerName("originalBadge"));
            if (mBadge) method_setImplementation(mBadge, (IMP)hook_originalBadge);

            Method mAllowed = class_getInstanceMethod(pickerVCCls, sel_registerName("isOriginAllowed:"));
            if (mAllowed) method_setImplementation(mAllowed, (IMP)hook_enableShowOriginPhoto);

            Method mCurQ = class_getInstanceMethod(pickerVCCls, sel_registerName("currentQuality"));
            if (mCurQ) method_setImplementation(mCurQ, (IMP)hook_currentQuality_original);

            NSLog(@"[DucLamXNgBao] Đã mở khóa chọn ảnh Original không cần zCloud!");
        }

        // Cấu hình ZCFQualityPickerConfig cho phép gửi ảnh Original mặc định
        Class qpConfigCls = objc_getClass("_TtC15CommFeatureBase22ZCFQualityPickerConfig") ?: objc_getClass("ZCFQualityPickerConfig");
        if (qpConfigCls) {
            Method mSendOrig = class_getClassMethod(qpConfigCls, sel_registerName("enableSendOriginal"));
            if (mSendOrig) method_setImplementation(mSendOrig, (IMP)hook_alwaysTrue);

            Method mBadge = class_getClassMethod(qpConfigCls, sel_registerName("originalBadge"));
            if (mBadge) method_setImplementation(mBadge, (IMP)hook_originalBadge);

            Method mBeta = class_getClassMethod(qpConfigCls, sel_registerName("showBadgeBeta"));
            if (mBeta) method_setImplementation(mBeta, (IMP)hook_zstyleAlwaysFalse);

            Method mRem = class_getClassMethod(qpConfigCls, sel_registerName("allowRememberQuality"));
            if (mRem) method_setImplementation(mRem, (IMP)hook_allowRememberQuality);

            Method mQuality = class_getClassMethod(qpConfigCls, sel_registerName("originalCompressQuality"));
            if (mQuality) method_setImplementation(mQuality, (IMP)hook_originalCompressQuality);
        }

        // Cấu hình ZSharedData bỏ giới hạn dung lượng ảnh gốc
        Class zSharedCls = objc_getClass("ZSharedData");
        if (zSharedCls) {
            Method mSetting = class_getInstanceMethod(zSharedCls, sel_registerName("settingOriginalPhotoQuality"));
            if (mSetting) method_setImplementation(mSetting, (IMP)hook_alwaysTrue);

            Method mLimitSize = class_getInstanceMethod(zSharedCls, sel_registerName("limitOriginalPhotoSize"));
            if (mLimitSize) method_setImplementation(mLimitSize, (IMP)hook_maxOriginalLimit);

            Method mLimitDim = class_getInstanceMethod(zSharedCls, sel_registerName("limitOriginalPhotoDimension"));
            if (mLimitDim) method_setImplementation(mLimitDim, (IMP)hook_maxOriginalLimit);

            Method mRemHD = class_getInstanceMethod(zSharedCls, sel_registerName("enableRememberHD"));
            if (mRemHD) method_setImplementation(mRemHD, (IMP)hook_alwaysTrue);
        }

        // Hook ZAChatSendingManager: Gửi tin nhắn tự động kèm TTL và tự động gửi ảnh Original
        Class sendMgrCls = objc_getClass("ZAChatSendingManager");
        if (sendMgrCls) {
            Method m1 = class_getInstanceMethod(sendMgrCls, sel_registerName("sendChat:checkUpload:"));
            if (m1) {
                IMP orig = method_getImplementation(m1);
                class_addMethod(sendMgrCls, sel_registerName("zaloMod_orig_sendChat_checkUpload:"), orig, method_getTypeEncoding(m1));
                method_setImplementation(m1, (IMP)hook_sendChat_checkUpload);
            }
            Method m2 = class_getInstanceMethod(sendMgrCls, sel_registerName("sendChat:toDestinations:checkUpload:isWaitingSend:"));
            if (m2) {
                IMP orig = method_getImplementation(m2);
                class_addMethod(sendMgrCls, sel_registerName("zaloMod_orig_sendChat_destinations:"), orig, method_getTypeEncoding(m2));
                method_setImplementation(m2, (IMP)hook_sendChat_destinations);
            }
            NSLog(@"[DucLamXNgBao] Hook ZAChatSendingManager tự động gửi ảnh Original thành công!");
        }

        // Hook RichMessageContent: Gán cờ Original/PhotoHD cho ảnh gửi đi
        Class richContentCls = objc_getClass("RichMessageContent");
        if (richContentCls) {
            Method mOrig = class_getInstanceMethod(richContentCls, sel_registerName("isOriginal"));
            if (mOrig) {
                IMP orig = method_getImplementation(mOrig);
                class_addMethod(richContentCls, sel_registerName("zaloMod_orig_isOriginal:"), orig, method_getTypeEncoding(mOrig));
                method_setImplementation(mOrig, (IMP)hook_RichMessageContent_isOriginal);
            }
            Method mHD = class_getInstanceMethod(richContentCls, sel_registerName("isPhotoHD"));
            if (mHD) {
                IMP orig = method_getImplementation(mHD);
                class_addMethod(richContentCls, sel_registerName("zaloMod_orig_isPhotoHD:"), orig, method_getTypeEncoding(mHD));
                method_setImplementation(mHD, (IMP)hook_RichMessageContent_isPhotoHD);
            }
        }

        // 4. Hook Native Business Account (ProfileEntity, BuddyEntity, BALabelInfo, FlowManagers)
        Class profEntityCls = objc_getClass("ProfileEntity");
        if (profEntityCls) {
            Method m = class_getInstanceMethod(profEntityCls, sel_registerName("isBusinessAccount"));
            if (m) method_setImplementation(m, (IMP)hook_alwaysTrue);

            Method mZStyle = class_getInstanceMethod(profEntityCls, sel_registerName("isZStyle"));
            if (mZStyle) method_setImplementation(mZStyle, (IMP)hook_zstyleAlwaysTrue);

            Method mZUser = class_getInstanceMethod(profEntityCls, sel_registerName("isZStyleUser"));
            if (mZUser) method_setImplementation(mZUser, (IMP)hook_zstyleAlwaysTrue);

            Method mPaid = class_getInstanceMethod(profEntityCls, sel_registerName("isPaidZStyle"));
            if (mPaid) method_setImplementation(mPaid, (IMP)hook_zstyleAlwaysTrue);

            Method mPkg = class_getInstanceMethod(profEntityCls, sel_registerName("zstylePackageId"));
            if (mPkg) method_setImplementation(mPkg, (IMP)hook_zstylePackageIdVIP);

            Method mPkgIvar = class_getInstanceMethod(profEntityCls, sel_registerName("_zstylePackageId"));
            if (mPkgIvar) method_setImplementation(mPkgIvar, (IMP)hook_zstylePackageIdVIP);

            Method mInfo = class_getInstanceMethod(profEntityCls, sel_registerName("_zstyleInfo"));
            if (mInfo) method_setImplementation(mInfo, (IMP)hook_BuddyEntity_zstyleInfo);

            Method mInfo2 = class_getInstanceMethod(profEntityCls, sel_registerName("zstyleInfo"));
            if (mInfo2) method_setImplementation(mInfo2, (IMP)hook_BuddyEntity_zstyleInfo);
        }

        Class buddyEntityCls = objc_getClass("BuddyEntity");
        if (buddyEntityCls) {
            Method m = class_getInstanceMethod(buddyEntityCls, sel_registerName("isBusinessAccount"));
            if (m) method_setImplementation(m, (IMP)hook_alwaysTrue);

            Method mZStyle = class_getInstanceMethod(buddyEntityCls, sel_registerName("isZStyle"));
            if (mZStyle) method_setImplementation(mZStyle, (IMP)hook_zstyleAlwaysTrue);

            Method mZUser = class_getInstanceMethod(buddyEntityCls, sel_registerName("isZStyleUser"));
            if (mZUser) method_setImplementation(mZUser, (IMP)hook_zstyleAlwaysTrue);

            Method mPaid = class_getInstanceMethod(buddyEntityCls, sel_registerName("isPaidZStyle"));
            if (mPaid) method_setImplementation(mPaid, (IMP)hook_zstyleAlwaysTrue);

            Method mPkg = class_getInstanceMethod(buddyEntityCls, sel_registerName("zstylePackageId"));
            if (mPkg) method_setImplementation(mPkg, (IMP)hook_zstylePackageIdVIP);

            Method mPkgIvar = class_getInstanceMethod(buddyEntityCls, sel_registerName("_zstylePackageId"));
            if (mPkgIvar) method_setImplementation(mPkgIvar, (IMP)hook_zstylePackageIdVIP);

            Method mInfo = class_getInstanceMethod(buddyEntityCls, sel_registerName("_zstyleInfo"));
            if (mInfo) {
                IMP orig = method_getImplementation(mInfo);
                class_addMethod(buddyEntityCls, sel_registerName("zaloMod_orig_zstyleInfo"), orig, method_getTypeEncoding(mInfo));
                method_setImplementation(mInfo, (IMP)hook_BuddyEntity_zstyleInfo);
            }

            Method mInfo2 = class_getInstanceMethod(buddyEntityCls, sel_registerName("zstyleInfo"));
            if (mInfo2) method_setImplementation(mInfo2, (IMP)hook_BuddyEntity_zstyleInfo);
        }

        Class profFlowCls = objc_getClass("ProfileFlowManager");
        if (profFlowCls) {
            Method m = class_getInstanceMethod(profFlowCls, sel_registerName("checkUserIsBusinessAccount:"));
            if (m) method_setImplementation(m, (IMP)hook_checkUserIsBusinessAccount);
        }

        Class friendFlowCls = objc_getClass("FriendFlowManager");
        if (friendFlowCls) {
            Method m = class_getInstanceMethod(friendFlowCls, sel_registerName("checkUserIsBusinessAccount:"));
            if (m) method_setImplementation(m, (IMP)hook_checkUserIsBusinessAccount);
        }

        Class baInfoCls = objc_getClass("_TtC6CORBiz11BALabelInfo") ?: objc_getClass("CORBiz11BALabelInfo");
        if (baInfoCls) {
            Method m1 = class_getInstanceMethod(baInfoCls, sel_registerName("hasTitleBadge"));
            if (m1) method_setImplementation(m1, (IMP)hook_alwaysTrue);

            Method m2 = class_getInstanceMethod(baInfoCls, sel_registerName("titleBadge"));
            if (m2) method_setImplementation(m2, (IMP)hook_titleBadge);

            Method m3 = class_getInstanceMethod(baInfoCls, sel_registerName("textColorBadge"));
            if (m3) method_setImplementation(m3, (IMP)hook_textColorBadge);

            Method m4 = class_getInstanceMethod(baInfoCls, sel_registerName("backgroundColorBadge"));
            if (m4) method_setImplementation(m4, (IMP)hook_backgroundColorBadge);

            NSLog(@"[DucLamXNgBao Hook] Đã kích hoạt nhãn Business chuẩn Native trong Zalo!");
        }

        // 4b. Hook All ZStyles & Nhạc Nền (ProfileLegacyUtils, SocialFeatureSetting, ProfileMusicOverlay, BuddyEntity)
        Class legacyUtilsCls = objc_getClass("ProfileLegacyUtils");
        if (legacyUtilsCls) {
            Class metaCls = object_getClass(legacyUtilsCls);
            Method mSub = class_getClassMethod(legacyUtilsCls, sel_registerName("isZStyleSubscribed:"));
            if (mSub && metaCls) {
                IMP orig = method_getImplementation(mSub);
                class_addMethod(metaCls, sel_registerName("zaloMod_orig_isZStyleSubscribed:"), orig, method_getTypeEncoding(mSub));
                method_setImplementation(mSub, (IMP)hook_isZStyleSubscribed);
            }
            Method mPkg = class_getClassMethod(legacyUtilsCls, sel_registerName("getZStylePackageId:"));
            if (mPkg && metaCls) {
                IMP orig = method_getImplementation(mPkg);
                class_addMethod(metaCls, sel_registerName("zaloMod_orig_getZStylePackageId:"), orig, method_getTypeEncoding(mPkg));
                method_setImplementation(mPkg, (IMP)hook_getZStylePackageId);
            }
            Method mDict = class_getClassMethod(legacyUtilsCls, sel_registerName("getZStyleDictOfUser:"));
            if (mDict && metaCls) {
                IMP orig = method_getImplementation(mDict);
                class_addMethod(metaCls, sel_registerName("zaloMod_orig_getZStyleDictOfUser:"), orig, method_getTypeEncoding(mDict));
                method_setImplementation(mDict, (IMP)hook_getZStyleDictOfUser);
            }
            Method mSub2 = class_getClassMethod(legacyUtilsCls, sel_registerName("objc_isSubscribeZStyle:"));
            if (mSub2) method_setImplementation(mSub2, (IMP)hook_isZStyleSubscribed);

            Method mSub3 = class_getClassMethod(legacyUtilsCls, sel_registerName("objc_isZStyleSubscribed:"));
            if (mSub3) method_setImplementation(mSub3, (IMP)hook_isZStyleSubscribed);

            Method mPkg2 = class_getClassMethod(legacyUtilsCls, sel_registerName("objc_getZStylePackageId:"));
            if (mPkg2) method_setImplementation(mPkg2, (IMP)hook_getZStylePackageId);

            Method mFrame = class_getClassMethod(legacyUtilsCls, sel_registerName("objc_isEnabledZStyleAvatarFrame"));
            if (mFrame) method_setImplementation(mFrame, (IMP)hook_zstyleAlwaysTrue);

            Method mFrameType = class_getClassMethod(legacyUtilsCls, sel_registerName("objc_isEnabledFrameTypeForProfileUIType:"));
            if (mFrameType) method_setImplementation(mFrameType, (IMP)hook_zstyleAlwaysTrue);

            NSLog(@"[DucLamXNgBao] Hook ProfileLegacyUtils ZStyle thành công!");
        }

        // Hook ProfileCombineTypeImpl: Khẳng định profile có package zStyle 1
        Class combineTypeCls = objc_getClass("_TtC9ProfileUI22ProfileCombineTypeImpl") ?: objc_getClass("ProfileCombineTypeImpl");
        if (combineTypeCls) {
            Method mPkg = class_getInstanceMethod(combineTypeCls, sel_registerName("zstylePackageId"));
            if (mPkg) method_setImplementation(mPkg, (IMP)hook_zstylePackageIdVIP);

            Method mBiz = class_getInstanceMethod(combineTypeCls, sel_registerName("zbizPackageId"));
            if (mBiz) method_setImplementation(mBiz, (IMP)hook_zstylePackageIdVIP);
        }

        // Hook StickersBottomSheetPackInfo: Mở khóa mua tất cả frame/sticker/theme ZStyle
        Class stickerPackCls = objc_getClass("_TtC19CommFeatureBusiness27StickersBottomSheetPackInfo") ?: objc_getClass("StickersBottomSheetPackInfo");
        if (stickerPackCls) {
            Method mPaid = class_getInstanceMethod(stickerPackCls, sel_registerName("isPaidZStyle"));
            if (mPaid) method_setImplementation(mPaid, (IMP)hook_zstyleAlwaysTrue);

            Method mOwned = class_getInstanceMethod(stickerPackCls, sel_registerName("isOwned"));
            if (mOwned) method_setImplementation(mOwned, (IMP)hook_zstyleAlwaysTrue);

            Method mPurchased = class_getInstanceMethod(stickerPackCls, sel_registerName("isPurchased"));
            if (mPurchased) method_setImplementation(mPurchased, (IMP)hook_zstyleAlwaysTrue);

            Method mZUser = class_getInstanceMethod(stickerPackCls, sel_registerName("isZStyleUser"));
            if (mZUser) method_setImplementation(mZUser, (IMP)hook_zstyleAlwaysTrue);

            Method mFree = class_getInstanceMethod(stickerPackCls, sel_registerName("isfree"));
            if (mFree) method_setImplementation(mFree, (IMP)hook_zstyleAlwaysTrue);

            Method mPrice = class_getInstanceMethod(stickerPackCls, sel_registerName("price"));
            if (mPrice) method_setImplementation(mPrice, (IMP)hook_zeroPrice);

            Method mZPrice = class_getInstanceMethod(stickerPackCls, sel_registerName("zStylePrice"));
            if (mZPrice) method_setImplementation(mZPrice, (IMP)hook_zeroPrice);

            Method mOrigPrice = class_getInstanceMethod(stickerPackCls, sel_registerName("originalPrice"));
            if (mOrigPrice) method_setImplementation(mOrigPrice, (IMP)hook_zeroPrice);
        }

        // Hook ProfileMusicDisplayDecision & ProfileMusicPillContext: Luôn hiển thị nhạc nền Pill Player
        Class musicDecisionCls = objc_getClass("_TtC12ProfileMusic27ProfileMusicDisplayDecision") ?: objc_getClass("ProfileMusicDisplayDecision");
        if (musicDecisionCls) {
            Method mV = class_getInstanceMethod(musicDecisionCls, sel_registerName("isViewerZStyle"));
            if (mV) method_setImplementation(mV, (IMP)hook_zstyleAlwaysTrue);

            Method mUI = class_getInstanceMethod(musicDecisionCls, sel_registerName("isZStyleProfileUI"));
            if (mUI) method_setImplementation(mUI, (IMP)hook_zstyleAlwaysTrue);
        }

        Class musicPillCtxCls = objc_getClass("_TtC12ProfileMusic23ProfileMusicPillContext") ?: objc_getClass("ProfileMusicPillContext");
        if (musicPillCtxCls) {
            Method mV = class_getInstanceMethod(musicPillCtxCls, sel_registerName("isViewerZStyle"));
            if (mV) method_setImplementation(mV, (IMP)hook_zstyleAlwaysTrue);

            Method mUI = class_getInstanceMethod(musicPillCtxCls, sel_registerName("isZStyleProfileUI"));
            if (mUI) method_setImplementation(mUI, (IMP)hook_zstyleAlwaysTrue);
        }

        Class socialSettingCls = objc_getClass("SocialFeatureSetting");
        if (socialSettingCls) {
            Method m1 = class_getClassMethod(socialSettingCls, sel_registerName("isEnabledZStyleAvatarFrame"));
            if (m1) method_setImplementation(m1, (IMP)hook_zstyleAlwaysTrue);

            Method m2 = class_getClassMethod(socialSettingCls, sel_registerName("isEnabledZStyleNameCard"));
            if (m2) method_setImplementation(m2, (IMP)hook_zstyleAlwaysTrue);

            Method m3 = class_getClassMethod(socialSettingCls, sel_registerName("enableStoryMusic"));
            if (m3) method_setImplementation(m3, (IMP)hook_zstyleAlwaysTrue);

            Method m4 = class_getClassMethod(socialSettingCls, sel_registerName("enableSwithProfileUI"));
            if (m4) method_setImplementation(m4, (IMP)hook_zstyleAlwaysTrue);

            Method m5 = class_getClassMethod(socialSettingCls, sel_registerName("isEnabledFrameType:"));
            if (m5) method_setImplementation(m5, (IMP)hook_zstyleAlwaysTrue);
            NSLog(@"[DucLamXNgBao] Hook SocialFeatureSetting ZStyle thành công!");
        }

        Class musicOverlayCls = objc_getClass("ProfileMusicOverlay");
        if (musicOverlayCls) {
            Method mViewer = class_getInstanceMethod(musicOverlayCls, sel_registerName("_isViewerZStyle"));
            if (mViewer) method_setImplementation(mViewer, (IMP)hook_zstyleAlwaysTrue);

            Method mSuggest = class_getInstanceMethod(musicOverlayCls, sel_registerName("_canSuggest"));
            if (mSuggest) method_setImplementation(mSuggest, (IMP)hook_zstyleAlwaysTrue);

            Method mPill = class_getInstanceMethod(musicOverlayCls, sel_registerName("_currentPillStatus"));
            if (mPill) {
                IMP orig = method_getImplementation(mPill);
                class_addMethod(musicOverlayCls, sel_registerName("zaloMod_orig_currentPillStatus"), orig, method_getTypeEncoding(mPill));
                method_setImplementation(mPill, (IMP)hook_currentPillStatus);
            }

            Method mLocErr = class_getInstanceMethod(musicOverlayCls, sel_registerName("isProfileMusicLocationError"));
            if (mLocErr) method_setImplementation(mLocErr, (IMP)hook_zstyleAlwaysFalse);

            Method mStop = class_getInstanceMethod(musicOverlayCls, sel_registerName("shouldStopMusic"));
            if (mStop) method_setImplementation(mStop, (IMP)hook_zstyleAlwaysFalse);
            NSLog(@"[DucLamXNgBao] Hook ProfileMusicOverlay Pill Player thành công!");
        }

        // Swizzle NSUserDefaults objectForKey: để trả về VIP ZStyle Info khi app kiểm tra
        swizzleInstanceMethod([NSUserDefaults class], @selector(objectForKey:), @selector(zaloMod_objectForKey:));

        // 5. Hook TTL vào ChatDataManager, ChatEntity & NSJSONSerialization (Chuẩn Milliseconds)
        Class chatDataMgrCls = objc_getClass("ChatDataManager");
        if (chatDataMgrCls) {
            Method mSync = class_getInstanceMethod(chatDataMgrCls, sel_registerName("syncMessageWithCurrentDisappearingTTLIfNeed:"));
            if (mSync) {
                IMP orig = method_getImplementation(mSync);
                class_addMethod(chatDataMgrCls, sel_registerName("zaloMod_orig_syncMessageWithCurrentDisappearingTTLIfNeed:"), orig, method_getTypeEncoding(mSync));
                method_setImplementation(mSync, (IMP)hook_syncMessageWithCurrentDisappearingTTLIfNeed);
                NSLog(@"[DucLamXNgBao] Hook ChatDataManager syncMessageWithCurrentDisappearingTTL thành công!");
            }

            Method mAttach = class_getInstanceMethod(chatDataMgrCls, sel_registerName("attachTTLValueForMessageIfNeed:"));
            if (mAttach) {
                IMP orig = method_getImplementation(mAttach);
                class_addMethod(chatDataMgrCls, sel_registerName("zaloMod_orig_attachTTLValueForMessageIfNeed:"), orig, method_getTypeEncoding(mAttach));
                method_setImplementation(mAttach, (IMP)hook_attachTTLValueForMessageIfNeed);
                NSLog(@"[DucLamXNgBao] Hook ChatDataManager attachTTLValueForMessageIfNeed thành công!");
            }
        }

        // Hook ChatEntity isExpiredMessage (Chống đếm giây nhanh / tự mất tin nhắn sớm)
        Class chatEntityCls = objc_getClass("ChatEntity");
        if (chatEntityCls) {
            Method mExpired = class_getInstanceMethod(chatEntityCls, sel_registerName("isExpiredMessage"));
            if (mExpired) {
                IMP orig = method_getImplementation(mExpired);
                class_addMethod(chatEntityCls, sel_registerName("zaloMod_orig_isExpiredMessage"), orig, method_getTypeEncoding(mExpired));
                method_setImplementation(mExpired, (IMP)hook_ChatEntity_isExpiredMessage);
                NSLog(@"[DucLamXNgBao] Hook ChatEntity isExpiredMessage (Chống đếm nhanh/mất sớm) thành công!");
            }
        }

        Method origJSON = class_getClassMethod([NSJSONSerialization class], @selector(dataWithJSONObject:options:error:));
        Method swizJSON = class_getClassMethod([NSJSONSerialization class], @selector(zaloMod_dataWithJSONObject:options:error:));
        if (origJSON && swizJSON) {
            method_exchangeImplementations(origJSON, swizJSON);
        }

        // 6. Dọn dẹp view cũ trên UIViewController
        swizzleInstanceMethod([UIViewController class], @selector(viewDidAppear:), @selector(zaloMod_viewDidAppear:));

        NSLog(@"[DucLamXNgBao] HOÀN TẤT KÍCH HOẠT HOOKS - SIÊU MƯỢT, TIN NHẮN CHUẨN ĐẸP!");
    });
}

// Constructor Tweak
__attribute__((constructor))
static void initZaloModVIP(void) {
    patchSiriKitCrash();

    // Kích hoạt runtime hooks chuẩn
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
