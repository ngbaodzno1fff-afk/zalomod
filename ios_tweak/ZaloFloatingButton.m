//
//  ZaloFloatingButton.m
//  ZaloMod - Cục Menu Tròn Floating Button Implementation
//

#import "ZaloFloatingButton.h"

@interface ZaloFloatingButton () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) CAShapeLayer *glowLayer;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, assign) CGPoint startTouchPoint;
@property (nonatomic, assign) BOOL isDragging;
@end

@implementation ZaloFloatingButton

static ZaloFloatingButton *_sharedInstance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CGFloat defaultSize = 56.0;
        CGRect frame = CGRectMake(16, 120, defaultSize, defaultSize);
        _sharedInstance = [[ZaloFloatingButton alloc] initWithFrame:frame];
    });
    return _sharedInstance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self setupGestures];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [UIColor clearColor];
    self.layer.masksToBounds = NO;
    
    // Đổ bóng phát sáng (Neon Glow)
    self.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.55 blue:1.0 alpha:0.8].CGColor;
    self.layer.shadowRadius = 8.0;
    self.layer.shadowOpacity = 0.85;
    self.layer.shadowOffset = CGSizeMake(0, 3);

    // Nút tròn chính ("Cục menu tròn")
    self.circleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.circleButton.frame = self.bounds;
    self.circleButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.circleButton.layer.cornerRadius = self.bounds.size.width / 2.0;
    self.circleButton.clipsToBounds = YES;
    
    // Viền phát sáng ánh kim
    self.circleButton.layer.borderColor = [UIColor colorWithRed:0.25 green:0.75 blue:1.0 alpha:0.9].CGColor;
    self.circleButton.layer.borderWidth = 2.0;
    
    // Gradient nền hiện đại chuẩn Zalo VIP (Xanh dương đậm sang Cyber Cyan)
    self.gradientLayer = [CAGradientLayer layer];
    self.gradientLayer.frame = self.circleButton.bounds;
    self.gradientLayer.colors = @[
        (id)[UIColor colorWithRed:0.02 green:0.45 blue:0.95 alpha:0.95].CGColor,
        (id)[UIColor colorWithRed:0.00 green:0.25 blue:0.65 alpha:0.95].CGColor
    ];
    self.gradientLayer.startPoint = CGPointMake(0, 0);
    self.gradientLayer.endPoint = CGPointMake(1, 1);
    self.gradientLayer.cornerRadius = self.bounds.size.width / 2.0;
    [self.circleButton.layer insertSublayer:self.gradientLayer atIndex:0];

    // Chữ 'Z' VIP nổi bật giữa cục menu tròn
    [self.circleButton setTitle:@"Z" forState:UIControlStateNormal];
    [self.circleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.circleButton.titleLabel.font = [UIFont boldSystemFontOfSize:24.0];
    self.circleButton.titleLabel.layer.shadowColor = [UIColor colorWithRed:0.3 green:0.8 blue:1.0 alpha:1.0].CGColor;
    self.circleButton.titleLabel.layer.shadowRadius = 4.0;
    self.circleButton.titleLabel.layer.shadowOpacity = 0.9;
    self.circleButton.titleLabel.layer.shadowOffset = CGSizeZero;

    [self.circleButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.circleButton];

    // Huy hiệu đếm số tin nhắn đã chống thu hồi (Badge count)
    CGFloat badgeSize = 20.0;
    self.badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width - badgeSize + 2, -2, badgeSize, badgeSize)];
    self.badgeLabel.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.25 alpha:1.0];
    self.badgeLabel.textColor = [UIColor whiteColor];
    self.badgeLabel.font = [UIFont boldSystemFontOfSize:11.0];
    self.badgeLabel.textAlignment = NSTextAlignmentCenter;
    self.badgeLabel.layer.cornerRadius = badgeSize / 2.0;
    self.badgeLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    self.badgeLabel.layer.borderWidth = 1.5;
    self.badgeLabel.clipsToBounds = YES;
    self.badgeLabel.hidden = YES;
    [self addSubview:self.badgeLabel];
    
    // Hiệu ứng thở / Nhấp nháy nhẹ (Pulsing Glow Animation)
    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    pulse.duration = 1.6;
    pulse.fromValue = @(0.4);
    pulse.toValue = @(0.95);
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [self.layer addAnimation:pulse forKey:@"pulseGlow"];
}

