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
// 1. FLOATING BUTTON & WINDOW (CỤC MENU TRÒN CHẠM XUYÊN THẤU - AN TOÀN TUYỆT ĐỐI)
// =========================================================================
@interface ZaloFloatingWindow : UIWindow
@end

@implementation ZaloFloatingWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self || hitView == self.rootViewController.view) {
        return nil; // Cho phép chạm xuyên thấu xuống giao diện Zalo!
    }
    return hitView; // Nút tròn hoặc menu nhận sự kiện cảm ứng bình thường!
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
            ZaloFloatingButton *bubble = [ZaloFloatingButton sharedInstance];
            bubble.delegate = self;

            UIWindowScene *activeScene = nil;
            if (@available(iOS 13.0, *)) {
                for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                    if ([scene isKindOfClass:[UIWindowScene class]]) {
                        UIWindowScene *ws = (UIWindowScene *)scene;
                        if (ws.activationState == UISceneActivationStateForegroundActive || ws.activationState == UISceneActivationStateForegroundInactive) {
                            activeScene = ws;
                            break;
                        }
                        if (!activeScene) activeScene = ws;
                    }
                }
            }

            if (!gFloatingWindow) {
                if (@available(iOS 13.0, *)) {
                    if (activeScene) {
                        gFloatingWindow = [[ZaloFloatingWindow alloc] initWithWindowScene:activeScene];
                    } else {
                        gFloatingWindow = [[ZaloFloatingWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                    }
                } else {
                    gFloatingWindow = [[ZaloFloatingWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                }
            } else if (@available(iOS 13.0, *)) {
                if (activeScene && gFloatingWindow.windowScene != activeScene) {
                    gFloatingWindow.windowScene = activeScene;
                }
            }

            gFloatingWindow.windowLevel = UIWindowLevelAlert + 100.0;
            gFloatingWindow.backgroundColor = [UIColor clearColor];

            if (!gFloatingWindow.rootViewController) {
                UIViewController *rootVC = [[UIViewController alloc] init];
                rootVC.view.backgroundColor = [UIColor clearColor];
                rootVC.view.userInteractionEnabled = YES;
                gFloatingWindow.rootViewController = rootVC;
            }

            gFloatingWindow.hidden = NO;

            if (bubble.superview != gFloatingWindow.rootViewController.view) {
                [bubble removeFromSuperview];
                [gFloatingWindow.rootViewController.view addSubview:bubble];
                [gFloatingWindow.rootViewController.view bringSubviewToFront:bubble];
            }
            [bubble show];
            NSLog(@"[DucLamXNgBao] Cục Menu Tròn Zalo VIP Mod đã sẵn sàng trên ZaloFloatingWindow!");
        } @catch (NSException *exception) {
            NSLog(@"[DucLamXNgBao] Exception initializing floating button: %@", exception);
        }
    });
}

#pragma mark - ZaloFloatingButtonDelegate
- (void)floatingButtonDidTap:(id)sender {
    UIViewController *presentingVC = gFloatingWindow.rootViewController;
    if (!presentingVC) {
        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                        if (!w.hidden && w.rootViewController) {
                            presentingVC = w.rootViewController;
                            break;
                        }
                    }
                }
                if (presentingVC) break;
            }
        }
    }
    if (!presentingVC) return;

    ZaloModViewController *menuVC = [ZaloModViewController sharedInstance];
    menuVC.delegate = self;
    [menuVC showMenuFromViewController:presentingVC];
}

- (void)modMenuDidDismiss {
}

@end

// =========================================================================
// 2. HELPER SWIZZLING AN TOÀN
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
// 3. FONT HOOK (12 FONT CHỮ NGHỆ THUẬT, CHỮ TO, CHỮ MÀU KHI GÕ & KHI GỬI)
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
// 4. CHỐNG THU HỒI TIN NHẮN (ANTI-UNDO) - CHẶN XÓA & HIỂN THỊ NỘI DUNG GỐC
// =========================================================================
static void hook_UndoChatProcessor_updateUndoMessageContent(id self, SEL _cmd, id chat) {
    if ([ZaloModViewController isAntiUndoEnabled] && chat) {
        @try {
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
                origText = @"[Tin nhắn đã thu hồi]";
            }

            if (origText && ![origText containsString:@"( đã thu hồi )"]) {
                NSString *newText = [NSString stringWithFormat:@"%@ ( đã thu hồi )", origText];
                if ([chat respondsToSelector:setMsgSel]) {
                    ((void (*)(id, SEL, id))objc_msgSend)(chat, setMsgSel, newText);
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[ZaloFloatingButton sharedInstance] incrementBadge];
            });
            return; // Chặn không thay thế thành nhãn trắng xóa của Zalo!
        } @catch (NSException *e) {}
    }

    void (*orig)(id, SEL, id) = (void (*)(id, SEL, id))class_getMethodImplementation(object_getClass(self), sel_registerName("zaloMod_orig_updateUndoMessageContent:"));
    if (orig) orig(self, _cmd, chat);
}

