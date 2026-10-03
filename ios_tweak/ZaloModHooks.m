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
// 3. FONT HOOK (15 FONT CHỮ NGHỆ THUẬT, CHỮ TO, ALL MÀU SẮC Ô NHẬP)
// =========================================================================
static NSString *getEffectiveFont(void) {
    NSString *selectedFont = [[NSUserDefaults standardUserDefaults] stringForKey:@"ZaloMod_SelectedFont"];
    if (!selectedFont || [selectedFont isEqualToString:@"Tắt"]) {
        NSString *col = [ZaloModViewController selectedTextColorName];
        if ([col isEqualToString:@"Đỏ"]) return @"Chữ Đỏ";
        if ([col isEqualToString:@"Xanh Dương"]) return @"Chữ Xanh";
        if ([col isEqualToString:@"Random"]) return @"Random Màu Font";
        return nil;
    }
    return selectedFont;
}

@interface UITextView (ZaloModFontHook)
@end

@implementation UITextView (ZaloModFontHook)
- (void)zaloMod_insertText:(NSString *)text {
    NSString *effFont = getEffectiveFont();
    NSString *textToInsert = text;
    if (effFont && text.length > 0) {
        textToInsert = [ZaloModFontHelper convertText:text toStyle:effFont];
    }
    [self zaloMod_insertText:textToInsert];

    // Áp dụng Cỡ Chữ (Chữ To)
    CGFloat customSize = [ZaloModViewController customFontSize];
    if (customSize > 0) {
        @try {
            self.font = [UIFont systemFontOfSize:customSize];
        } @catch (NSException *e) {}
    }

    // Áp dụng Màu Chữ Ô Nhập (All Màu & Random)
    UIColor *customColor = [ZaloModViewController selectedTextColor];
    if (customColor) {
        @try {
            self.textColor = customColor;
        } @catch (NSException *e) {}
    }
}
@end

@interface UITextField (ZaloModFontHook)
@end