- (void)setupGestures {
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.panGesture.delegate = self;
    self.panGesture.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:self.panGesture];
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIView *superView = self.superview;
    if (!superView) return;

    CGPoint translation = [pan translationInView:superView];

    if (pan.state == UIGestureRecognizerStateBegan) {
        self.isDragging = YES;
        self.startTouchPoint = self.center;
        [UIView animateWithDuration:0.15 animations:^{
            self.transform = CGAffineTransformMakeScale(1.12, 1.12);
            self.alpha = 1.0;
        }];
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(self.startTouchPoint.x + translation.x, self.startTouchPoint.y + translation.y);
        
        // Giới hạn trong màn hình
        CGFloat halfW = self.bounds.size.width / 2.0;
        CGFloat halfH = self.bounds.size.height / 2.0;
        CGFloat screenW = superView.bounds.size.width;
        CGFloat screenH = superView.bounds.size.height;
        
        newCenter.x = MAX(halfW, MIN(screenW - halfW, newCenter.x));
        newCenter.y = MAX(halfH + 40, MIN(screenH - halfH - 40, newCenter.y));
        self.center = newCenter;
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        self.isDragging = NO;
        [UIView animateWithDuration:0.15 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
        [self snapToEdgeAnimated];
    }
}

- (void)snapToEdgeAnimated {
    UIView *superView = self.superview;
    if (!superView) return;

    CGFloat screenW = superView.bounds.size.width;
    CGFloat halfW = self.bounds.size.width / 2.0;
    CGFloat padding = 12.0;

    CGFloat targetX = (self.center.x < screenW / 2.0) ? (halfW + padding) : (screenW - halfW - padding);
    CGPoint targetCenter = CGPointMake(targetX, self.center.y);

    [UIView animateWithDuration:0.42
                          delay:0
         usingSpringWithDamping:0.75
          initialSpringVelocity:0.6
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.center = targetCenter;
    } completion:nil];
}

- (void)buttonTapped:(UIButton *)sender {
    if (self.isDragging) return;

    // Phản hồi xúc giác Haptic Feedback khi bấm cục menu tròn
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [generator impactOccurred];
    }

    // Hiệu ứng co dãn (Bounce effect) khi click
    [UIView animateWithDuration:0.1 animations:^{
        self.transform = CGAffineTransformMakeScale(0.88, 0.88);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
    }];

    if ([self.delegate respondsToSelector:@selector(floatingButtonDidTap:)]) {
        [self.delegate floatingButtonDidTap:self];
    }
}

- (void)show {
    self.hidden = NO;
    self.alpha = 0.0;
    self.transform = CGAffineTransformMakeScale(0.5, 0.5);
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
        self.transform = CGAffineTransformIdentity;
    }];
}

- (void)hide {
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0.0;
        self.transform = CGAffineTransformMakeScale(0.5, 0.5);
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

- (void)updateBadge:(NSInteger)count {
    self.unreadRevokedCount = count;
    if (count > 0) {
        self.badgeLabel.hidden = NO;
        self.badgeLabel.text = count > 99 ? @"99+" : [NSString stringWithFormat:@"%ld", (long)count];
        
        // Hiệu ứng nảy huy hiệu
        self.badgeLabel.transform = CGAffineTransformMakeScale(1.4, 1.4);
        [UIView animateWithDuration:0.25 animations:^{
            self.badgeLabel.transform = CGAffineTransformIdentity;
        }];
    } else {
        self.badgeLabel.hidden = YES;
    }
}

- (void)incrementBadge {
    [self updateBadge:self.unreadRevokedCount + 1];
}

- (void)setButtonOpacity:(CGFloat)opacity {
    self.alpha = MAX(0.2, MIN(1.0, opacity));
}

- (void)setButtonSize:(CGFloat)size {
    CGPoint oldCenter = self.center;
    self.bounds = CGRectMake(0, 0, size, size);
    self.circleButton.frame = self.bounds;
    self.circleButton.layer.cornerRadius = size / 2.0;
    self.gradientLayer.frame = self.circleButton.bounds;
    self.gradientLayer.cornerRadius = size / 2.0;
    self.center = oldCenter;
}

@end