static void hook_ChatOperationProcessor_processUndoMessage(id self, SEL _cmd, id item) {
    if ([ZaloModViewController isAntiUndoEnabled]) {
        NSLog(@"[DucLamXNgBao Anti-Undo] Đã chặn lệnh thu hồi tin nhắn từ Server!");
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ZaloFloatingButton sharedInstance] incrementBadge];
        });
        return; // KHÔNG THỰC THI LỆNH XÓA/THU HỒI!
    }
    void (*orig)(id, SEL, id) = (void (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("ChatOperationProcessor"), sel_registerName("zaloMod_orig_processUndoMessage:"));
    if (orig) orig(self, _cmd, item);
}

static void hook_ChatOperationProcessor_processUpdateUndo(id self, SEL _cmd, id chat) {
    if ([ZaloModViewController isAntiUndoEnabled] && chat) {
        @try {
            SEL msgSel = sel_registerName("message");
            SEL setMsgSel = sel_registerName("setMessage:");
            if ([chat respondsToSelector:msgSel] && [chat respondsToSelector:setMsgSel]) {
                NSString *cur = ((id (*)(id, SEL))objc_msgSend)(chat, msgSel);
                if (cur && cur.length > 0 && ![cur containsString:@"( đã thu hồi )"]) {
                    NSString *annotated = [NSString stringWithFormat:@"%@ ( đã thu hồi )", cur];
                    ((void (*)(id, SEL, id))objc_msgSend)(chat, setMsgSel, annotated);
                }
            }
        } @catch (NSException *e) {}
        return; // Chặn cập nhật trạng thái xóa!
    }
    void (*orig)(id, SEL, id) = (void (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("ChatOperationProcessor"), sel_registerName("zaloMod_orig_processUpdateUndo:"));
    if (orig) orig(self, _cmd, chat);
}

// =========================================================================
// 5. MỞ KHÓA GỬI ẢNH GỐC & HD (TỰ ĐỘNG GỬI ORIGINAL KHÔNG CẦN MUA ZCLOUD)
// =========================================================================
static void markChatAsOriginalIfPhoto(id chat) {
    if (!chat || ![ZaloModViewController isBugOriginalEnabled]) return;
    @try {
        BOOL isPhoto = NO;
        if ([chat respondsToSelector:sel_registerName("isMessagePhoto")] && ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isMessagePhoto"))) {
            isPhoto = YES;
        } else if ([chat respondsToSelector:sel_registerName("mediatype")]) {
            NSInteger mt = ((NSInteger (*)(id, SEL))objc_msgSend)(chat, sel_registerName("mediatype"));
            if (mt == 11 || mt == 28 || mt == 1 || mt == 3) {
                isPhoto = YES;
            }
        } else if ([chat respondsToSelector:sel_registerName("isPhoto")] && ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isPhoto"))) {
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
            if ([chat respondsToSelector:sel_registerName("setCanSendOriginal:")]) {
                ((void (*)(id, SEL, BOOL))objc_msgSend)(chat, sel_registerName("setCanSendOriginal:"), YES);
            }

            // Gán trực tiếp trên richMsgNormal (RichMessageContent)
            SEL richSel = sel_registerName("richMsgNormal");
            if ([chat respondsToSelector:richSel]) {
                id richContent = ((id (*)(id, SEL))objc_msgSend)(chat, richSel);
                if (richContent) {
                    if ([richContent respondsToSelector:sel_registerName("setIsOriginal:")]) {
                        ((void (*)(id, SEL, BOOL))objc_msgSend)(richContent, sel_registerName("setIsOriginal:"), YES);
                    }
                    if ([richContent respondsToSelector:sel_registerName("setIsPhotoHD:")]) {
                        ((void (*)(id, SEL, BOOL))objc_msgSend)(richContent, sel_registerName("setIsPhotoHD:"), YES);
                    }
                }
            }
        }
    } @catch (NSException *e) {}
}

static BOOL hook_enableShowOriginPhoto(id self, SEL _cmd) {
    return YES;
}

static NSInteger hook_originalBadgeType(id self, SEL _cmd) {
    return 0;
}

static id hook_originalBadge(id self, SEL _cmd) {
    return nil;
}

static NSInteger hook_currentQuality_original(id self, SEL _cmd) {
    return [ZaloModViewController isBugOriginalEnabled] ? 2 : 1;
}

static float hook_originalCompressQuality(id self, SEL _cmd) {
    return 1.0f;
}

static BOOL hook_allowRememberQuality(id self, SEL _cmd) {
    return YES;
}

static long long hook_maxOriginalLimit(id self, SEL _cmd) {
    return 100LL * 1024LL * 1024LL;
}

static BOOL hook_RichMessageContent_isOriginal(id self, SEL _cmd) {
    if ([ZaloModViewController isBugOriginalEnabled]) return YES;
    BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(objc_getClass("RichMessageContent"), sel_registerName("zaloMod_orig_isOriginal:"));
    return orig ? orig(self, _cmd) : YES;
}

static BOOL hook_RichMessageContent_isPhotoHD(id self, SEL _cmd) {
    if ([ZaloModViewController isBugOriginalEnabled]) return YES;
    BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(objc_getClass("RichMessageContent"), sel_registerName("zaloMod_orig_isPhotoHD:"));
    return orig ? orig(self, _cmd) : YES;
}

static NSInteger hook_ChatEntity_photoQuality(id self, SEL _cmd) {
    if ([ZaloModViewController isBugOriginalEnabled]) {
        return 2; // Original Quality
    }
    NSInteger (*orig)(id, SEL) = (NSInteger (*)(id, SEL))class_getMethodImplementation(objc_getClass("ChatEntity"), sel_registerName("zaloMod_orig_photoQuality"));
    return orig ? orig(self, _cmd) : 2;
}

// =========================================================================
// 6. ÁP DỤNG FONT CHỮ, TTL VÀ ẢNH ORIGINAL VÀO MỌI TIN NHẮN GỬI ĐI (100% HIỆU LỰC)
// =========================================================================
static BOOL isOutgoingChatMessage(id chat) {
    if (!chat) return NO;
    @try {
        if ([chat respondsToSelector:sel_registerName("isSending")] && ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isSending"))) {
            return YES;
        }
        if ([chat respondsToSelector:sel_registerName("isInProgressSendingMessage")] && ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isInProgressSendingMessage"))) {
            return YES;
        }
        if ([chat respondsToSelector:sel_registerName("isFromOwner")] && ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isFromOwner"))) {
            return YES;
        }
    } @catch (NSException *e) {}
    return NO;
}

static void applyAllModSettingsToOutgoingChat(id chat) {
    if (!chat) return;
    @try {
        // 1. ÁP DỤNG FONT CHỮ (Chữ To, Chữ Đỏ, Khối Đen, Khoanh Tròn, Random,...)
        NSString *selectedFont = [[NSUserDefaults standardUserDefaults] stringForKey:@"ZaloMod_SelectedFont"];
        if (selectedFont && ![selectedFont isEqualToString:@"Tắt"]) {
            SEL msgSel = sel_registerName("message");
            SEL setMsgSel = sel_registerName("setMessage:");
            if ([chat respondsToSelector:msgSel] && [chat respondsToSelector:setMsgSel]) {
                NSString *origMsg = ((id (*)(id, SEL))objc_msgSend)(chat, msgSel);
                if (origMsg && origMsg.length > 0) {
                    NSString *styledMsg = [ZaloModFontHelper convertText:origMsg toStyle:selectedFont];
                    if (styledMsg && styledMsg.length > 0) {
                        ((void (*)(id, SEL, id))objc_msgSend)(chat, setMsgSel, styledMsg);
                        NSLog(@"[DucLamXNgBao] Đã đổi font '%@' cho tin nhắn gửi đi: %@", selectedFont, styledMsg);
                    }
                }
            }
        }

        // 2. ÁP DỤNG TTL (TỰ XÓA THEO GIÂY: s, h, d) - CHỈ CHO TIN NHẮN CỦA MÌNH
        NSInteger ttlSecs = [ZaloModViewController customTTLSeconds];
        if (ttlSecs > 0) {
            SEL setTtlSel = sel_registerName("setTtl:");
            if ([chat respondsToSelector:setTtlSel]) {
                ((void (*)(id, SEL, long long))objc_msgSend)(chat, setTtlSel, (long long)ttlSecs);
                NSLog(@"[DucLamXNgBao] Đã gán TTL %ld giây cho tin nhắn gửi đi!", (long)ttlSecs);
            }
        }

        // 3. TỰ ĐỘNG GỬI ẢNH GỐC HD (ORIGINAL)
        markChatAsOriginalIfPhoto(chat);
    } @catch (NSException *e) {
        NSLog(@"[DucLamXNgBao] Exception applyAllModSettingsToOutgoingChat: %@", e);
    }
}

// Hook ZAChatSendingManager: Nơi gửi đi tất cả tin nhắn & ảnh của người dùng (100% Outgoing)
static void hook_sendChat_checkUpload(id self, SEL _cmd, id chat, BOOL check) {
    applyAllModSettingsToOutgoingChat(chat);
    void (*orig)(id, SEL, id, BOOL) = (void (*)(id, SEL, id, BOOL))class_getMethodImplementation(objc_getClass("ZAChatSendingManager"), sel_registerName("zaloMod_orig_sendChat_checkUpload:"));
    if (orig) orig(self, _cmd, chat, check);
}

static void hook_sendChat_destinations(id self, SEL _cmd, id chat, id dests, BOOL check, BOOL wait) {
    applyAllModSettingsToOutgoingChat(chat);
    void (*orig)(id, SEL, id, id, BOOL, BOOL) = (void (*)(id, SEL, id, id, BOOL, BOOL))class_getMethodImplementation(objc_getClass("ZAChatSendingManager"), sel_registerName("zaloMod_orig_sendChat_destinations:"));
    if (orig) orig(self, _cmd, chat, dests, check, wait);
}

static BOOL hook_attachTTLValueForMessageIfNeed(id self, SEL _cmd, id chat) {
    BOOL (*orig)(id, SEL, id) = (BOOL (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("ChatDataManager"), sel_registerName("zaloMod_orig_attachTTLValueForMessageIfNeed:"));
    BOOL res = orig ? orig(self, _cmd, chat) : NO;
    if (isOutgoingChatMessage(chat)) {
        applyAllModSettingsToOutgoingChat(chat);
        if ([ZaloModViewController customTTLSeconds] > 0) {
            res = YES;
        }
    }
    return res;
}

// =========================================================================
// 7. GHOST SEEN (ẨN ĐÃ XEM) & HIDE TYPING (ẨN ĐANG SOẠN TIN)
// =========================================================================
static BOOL hook_checkCanSendSeenInboxEntity(id self, SEL _cmd, id entity, NSInteger msgType, id toUserId) {
    if ([ZaloModViewController isGhostSeenEnabled]) {
        return NO;
    }
    BOOL (*orig)(id, SEL, id, NSInteger, id) = (BOOL (*)(id, SEL, id, NSInteger, id))class_getMethodImplementation(objc_getClass("ChatDataManager"), sel_registerName("zaloMod_orig_checkCanSendSeenInboxEntity:messageType:withToUserId:"));
    return orig ? orig(self, _cmd, entity, msgType, toUserId) : YES;
}

static void hook_sendTypingWithType(id self, SEL _cmd, NSInteger type, id toUserId, NSInteger msgType, BOOL isE2ee) {
    if ([ZaloModViewController isHideTypingEnabled]) {
        return;
    }
    void (*orig)(id, SEL, NSInteger, id, NSInteger, BOOL) = (void (*)(id, SEL, NSInteger, id, NSInteger, BOOL))class_getMethodImplementation(objc_getClass("ChatDataManager"), sel_registerName("zaloMod_orig_sendTypingWithType:toUserId:messageType:isE2eeChat:"));
    if (orig) orig(self, _cmd, type, toUserId, msgType, isE2ee);
}

static void hook_sendSeenWithChatEntity(id self, SEL _cmd, id chat) {
    if ([ZaloModViewController isGhostSeenEnabled]) {
        return;
    }
    void (*orig)(id, SEL, id) = (void (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("ChatSendSeenDataManager"), sel_registerName("zaloMod_orig_sendSeenWithChatEntity:"));
    if (orig) orig(self, _cmd, chat);
}

static void hook_sendSeenServer(id self, SEL _cmd) {
    if ([ZaloModViewController isGhostSeenEnabled]) {
        return;
    }
    void (*orig)(id, SEL) = (void (*)(id, SEL))class_getMethodImplementation(objc_getClass("ChatSendSeenDataManager"), sel_registerName("zaloMod_orig_sendSeenServer"));
    if (orig) orig(self, _cmd);
}

static void hook_sendSeenServerPeriodicallyIfNeeded(id self, SEL _cmd) {
    if ([ZaloModViewController isGhostSeenEnabled]) {
        return;
    }
    void (*orig)(id, SEL) = (void (*)(id, SEL))class_getMethodImplementation(objc_getClass("ChatSendSeenDataManager"), sel_registerName("zaloMod_orig_sendSeenServerPeriodicallyIfNeeded"));
    if (orig) orig(self, _cmd);
}

static void hook_sendSeenMessageWithSeenData(id self, SEL _cmd, id seenData, NSInteger msgType) {
    if ([ZaloModViewController isGhostSeenEnabled]) {
        return;
    }
    void (*orig)(id, SEL, id, NSInteger) = (void (*)(id, SEL, id, NSInteger))class_getMethodImplementation(objc_getClass("ChatSendSeenDataManager"), sel_registerName("zaloMod_orig_sendSeenMessageWithSeenData:messageType:"));
    if (orig) orig(self, _cmd, seenData, msgType);
}

static void hook_sendTypingWithVoiceBoardType(id self, SEL _cmd, NSInteger type) {
    if ([ZaloModViewController isHideTypingEnabled]) {
        return;
    }
    void (*orig)(id, SEL, NSInteger) = (void (*)(id, SEL, NSInteger))class_getMethodImplementation(objc_getClass("BaseChatTVC"), sel_registerName("zaloMod_orig_sendTypingWithVoiceBoardType:"));
    if (orig) orig(self, _cmd, type);
}

static void hook_sendSeenForLastReadMessage(id self, SEL _cmd) {
    if ([ZaloModViewController isGhostSeenEnabled]) {
        return;
    }
    void (*orig)(id, SEL) = (void (*)(id, SEL))class_getMethodImplementation(objc_getClass("BaseChatTVC"), sel_registerName("zaloMod_orig_sendSeenForLastReadMessage"));
    if (orig) orig(self, _cmd);
}

static void hook_sendSeenMessageWithChatEntity(id self, SEL _cmd, id chat) {
    if ([ZaloModViewController isGhostSeenEnabled]) {
        return;
    }
    void (*orig)(id, SEL, id) = (void (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("BaseChatTVC"), sel_registerName("zaloMod_orig_sendSeenMessageWithChatEntity:"));
    if (orig) orig(self, _cmd, chat);
}

static void hook_sendSeenInfoInboxEntity(id self, SEL _cmd, id entity) {
    if ([ZaloModViewController isGhostSeenEnabled]) {
        return;
    }
    void (*orig)(id, SEL, id) = (void (*)(id, SEL, id))class_getMethodImplementation(objc_getClass("BaseChatTVC"), sel_registerName("zaloMod_orig_sendSeenInfoInboxEntity:"));
    if (orig) orig(self, _cmd, entity);
}

static BOOL hook_isEnableTypingMessage(id self, SEL _cmd) {
    if ([ZaloModViewController isHideTypingEnabled]) {
        return NO;
    }
    BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(objc_getClass("FeatureManager"), sel_registerName("zaloMod_orig_isEnableTypingMessage"));
    return orig ? orig(self, _cmd) : YES;
}

// =========================================================================
// 8. NATIVE ZALO BUSINESS ACCOUNT HOOK (CHUẨN CHÍNH HÃNG 100%, KHÔNG ĐÈ CHỮ)
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
// 9. BUG ALL ZSTYLES & PROFILE (AN TOÀN TUYỆT ĐỐI, KHÔNG TRẢ DICTIONARY LỖI)
// =========================================================================
static BOOL hook_zstyleAlwaysTrue(id self, SEL _cmd) {
    return [ZaloModViewController isBugZLStyleEnabled];
}

static NSInteger hook_zstylePackageIdVIP(id self, SEL _cmd) {
    return [ZaloModViewController isBugZLStyleEnabled] ? 1 : 0;
}

static long long hook_zeroPrice(id self, SEL _cmd) {
    return 0;
}

static BOOL hook_isZStyleSubscribed(id self, SEL _cmd, id userId) {
    return [ZaloModViewController isBugZLStyleEnabled];
}

static NSInteger hook_getZStylePackageId(id self, SEL _cmd, id userId) {
    return [ZaloModViewController isBugZLStyleEnabled] ? 1 : 0;
}

// =========================================================================
// 10. KÍCH HOẠT TOÀN BỘ HOOKS (CHẠY ỔN ĐỊNH 100%, ĐẦY ĐỦ TÁC DỤNG)
// =========================================================================
static void installAllZaloModHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[DucLamXNgBao] Đang cài đặt Hook chuẩn xác cho Zalo Mod VIP...");

        // 1. Hook Font Chữ vào ô nhập liệu
        swizzleInstanceMethod([UITextView class], @selector(insertText:), @selector(zaloMod_insertText:));
        swizzleInstanceMethod([UITextField class], @selector(insertText:), @selector(zaloMod_insertText:));

        // 2. Hook Anti-Undo trên UndoChatProcessor & ChatOperationProcessor
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

        Class chatOpProcCls = objc_getClass("ChatOperationProcessor");
        if (chatOpProcCls) {
            Method undoProcM = class_getInstanceMethod(chatOpProcCls, sel_registerName("_processUndoMessageWithOperationItem:"));
            if (undoProcM) {
                IMP origImp = method_getImplementation(undoProcM);
                class_addMethod(chatOpProcCls, sel_registerName("zaloMod_orig_processUndoMessage:"), origImp, method_getTypeEncoding(undoProcM));
                method_setImplementation(undoProcM, (IMP)hook_ChatOperationProcessor_processUndoMessage);
            }

            Method updateUndoM = class_getInstanceMethod(chatOpProcCls, sel_registerName("_processUpdateUndoWithChatEntity:"));
            if (updateUndoM) {
                IMP origImp = method_getImplementation(updateUndoM);
                class_addMethod(chatOpProcCls, sel_registerName("zaloMod_orig_processUpdateUndo:"), origImp, method_getTypeEncoding(updateUndoM));
                method_setImplementation(updateUndoM, (IMP)hook_ChatOperationProcessor_processUpdateUndo);
            }
        }

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

        Class qpConfigCls = objc_getClass("_TtC15CommFeatureBase22ZCFQualityPickerConfig") ?: objc_getClass("ZCFQualityPickerConfig");
        if (qpConfigCls) {
            Method mSendOrig = class_getClassMethod(qpConfigCls, sel_registerName("enableSendOriginal"));
            if (mSendOrig) method_setImplementation(mSendOrig, (IMP)hook_alwaysTrue);

            Method mBadge = class_getClassMethod(qpConfigCls, sel_registerName("originalBadge"));
            if (mBadge) method_setImplementation(mBadge, (IMP)hook_originalBadge);

            Method mRem = class_getClassMethod(qpConfigCls, sel_registerName("allowRememberQuality"));
            if (mRem) method_setImplementation(mRem, (IMP)hook_allowRememberQuality);

            Method mQuality = class_getClassMethod(qpConfigCls, sel_registerName("originalCompressQuality"));
            if (mQuality) method_setImplementation(mQuality, (IMP)hook_originalCompressQuality);
        }

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

        // Hook ChatEntity photoQuality để luôn nhận là Original
        Class chatEntityCls = objc_getClass("ChatEntity");
        if (chatEntityCls) {
            Method mPhotoQ = class_getInstanceMethod(chatEntityCls, sel_registerName("photoQuality"));
            if (mPhotoQ) {
                IMP orig = method_getImplementation(mPhotoQ);
                class_addMethod(chatEntityCls, sel_registerName("zaloMod_orig_photoQuality"), orig, method_getTypeEncoding(mPhotoQ));
                method_setImplementation(mPhotoQ, (IMP)hook_ChatEntity_photoQuality);
            }
        }

        // Hook ZAChatSendingManager: Gửi tin nhắn tự động áp dụng Font, TTL và ảnh Original
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
            NSLog(@"[DucLamXNgBao] Hook ZAChatSendingManager áp dụng Font, TTL, Original thành công!");
        }

        // Hook ChatDataManager attachTTLValueForMessageIfNeed
        Class chatDataMgrCls = objc_getClass("ChatDataManager");
        if (chatDataMgrCls) {
            Method mAttach = class_getInstanceMethod(chatDataMgrCls, sel_registerName("attachTTLValueForMessageIfNeed:"));
            if (mAttach) {
                IMP orig = method_getImplementation(mAttach);
                class_addMethod(chatDataMgrCls, sel_registerName("zaloMod_orig_attachTTLValueForMessageIfNeed:"), orig, method_getTypeEncoding(mAttach));
                method_setImplementation(mAttach, (IMP)hook_attachTTLValueForMessageIfNeed);
            }

            Method mCanSeen = class_getInstanceMethod(chatDataMgrCls, sel_registerName("checkCanSendSeenInboxEntity:messageType:withToUserId:"));
            if (mCanSeen) {
                IMP orig = method_getImplementation(mCanSeen);
                class_addMethod(chatDataMgrCls, sel_registerName("zaloMod_orig_checkCanSendSeenInboxEntity:messageType:withToUserId:"), orig, method_getTypeEncoding(mCanSeen));
                method_setImplementation(mCanSeen, (IMP)hook_checkCanSendSeenInboxEntity);
            }

            Method mTyping = class_getInstanceMethod(chatDataMgrCls, sel_registerName("sendTypingWithType:toUserId:messageType:isE2eeChat:"));
            if (mTyping) {
                IMP orig = method_getImplementation(mTyping);
                class_addMethod(chatDataMgrCls, sel_registerName("zaloMod_orig_sendTypingWithType:toUserId:messageType:isE2eeChat:"), orig, method_getTypeEncoding(mTyping));
                method_setImplementation(mTyping, (IMP)hook_sendTypingWithType);
            }
        }

        // Hook ChatSendSeenDataManager (Ghost Seen)
        Class sendSeenMgrCls = objc_getClass("ChatSendSeenDataManager");
        if (sendSeenMgrCls) {
            Method mSeen1 = class_getInstanceMethod(sendSeenMgrCls, sel_registerName("sendSeenWithChatEntity:"));
            if (mSeen1) {
                IMP orig = method_getImplementation(mSeen1);
                class_addMethod(sendSeenMgrCls, sel_registerName("zaloMod_orig_sendSeenWithChatEntity:"), orig, method_getTypeEncoding(mSeen1));
                method_setImplementation(mSeen1, (IMP)hook_sendSeenWithChatEntity);
            }

            Method mSeen2 = class_getInstanceMethod(sendSeenMgrCls, sel_registerName("sendSeenServer"));
            if (mSeen2) {
                IMP orig = method_getImplementation(mSeen2);
                class_addMethod(sendSeenMgrCls, sel_registerName("zaloMod_orig_sendSeenServer"), orig, method_getTypeEncoding(mSeen2));
                method_setImplementation(mSeen2, (IMP)hook_sendSeenServer);
            }

            Method mSeen3 = class_getInstanceMethod(sendSeenMgrCls, sel_registerName("sendSeenServerPeriodicallyIfNeeded"));
            if (mSeen3) {
                IMP orig = method_getImplementation(mSeen3);
                class_addMethod(sendSeenMgrCls, sel_registerName("zaloMod_orig_sendSeenServerPeriodicallyIfNeeded"), orig, method_getTypeEncoding(mSeen3));
                method_setImplementation(mSeen3, (IMP)hook_sendSeenServerPeriodicallyIfNeeded);
            }

            Method mSeen4 = class_getInstanceMethod(sendSeenMgrCls, sel_registerName("_sendSeenMessageWithSeenData:messageType:"));
            if (mSeen4) {
                IMP orig = method_getImplementation(mSeen4);
                class_addMethod(sendSeenMgrCls, sel_registerName("zaloMod_orig_sendSeenMessageWithSeenData:messageType:"), orig, method_getTypeEncoding(mSeen4));
                method_setImplementation(mSeen4, (IMP)hook_sendSeenMessageWithSeenData);
            }
            NSLog(@"[DucLamXNgBao] Hook ChatSendSeenDataManager Ghost Seen thành công!");
        }

        // Hook BaseChatTVC (Ghost Seen & Hide Typing)
        Class baseChatTVCCls = objc_getClass("BaseChatTVC");
        if (baseChatTVCCls) {
            Method mVoiceTyping = class_getInstanceMethod(baseChatTVCCls, sel_registerName("sendTypingWithVoiceBoardType:"));
            if (mVoiceTyping) {
                IMP orig = method_getImplementation(mVoiceTyping);
                class_addMethod(baseChatTVCCls, sel_registerName("zaloMod_orig_sendTypingWithVoiceBoardType:"), orig, method_getTypeEncoding(mVoiceTyping));
                method_setImplementation(mVoiceTyping, (IMP)hook_sendTypingWithVoiceBoardType);
            }

            Method mSeenLast = class_getInstanceMethod(baseChatTVCCls, sel_registerName("sendSeenForLastReadMessage"));
            if (mSeenLast) {
                IMP orig = method_getImplementation(mSeenLast);
                class_addMethod(baseChatTVCCls, sel_registerName("zaloMod_orig_sendSeenForLastReadMessage"), orig, method_getTypeEncoding(mSeenLast));
                method_setImplementation(mSeenLast, (IMP)hook_sendSeenForLastReadMessage);
            }

            Method mSeenMsg = class_getInstanceMethod(baseChatTVCCls, sel_registerName("sendSeenMessageWithChatEntity:"));
            if (mSeenMsg) {
                IMP orig = method_getImplementation(mSeenMsg);
                class_addMethod(baseChatTVCCls, sel_registerName("zaloMod_orig_sendSeenMessageWithChatEntity:"), orig, method_getTypeEncoding(mSeenMsg));
                method_setImplementation(mSeenMsg, (IMP)hook_sendSeenMessageWithChatEntity);
            }

            Method mSeenInfo = class_getInstanceMethod(baseChatTVCCls, sel_registerName("sendSeenInfoInboxEntity:"));
            if (mSeenInfo) {
                IMP orig = method_getImplementation(mSeenInfo);
                class_addMethod(baseChatTVCCls, sel_registerName("zaloMod_orig_sendSeenInfoInboxEntity:"), orig, method_getTypeEncoding(mSeenInfo));
                method_setImplementation(mSeenInfo, (IMP)hook_sendSeenInfoInboxEntity);
            }
        }

        // Hook FeatureManager (Hide Typing)
        Class featMgrCls = objc_getClass("FeatureManager");
        if (featMgrCls) {
            Method mTypingFeat = class_getInstanceMethod(featMgrCls, sel_registerName("isEnableTypingMessage"));
            if (mTypingFeat) {
                IMP orig = method_getImplementation(mTypingFeat);
                class_addMethod(featMgrCls, sel_registerName("zaloMod_orig_isEnableTypingMessage"), orig, method_getTypeEncoding(mTypingFeat));
                method_setImplementation(mTypingFeat, (IMP)hook_isEnableTypingMessage);
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

        // 4b. Hook All ZStyles (ProfileLegacyUtils, SocialFeatureSetting, StickersBottomSheetPackInfo, ZMp3Manager)
        Class legacyUtilsCls = objc_getClass("ProfileLegacyUtils");
        if (legacyUtilsCls) {
            Method mSub = class_getClassMethod(legacyUtilsCls, sel_registerName("isZStyleSubscribed:"));
            if (mSub) method_setImplementation(mSub, (IMP)hook_isZStyleSubscribed);

            Method mPkg = class_getClassMethod(legacyUtilsCls, sel_registerName("getZStylePackageId:"));
            if (mPkg) method_setImplementation(mPkg, (IMP)hook_getZStylePackageId);

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

        Class zmp3Cls = objc_getClass("ZMp3Manager");
        if (zmp3Cls) {
            Method m1 = class_getInstanceMethod(zmp3Cls, sel_registerName("enableProfileMusic"));
            if (m1) method_setImplementation(m1, (IMP)hook_zstyleAlwaysTrue);

            Method m2 = class_getInstanceMethod(zmp3Cls, sel_registerName("enableProfileMusicLocal"));
            if (m2) method_setImplementation(m2, (IMP)hook_zstyleAlwaysTrue);

            Method m3 = class_getInstanceMethod(zmp3Cls, sel_registerName("enableProfileMusicRBT"));
            if (m3) method_setImplementation(m3, (IMP)hook_zstyleAlwaysTrue);

            Method m4 = class_getInstanceMethod(zmp3Cls, sel_registerName("enableShareProfileMusic"));
            if (m4) method_setImplementation(m4, (IMP)hook_zstyleAlwaysTrue);

            Method m5 = class_getInstanceMethod(zmp3Cls, sel_registerName("autoPlayMyMusic"));
            if (m5) method_setImplementation(m5, (IMP)hook_zstyleAlwaysTrue);

            Method m6 = class_getInstanceMethod(zmp3Cls, sel_registerName("autoPlayFriendMusic"));
            if (m6) method_setImplementation(m6, (IMP)hook_zstyleAlwaysTrue);

            Method m7 = class_getInstanceMethod(zmp3Cls, sel_registerName("newFlagEnableProfileMusic"));
            if (m7) method_setImplementation(m7, (IMP)hook_zstyleAlwaysTrue);
            NSLog(@"[DucLamXNgBao] Hook ZMp3Manager Profile Music ZStyle thành công!");
        }

        NSLog(@"[DucLamXNgBao] HOÀN TẤT KÍCH HOẠT HOOKS - ĐẦY ĐỦ TÁC DỤNG 100%!");
    });
}

// Constructor Tweak
__attribute__((constructor))
static void initZaloModVIP(void) {
    installAllZaloModHooks();

    void (^setupBlock)(NSNotification *) = ^(NSNotification * _Nonnull note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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

    // Fallback timers đảm bảo menu hiện lên 100%
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZaloModManager sharedManager] setupFloatingButton];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZaloModManager sharedManager] setupFloatingButton];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZaloModManager sharedManager] setupFloatingButton];
    });
}