@implementation UITextField (ZaloModFontHook)
- (void)zaloMod_insertText:(NSString *)text {
    NSString *effFont = getEffectiveFont();
    NSString *textToInsert = text;
    if (effFont && text.length > 0) {
        textToInsert = [ZaloModFontHelper convertText:text toStyle:effFont];
    }
    [self zaloMod_insertText:textToInsert];

    // Áp dụng Cỡ Chữ (Chữ To)
    CGFloat customSize = [ZaloModViewController customFontSize];
    if (customSize > 0) {
        @try {
            self.font = [UIFont systemFontOfSize:customSize];
        } @catch (NSException *e) {}
    }

    // Áp dụng Màu Chữ Ô Nhập (All Màu & Random)
    UIColor *customColor = [ZaloModViewController selectedTextColor];
    if (customColor) {
        @try {
            self.textColor = customColor;
        } @catch (NSException *e) {}
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
// 6. ÁP DỤNG FONT CHỮ, TTL VÀ ẢNH ORIGINAL VÀO MỌI TIN NHẮN GỬI ĐI
// (CHỈ TTL TIN NHẮN CỦA MÌNH - KHÔNG TTL TIN NHẮN NGƯỜI KHÁC!)
// =========================================================================
static BOOL isOutgoingChatMessage(id chat) {
    if (!chat) return NO;
    @try {
        if ([chat respondsToSelector:sel_registerName("isFromOwner")] && ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isFromOwner"))) {
            return YES;
        }
        if ([chat respondsToSelector:sel_registerName("isSending")] && ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isSending"))) {
            return YES;
        }
        if ([chat respondsToSelector:sel_registerName("isInProgressSendingMessage")] && ((BOOL (*)(id, SEL))objc_msgSend)(chat, sel_registerName("isInProgressSendingMessage"))) {
            return YES;
        }
    } @catch (NSException *e) {}
    return NO;
}

static void applyAllModSettingsToOutgoingChat(id chat) {
    if (!chat) return;
    @try {
        // 1. ÁP DỤNG FONT CHỮ (Chữ To, Chữ Đỏ, Khối Đen, Khoanh Tròn, Random,...)
        NSString *effFont = getEffectiveFont();
        if (effFont) {
            SEL msgSel = sel_registerName("message");
            SEL setMsgSel = sel_registerName("setMessage:");
            if ([chat respondsToSelector:msgSel] && [chat respondsToSelector:setMsgSel]) {
                NSString *origMsg = ((id (*)(id, SEL))objc_msgSend)(chat, msgSel);
                if (origMsg && origMsg.length > 0) {
                    NSString *styledMsg = [ZaloModFontHelper convertText:origMsg toStyle:effFont];
                    if (styledMsg && styledMsg.length > 0) {
                        ((void (*)(id, SEL, id))objc_msgSend)(chat, setMsgSel, styledMsg);
                        NSLog(@"[DucLamXNgBao] Đã đổi font '%@' cho tin nhắn gửi đi: %@", effFont, styledMsg);
                    }
                }
            }
        }

        // 2. ÁP DỤNG TTL (TỰ XÓA THEO GIÂY: s, h, d) - CHỈ CHO TIN NHẮN GỬI ĐI!
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

// Hook ChatEntity isExpiredMessage: Đảm bảo tin nhắn tự gán TTL không bị client xóa nhầm trước hạn!
static BOOL hook_ChatEntity_isExpiredMessage(id self, SEL _cmd) {
    if (!self) return NO;
    @try {
        BOOL isOwner = isOutgoingChatMessage(self);
        if (isOwner) {
            NSInteger ttlSecs = [ZaloModViewController customTTLSeconds];
            if (ttlSecs > 0) {
                long long createTime = 0;
                if ([self respondsToSelector:sel_registerName("createTime")]) {
                    createTime = ((long long (*)(id, SEL))objc_msgSend)(self, sel_registerName("createTime"));
                } else if ([self respondsToSelector:sel_registerName("time")]) {
                    createTime = ((long long (*)(id, SEL))objc_msgSend)(self, sel_registerName("time"));
                }

                if (createTime < 100000000000LL && createTime > 0) {
                    createTime *= 1000LL; // Đưa về miliseconds
                }

                long long nowMs = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
                long long targetTTLMs = (long long)ttlSecs * 1000LL;

                if (createTime > 0 && (nowMs < createTime + targetTTLMs)) {
                    return NO; // CHƯA HẾT HẠN TTL TỰ CHỌN -> CHƯA HỦY TIN NHẮN!
                }
            }
        }
    } @catch (NSException *e) {}

    BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))class_getMethodImplementation(objc_getClass("ChatEntity"), sel_registerName("zaloMod_orig_isExpiredMessage"));
    return orig ? orig(self, _cmd) : NO;
}

// =========================================================================
// 6B. HOOK BASECHATTVC: ĐỔI FONT VÀ MÀU TRỰC TIẾP KHI GỬI & HIỂN THỊ CELL
// (ĐẢM BẢO 100% GỬI TIN NHẮN KHÔNG BỊ MẤT FONT, KHÔNG MẤT MÀU!)
// =========================================================================
static NSString *hook_BaseChatTVC_getTextToSend(id self, SEL _cmd) {
    NSString *(*orig)(id, SEL) = (NSString *(*)(id, SEL))class_getMethodImplementation(objc_getClass("BaseChatTVC"), sel_registerName("zaloMod_orig_getTextToSend"));
    NSString *text = orig ? orig(self, _cmd) : nil;
    if (text && text.length > 0) {
        NSString *effFont = getEffectiveFont();
        if (effFont) {
            text = [ZaloModFontHelper convertText:text toStyle:effFont];
        }
    }
    return text;
}

static void hook_BaseChatTVC_sendMessageWithText_needCreateBubble(id self, SEL _cmd, NSString *text, BOOL needCreateBubble) {
    NSString *styledText = text;
    if (text && text.length > 0) {
        NSString *effFont = getEffectiveFont();
        if (effFont) {
            styledText = [ZaloModFontHelper convertText:text toStyle:effFont];
        }
    }
    void (*orig)(id, SEL, NSString *, BOOL) = (void (*)(id, SEL, NSString *, BOOL))class_getMethodImplementation(objc_getClass("BaseChatTVC"), sel_registerName("zaloMod_orig_sendMessageWithText:needCreateBubble:"));
    if (orig) orig(self, _cmd, styledText, needCreateBubble);
}

static id hook_BaseChatTVC_createChatToSendWithMessage(id self, SEL _cmd, NSString *message, int mediaType, NSString *clientMsgId) {
    NSString *styledMsg = message;
    if (message && message.length > 0) {
        NSString *effFont = getEffectiveFont();
        if (effFont) {
            styledMsg = [ZaloModFontHelper convertText:message toStyle:effFont];
        }
    }
    id (*orig)(id, SEL, NSString *, int, NSString *) = (id (*)(id, SEL, NSString *, int, NSString *))class_getMethodImplementation(objc_getClass("BaseChatTVC"), sel_registerName("zaloMod_orig_createChatToSendWithMessage:mediaType:clientMsgId:"));
    id chat = orig ? orig(self, _cmd, styledMsg, mediaType, clientMsgId) : nil;
    if (chat) {
        NSInteger ttlSecs = [ZaloModViewController customTTLSeconds];
        if (ttlSecs > 0 && [chat respondsToSelector:sel_registerName("setTtl:")]) {
            ((void (*)(id, SEL, long long))objc_msgSend)(chat, sel_registerName("setTtl:"), (long long)ttlSecs);
        }
        markChatAsOriginalIfPhoto(chat);
    }
    return chat;
}

// Duyệt cây UIView để áp dụng Màu Chữ và Cỡ Chữ (Chữ To) lên các Bong Bóng Tin Nhắn trong Chat
static void recursivelyStyleCellView(UIView *view, UIColor *color, CGFloat fontSize) {
    if (!view) return;
    @try {
        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *lbl = (UILabel *)view;
            if (lbl.text.length > 0 && lbl.font.pointSize >= 11.5) {
                if (color) lbl.textColor = color;
                if (fontSize > 0) {
                    UIFontDescriptor *desc = lbl.font.fontDescriptor;
                    if (desc) {
                        lbl.font = [UIFont fontWithDescriptor:desc size:fontSize];
                    } else {
                        lbl.font = [UIFont systemFontOfSize:fontSize];
                    }
                }
            }
        } else if ([view isKindOfClass:[UITextView class]]) {
            UITextView *tv = (UITextView *)view;
            if (tv.text.length > 0) {
                if (color) tv.textColor = color;
                if (fontSize > 0) {
                    UIFontDescriptor *desc = tv.font.fontDescriptor;
                    if (desc) {
                        tv.font = [UIFont fontWithDescriptor:desc size:fontSize];
                    } else {
                        tv.font = [UIFont systemFontOfSize:fontSize];
                    }
                }
            }
        }
        for (UIView *sub in view.subviews) {
            recursivelyStyleCellView(sub, color, fontSize);
        }
    } @catch (NSException *e) {}
}

static void hook_BaseChatTVC_willDisplayCell_forItemAtIndexPath(id self, SEL _cmd, id cell, id indexPath) {
    void (*orig)(id, SEL, id, id) = (void (*)(id, SEL, id, id))class_getMethodImplementation(objc_getClass("BaseChatTVC"), sel_registerName("zaloMod_orig_willDisplayCell:forItemAtIndexPath:"));
    if (orig) orig(self, _cmd, cell, indexPath);

    @try {
        UIColor *textColor = [ZaloModViewController selectedTextColor];
        CGFloat customSize = [ZaloModViewController customFontSize];
        if (textColor || customSize > 0) {
            if ([cell isKindOfClass:[UIView class]]) {
                recursivelyStyleCellView((UIView *)cell, textColor, customSize);
            }
        }
    } @catch (NSException *e) {}
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
// 8. NATIVE ZALO BUSINESS ACCOUNT HOOK
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
// 9. BUG ALL ZSTYLES & HIỂN THỊ NHẠC NỀN (PILL PLAYER) TRÊN PROFILE
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

static void hook_voidDoNothing(id self, SEL _cmd) {
    // Chặn hiển thị Modal Paywall Nâng Cấp Tài Khoản!
}

static BOOL hook_adBlockAlwaysFalse(id self, SEL _cmd) {
    return ![ZaloModViewController isAdBlockEnabled];
}

static long long hook_unlimitedMediaDuration(id self, SEL _cmd) {
    return [ZaloModViewController isUnlimitedMediaEnabled] ? 999999LL : 60LL;
}

static long long hook_unlimitedMediaFileSize(id self, SEL _cmd) {
    return [ZaloModViewController isUnlimitedMediaEnabled] ? 2147483647LL : 104857600LL;
}

static BOOL hook_rbtAlwaysTrue(id self, SEL _cmd) {
    return [ZaloModViewController isUnlockRBTEnabled];
}


// =========================================================================
// 10. KÍCH HOẠT TOÀN BỘ HOOKS (CHẠY ỔN ĐỊNH 100%, ĐẦY ĐỦ TÁC DỤNG)
// =========================================================================
static void installAllZaloModHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSLog(@"[DucLamXNgBao] Đang cài đặt Hook chuẩn xác cho Zalo Mod VIP...");

        // 1. Hook Font Chữ vào ô nhập liệu (UITextView & UITextField)
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

        // Hook ChatEntity photoQuality & isExpiredMessage
        Class chatEntityCls = objc_getClass("ChatEntity");
        if (chatEntityCls) {
            Method mPhotoQ = class_getInstanceMethod(chatEntityCls, sel_registerName("photoQuality"));
            if (mPhotoQ) {
                IMP orig = method_getImplementation(mPhotoQ);
                class_addMethod(chatEntityCls, sel_registerName("zaloMod_orig_photoQuality"), orig, method_getTypeEncoding(mPhotoQ));
                method_setImplementation(mPhotoQ, (IMP)hook_ChatEntity_photoQuality);
            }

            Method mExp = class_getInstanceMethod(chatEntityCls, sel_registerName("isExpiredMessage"));
            if (mExp) {
                IMP orig = method_getImplementation(mExp);
                class_addMethod(chatEntityCls, sel_registerName("zaloMod_orig_isExpiredMessage"), orig, method_getTypeEncoding(mExp));
                method_setImplementation(mExp, (IMP)hook_ChatEntity_isExpiredMessage);
            }
        }

        // Hook BaseChatTVC: Đổi font, TTL và màu sắc chat bubble 100% không bao giờ mất!
        Class baseChatTVCCls = objc_getClass("BaseChatTVC");
        if (baseChatTVCCls) {
            Method mGetText = class_getInstanceMethod(baseChatTVCCls, sel_registerName("getTextToSend"));
            if (mGetText) {
                IMP orig = method_getImplementation(mGetText);
                class_addMethod(baseChatTVCCls, sel_registerName("zaloMod_orig_getTextToSend"), orig, method_getTypeEncoding(mGetText));
                method_setImplementation(mGetText, (IMP)hook_BaseChatTVC_getTextToSend);
                NSLog(@"[DucLamXNgBao] Hook BaseChatTVC getTextToSend thành công!");
            }

            Method mSendMsg = class_getInstanceMethod(baseChatTVCCls, sel_registerName("sendMessageWithText:needCreateBubble:"));
            if (mSendMsg) {
                IMP orig = method_getImplementation(mSendMsg);
                class_addMethod(baseChatTVCCls, sel_registerName("zaloMod_orig_sendMessageWithText:needCreateBubble:"), orig, method_getTypeEncoding(mSendMsg));
                method_setImplementation(mSendMsg, (IMP)hook_BaseChatTVC_sendMessageWithText_needCreateBubble);
                NSLog(@"[DucLamXNgBao] Hook BaseChatTVC sendMessageWithText:needCreateBubble: thành công!");
            }

            Method mCreateChat = class_getInstanceMethod(baseChatTVCCls, sel_registerName("createChatToSendWithMessage:mediaType:clientMsgId:"));
            if (mCreateChat) {
                IMP orig = method_getImplementation(mCreateChat);
                class_addMethod(baseChatTVCCls, sel_registerName("zaloMod_orig_createChatToSendWithMessage:mediaType:clientMsgId:"), orig, method_getTypeEncoding(mCreateChat));
                method_setImplementation(mCreateChat, (IMP)hook_BaseChatTVC_createChatToSendWithMessage);
                NSLog(@"[DucLamXNgBao] Hook BaseChatTVC createChatToSendWithMessage:mediaType:clientMsgId: thành công!");
            }

            Method mWillDisp = class_getInstanceMethod(baseChatTVCCls, sel_registerName("willDisplayCell:forItemAtIndexPath:"));
            if (mWillDisp) {
                IMP orig = method_getImplementation(mWillDisp);
                class_addMethod(baseChatTVCCls, sel_registerName("zaloMod_orig_willDisplayCell:forItemAtIndexPath:"), orig, method_getTypeEncoding(mWillDisp));
                method_setImplementation(mWillDisp, (IMP)hook_BaseChatTVC_willDisplayCell_forItemAtIndexPath);
                NSLog(@"[DucLamXNgBao] Hook BaseChatTVC willDisplayCell:forItemAtIndexPath: thành công!");
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

        // 4b. Hook All ZStyles - EXHAUSTIVE DEEP HOOKS cho TẤT CẢ các lớp ZStyle trong Zalo
        // -----------------------------------------------------------------------
        // ProfileLegacyUtils - Bridge Obj-C/Swift cho ZStyle check
        // -----------------------------------------------------------------------
        Class legacyUtilsCls = objc_getClass("ProfileLegacyUtils");
        if (legacyUtilsCls) {
            const char *luSelectors[] = {
                "isZStyleSubscribed:", "objc_isSubscribeZStyle:", "objc_isZStyleSubscribed:",
                "isEnabledZStyleAvatarFrame", "objc_isEnabledZStyleAvatarFrame",
                "objc_isEnabledFrameTypeForProfileUIType:", "isZStyleUser"
            };
            for (int i = 0; i < 7; i++) {
                Method m = class_getClassMethod(legacyUtilsCls, sel_registerName(luSelectors[i]));
                if (m) method_setImplementation(m, (IMP)hook_zstyleAlwaysTrue);
                Method mi = class_getInstanceMethod(legacyUtilsCls, sel_registerName(luSelectors[i]));
                if (mi) method_setImplementation(mi, (IMP)hook_zstyleAlwaysTrue);
            }
            Method mPkg = class_getClassMethod(legacyUtilsCls, sel_registerName("getZStylePackageId:"));
            if (mPkg) method_setImplementation(mPkg, (IMP)hook_getZStylePackageId);
            Method mPkg2 = class_getClassMethod(legacyUtilsCls, sel_registerName("objc_getZStylePackageId:"));
            if (mPkg2) method_setImplementation(mPkg2, (IMP)hook_getZStylePackageId);
            NSLog(@"[DucLamXNgBao] Hook ProfileLegacyUtils ZStyle thành công!");
        }

        // -----------------------------------------------------------------------
        // SocialFeatureSetting - Feature flags ZStyle cho Social features
        // -----------------------------------------------------------------------
        Class socialSettingCls = objc_getClass("SocialFeatureSetting");
        if (socialSettingCls) {
            const char *sfSelectors[] = {
                "isEnabledZStyleAvatarFrame", "isEnabledZStyleNameCard",
                "enableStoryMusic", "enableSwithProfileUI", "isEnabledFrameType:",
                "isEnabledZStyleUser", "isEnableZStyle", "enableZStyleProfileUI"
            };
            for (int i = 0; i < 8; i++) {
                Method m = class_getClassMethod(socialSettingCls, sel_registerName(sfSelectors[i]));
                if (m) method_setImplementation(m, (IMP)hook_zstyleAlwaysTrue);
                Method mi = class_getInstanceMethod(socialSettingCls, sel_registerName(sfSelectors[i]));
                if (mi) method_setImplementation(mi, (IMP)hook_zstyleAlwaysTrue);
            }
            NSLog(@"[DucLamXNgBao] Hook SocialFeatureSetting ZStyle thành công!");
        }

        // -----------------------------------------------------------------------
        // ProfileEntity & BuddyEntity - User entity ZStyle flags
        // -----------------------------------------------------------------------
        const char *entityClsNames[] = {"ProfileEntity", "BuddyEntity", "UserEntity", "UserInfo"};
        for (int ci = 0; ci < 4; ci++) {
            Class eCls = objc_getClass(entityClsNames[ci]);
            if (!eCls) continue;
            const char *eSelectors[] = {
                "isBusinessAccount", "isZStyle", "isZStyleUser", "isPaidZStyle",
                "isZStyleConfigLoaded", "isZStyleProfileUI", "isZCloudUser",
                "isPaidZCloudUser", "isPaidZCloudUserActive"
            };
            for (int si = 0; si < 9; si++) {
                Method m = class_getInstanceMethod(eCls, sel_registerName(eSelectors[si]));
                if (m) method_setImplementation(m, (IMP)hook_zstyleAlwaysTrue);
            }
            Method mPkg = class_getInstanceMethod(eCls, sel_registerName("zstylePackageId"));
            if (mPkg) method_setImplementation(mPkg, (IMP)hook_zstylePackageIdVIP);
            Method mPkg2 = class_getInstanceMethod(eCls, sel_registerName("_zstylePackageId"));
            if (mPkg2) method_setImplementation(mPkg2, (IMP)hook_zstylePackageIdVIP);
        }

        // -----------------------------------------------------------------------
        // ProfileFlowManager & FriendFlowManager - Business account check
        // -----------------------------------------------------------------------
        Class profFlowCls_new = objc_getClass("ProfileFlowManager");
        if (profFlowCls_new) {
            Method m = class_getInstanceMethod(profFlowCls, sel_registerName("checkUserIsBusinessAccount:"));
            if (m) method_setImplementation(m, (IMP)hook_checkUserIsBusinessAccount);
        }
        Class friendFlowCls_new = objc_getClass("FriendFlowManager");
        if (friendFlowCls_new) {
            Method m = class_getInstanceMethod(friendFlowCls, sel_registerName("checkUserIsBusinessAccount:"));
            if (m) method_setImplementation(m, (IMP)hook_checkUserIsBusinessAccount);
        }

        // -----------------------------------------------------------------------
        // BALabelInfo - ZBusiness Pro badge label
        // -----------------------------------------------------------------------
        Class baInfoCls_new = objc_getClass("_TtC6CORBiz11BALabelInfo") ?: objc_getClass("CORBiz11BALabelInfo");
        if (baInfoCls_new) {
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

        // -----------------------------------------------------------------------
        // ZCFReactionAuthenConfig - Mở khóa Reaction effects không cần mua
        // -----------------------------------------------------------------------
        Class reactionAuthCls = objc_getClass("_TtC15CommFeatureBase23ZCFReactionAuthenConfig") ?: objc_getClass("ZCFReactionAuthenConfig");
        if (reactionAuthCls) {
            Method mPromote = class_getInstanceMethod(reactionAuthCls, sel_registerName("promotionAllowed"));
            if (mPromote) method_setImplementation(mPromote, (IMP)hook_zstyleAlwaysTrue);
            Method mSub = class_getInstanceMethod(reactionAuthCls, sel_registerName("hasSubscription"));
            if (mSub) method_setImplementation(mSub, (IMP)hook_zstyleAlwaysTrue);
            Method mValid = class_getInstanceMethod(reactionAuthCls, sel_registerName("isValid"));
            if (mValid) method_setImplementation(mValid, (IMP)hook_zstyleAlwaysTrue);
            Method mFree = class_getInstanceMethod(reactionAuthCls, sel_registerName("isFree"));
            if (mFree) method_setImplementation(mFree, (IMP)hook_zstyleAlwaysTrue);
        }
        // ZCFReactionPackageValidator
        Class reactionPkgValidatorCls = objc_getClass("ZCFReactionPackageValidator");
        if (reactionPkgValidatorCls) {
            Method mValid = class_getInstanceMethod(reactionPkgValidatorCls, sel_registerName("isValid"));
            if (mValid) method_setImplementation(mValid, (IMP)hook_zstyleAlwaysTrue);
            Method mOwned = class_getInstanceMethod(reactionPkgValidatorCls, sel_registerName("isOwned"));
            if (mOwned) method_setImplementation(mOwned, (IMP)hook_zstyleAlwaysTrue);
            Method mFree = class_getInstanceMethod(reactionPkgValidatorCls, sel_registerName("isFree"));
            if (mFree) method_setImplementation(mFree, (IMP)hook_zstyleAlwaysTrue);
        }

        // -----------------------------------------------------------------------
        // ZStyle Sticker Pack
        // -----------------------------------------------------------------------
        Class stickerPackCls = objc_getClass("_TtC19CommFeatureBusiness27StickersBottomSheetPackInfo") ?: objc_getClass("StickersBottomSheetPackInfo");
        if (stickerPackCls) {
            const char *spSelectors[] = {"isPaidZStyle", "isOwned", "isPurchased", "isZStyleUser", "isfree"};
            for (int i = 0; i < 5; i++) {
                Method m = class_getInstanceMethod(stickerPackCls, sel_registerName(spSelectors[i]));
                if (m) method_setImplementation(m, (IMP)hook_zstyleAlwaysTrue);
            }
            Method mPrice = class_getInstanceMethod(stickerPackCls, sel_registerName("price"));
            if (mPrice) method_setImplementation(mPrice, (IMP)hook_zeroPrice);
            Method mZPrice = class_getInstanceMethod(stickerPackCls, sel_registerName("zStylePrice"));
            if (mZPrice) method_setImplementation(mZPrice, (IMP)hook_zeroPrice);
            Method mOrigPrice = class_getInstanceMethod(stickerPackCls, sel_registerName("originalPrice"));
            if (mOrigPrice) method_setImplementation(mOrigPrice, (IMP)hook_zeroPrice);
        }

        // -----------------------------------------------------------------------
        // ZMp3Manager - Profile Music, RBT, Zing MP3
        // -----------------------------------------------------------------------
        Class zmp3Cls = objc_getClass("ZMp3Manager");
        if (zmp3Cls) {
            const char *mp3Selectors[] = {
                "enableProfileMusic", "enableProfileMusicLocal", "enableProfileMusicRBT",
                "enableShareProfileMusic", "autoPlayMyMusic", "autoPlayFriendMusic",
                "newFlagEnableProfileMusic", "isEnableMusic", "isEnableMusicLocal",
                "newFlagIsEnableMusic", "enableMiniPlayer", "enablePillPlayer",
                "isZStyleUser", "isPaidZStyle"
            };
            for (int i = 0; i < 14; i++) {
                Method m = class_getInstanceMethod(zmp3Cls, sel_registerName(mp3Selectors[i]));
                if (m) method_setImplementation(m, (IMP)hook_zstyleAlwaysTrue);
            }
            NSLog(@"[DucLamXNgBao] Hook ZMp3Manager Profile Music ZStyle thành công!");
        }

        // -----------------------------------------------------------------------
        // ZStylePackageInfo (Swift) - Package info check
        // -----------------------------------------------------------------------
        Class zstylePkgInfoCls = objc_getClass("_TtC12ZStyleConfig17ZStylePackageInfo");
        if (zstylePkgInfoCls) {
            const char *pkgSels[] = {"isValid", "isPaidPackage", "isOwned", "isZStyleUser"};
            for (int i = 0; i < 4; i++) {
                Method m = class_getInstanceMethod(zstylePkgInfoCls, sel_registerName(pkgSels[i]));
                if (m) method_setImplementation(m, (IMP)hook_zstyleAlwaysTrue);
            }
            Method mPkg = class_getInstanceMethod(zstylePkgInfoCls, sel_registerName("packageId"));
            if (mPkg) method_setImplementation(mPkg, (IMP)hook_zstylePackageIdVIP);
            NSLog(@"[DucLamXNgBao] Hook ZStylePackageInfo thành công!");
        }

        // -----------------------------------------------------------------------
        // ZStyleProfileInfo (Swift ProfileUI) - Profile ZStyle info
        // -----------------------------------------------------------------------
        Class zstyleProfInfoCls = objc_getClass("_TtC9ProfileUI17ZStyleProfileInfo");
        if (zstyleProfInfoCls) {
            Method mPkg = class_getInstanceMethod(zstyleProfInfoCls, sel_registerName("packageId"));
            if (mPkg) method_setImplementation(mPkg, (IMP)hook_zstylePackageIdVIP);
            Method mUser = class_getInstanceMethod(zstyleProfInfoCls, sel_registerName("isZStyleUser"));
            if (mUser) method_setImplementation(mUser, (IMP)hook_zstyleAlwaysTrue);
            Method mPaid = class_getInstanceMethod(zstyleProfInfoCls, sel_registerName("isPaidZStyle"));
            if (mPaid) method_setImplementation(mPaid, (IMP)hook_zstyleAlwaysTrue);
        }

        // -----------------------------------------------------------------------
        // ZStyleBenefitConfig - Benefit flags cho ZStyle features
        // -----------------------------------------------------------------------
        Class zstyleBenefitCls = objc_getClass("_TtC12ZStyleConfig19ZStyleBenefitConfig");
        if (zstyleBenefitCls) {
            const char *bSels[] = {"isEnabled", "isAvailable", "canUse", "isOwned", "isPaid"};
            for (int i = 0; i < 5; i++) {
                Method m = class_getInstanceMethod(zstyleBenefitCls, sel_registerName(bSels[i]));
                if (m) method_setImplementation(m, (IMP)hook_zstyleAlwaysTrue);
            }
        }

        // -----------------------------------------------------------------------
        // ZStyleAvatarFrameFeature & ZStyleAvatarFrameSetting - Khung avatar
        // -----------------------------------------------------------------------
        Class avatarFrameFeature = objc_getClass("ZStyleAvatarFrameFeature");
        if (avatarFrameFeature) {
            const char *affSels[] = {"isEnabled", "isOwned", "isPaid", "canUse"};
            for (int i = 0; i < 4; i++) {
                Method m = class_getInstanceMethod(avatarFrameFeature, sel_registerName(affSels[i]));
                if (m) method_setImplementation(m, (IMP)hook_zstyleAlwaysTrue);
            }
        }

        // -----------------------------------------------------------------------
        // ProfileMusicDisplayDecision (Swift) - Quyết định hiện nhạc profile
        // -----------------------------------------------------------------------
        Class musicDecisionCls = objc_getClass("_TtC12ProfileMusic27ProfileMusicDisplayDecision");
        if (musicDecisionCls) {
            const char *mdSels[] = {"isViewerZStyle", "isZStyleProfileUI", "canShowMusic", "canShowMiniPlayer", "canShowPillPlayer"};
            for (int i = 0; i < 5; i++) {
                Method m = class_getInstanceMethod(musicDecisionCls, sel_registerName(mdSels[i]));
                if (m) method_setImplementation(m, (IMP)hook_zstyleAlwaysTrue);
            }
        }

        // -----------------------------------------------------------------------
        // ZCFReactionPaywallRouter - Chặn tất cả popup paywall upgrade
        // -----------------------------------------------------------------------
        Class paywallRouterCls = objc_getClass("ZCFReactionPaywallRouter");
        if (paywallRouterCls) {
            const char *pwSels[] = {
                "openPaywallWithEntrypoint:conversationType:",
                "_showDialogNotAllowedOpenPaywallIAPNotEnable",
                "showPaywall", "presentPaywall", "pushPaywall",
                "openPaywall", "showUpgradeDialog", "showPurchaseDialog"
            };
            for (int i = 0; i < 8; i++) {
                Method m = class_getInstanceMethod(paywallRouterCls, sel_registerName(pwSels[i]));
                if (m) method_setImplementation(m, (IMP)hook_voidDoNothing);
            }
        }
        // Block all paywall classes
        const char *paywallClsNames[] = {"ZCFPaywallRouter", "ZStylePaywallRouter", "PaywallManager", "UpgradeManager"};
        for (int ci = 0; ci < 4; ci++) {
            Class pwCls = objc_getClass(paywallClsNames[ci]);
            if (!pwCls) continue;
            const char *pwSels[] = {"show", "present", "push", "open", "showPaywall", "openPaywall"};
            for (int si = 0; si < 6; si++) {
                Method m = class_getInstanceMethod(pwCls, sel_registerName(pwSels[si]));
                if (m) method_setImplementation(m, (IMP)hook_voidDoNothing);
            }
        }

        // -----------------------------------------------------------------------
        // ZCF QualityPickerConfig - Original Photo/Video
        // -----------------------------------------------------------------------
        Class qpConfigCls_new = objc_getClass("_TtC15CommFeatureBase22ZCFQualityPickerConfig") ?: objc_getClass("ZCFQualityPickerConfig");
        if (qpConfigCls_new) {
            Method mSendOrig = class_getClassMethod(qpConfigCls, sel_registerName("enableSendOriginal"));
            if (mSendOrig) method_setImplementation(mSendOrig, (IMP)hook_alwaysTrue);
            Method mBadge = class_getClassMethod(qpConfigCls, sel_registerName("originalBadge"));
            if (mBadge) method_setImplementation(mBadge, (IMP)hook_originalBadge);
            Method mRem = class_getClassMethod(qpConfigCls, sel_registerName("allowRememberQuality"));
            if (mRem) method_setImplementation(mRem, (IMP)hook_allowRememberQuality);
            Method mQuality = class_getClassMethod(qpConfigCls, sel_registerName("originalCompressQuality"));
            if (mQuality) method_setImplementation(mQuality, (IMP)hook_originalCompressQuality);
        }

        // ZSharedData - Ảnh gốc HD
        Class zSharedCls_new = objc_getClass("ZSharedData");
        if (zSharedCls_new) {
            Method mSetting = class_getInstanceMethod(zSharedCls, sel_registerName("settingOriginalPhotoQuality"));
            if (mSetting) method_setImplementation(mSetting, (IMP)hook_alwaysTrue);
            Method mLimitSize = class_getInstanceMethod(zSharedCls, sel_registerName("limitOriginalPhotoSize"));
            if (mLimitSize) method_setImplementation(mLimitSize, (IMP)hook_maxOriginalLimit);
            Method mLimitDim = class_getInstanceMethod(zSharedCls, sel_registerName("limitOriginalPhotoDimension"));
            if (mLimitDim) method_setImplementation(mLimitDim, (IMP)hook_maxOriginalLimit);
            Method mRemHD = class_getInstanceMethod(zSharedCls, sel_registerName("enableRememberHD"));
            if (mRemHD) method_setImplementation(mRemHD, (IMP)hook_alwaysTrue);
        }

        // -----------------------------------------------------------------------
        // Hook AdBlock In-App (Chặn toàn bộ Quảng Cáo)
        // -----------------------------------------------------------------------
        const char *adClsNames[] = {"AdManager", "ZAdManager", "ZCHOutStreamAdsConfig", "ZAAdManager", "AdConfig", "ZAAdConfig"};
        for (int ci = 0; ci < 6; ci++) {
            Class adCls = objc_getClass(adClsNames[ci]);
            if (!adCls) continue;
            const char *adSels[] = {"enableAds", "shouldShowAd", "canShowAd", "isAdEnabled", "shouldShowBanner", "shouldShowFullscreen"};
            for (int si = 0; si < 6; si++) {
                Method m = class_getInstanceMethod(adCls, sel_registerName(adSels[si]));
                if (m) method_setImplementation(m, (IMP)hook_adBlockAlwaysFalse);
                Method mc = class_getClassMethod(adCls, sel_registerName(adSels[si]));
                if (mc) method_setImplementation(mc, (IMP)hook_adBlockAlwaysFalse);
            }
        }

        // -----------------------------------------------------------------------
        // Hook Unlimited Media
        // -----------------------------------------------------------------------
        if (chatDataMgrCls) {
            Method mMaxDur = class_getInstanceMethod(chatDataMgrCls, sel_registerName("getMaxSendingDuration:isHighQuality:"));
            if (mMaxDur) method_setImplementation(mMaxDur, (IMP)hook_unlimitedMediaDuration);
            Method mMaxSz = class_getInstanceMethod(chatDataMgrCls, sel_registerName("getMaxFileSizeWithPickerQuality:"));
            if (mMaxSz) method_setImplementation(mMaxSz, (IMP)hook_unlimitedMediaFileSize);
            Method mTrim = class_getInstanceMethod(chatDataMgrCls, sel_registerName("autoTrimVideoIfNeed:isHighQuality:"));
            if (mTrim) method_setImplementation(mTrim, (IMP)hook_adBlockAlwaysFalse);
        }

        NSLog(@"[DucLamXNgBao] HOÀN TẤT KÍCH HOẠT HOOKS - ĐẦY ĐỦ TÁC DỤNG 100%%!");
    });
}

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
