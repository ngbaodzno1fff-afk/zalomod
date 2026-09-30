//
//  ZaloFloatingButton.h
//  ZaloMod - Cục Menu Tròn Floating Button
//

#import <UIKit/UIKit.h>

@protocol ZaloFloatingButtonDelegate <NSObject>
- (void)floatingButtonDidTap:(id)sender;
@end

@interface ZaloFloatingButton : UIView

@property (nonatomic, weak) id<ZaloFloatingButtonDelegate> delegate;
@property (nonatomic, strong) UIButton *circleButton;
@property (nonatomic, strong) UILabel *badgeLabel;
@property (nonatomic, assign) NSInteger unreadRevokedCount;
@property (nonatomic, assign) BOOL isMenuOpen;

+ (instancetype)sharedInstance;
- (void)show;
- (void)hide;
- (void)updateBadge:(NSInteger)count;
- (void)incrementBadge;
- (void)setButtonOpacity:(CGFloat)opacity;
- (void)setButtonSize:(CGFloat)size;

@end
