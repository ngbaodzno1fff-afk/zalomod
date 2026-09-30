//
//  ZaloModFontHelper.m
//  ZaloMod VIP - Bộ chuyển đổi 12 Font chữ nghệ thuật
//  Thương hiệu: DucLamXNgBao
//

#import "ZaloModFontHelper.h"

@implementation ZaloModFontHelper

+ (NSString *)convertText:(NSString *)text toStyle:(NSString *)style {
    if (!text || text.length == 0 || [style isEqualToString:@"Tắt"]) {
        return text;
    }

    if ([style isEqualToString:@"Random"]) {
        NSArray *allStyles = @[@"Pixel", @"Vintage", @"Florence", @"Notes", @"Elegant", @"Amatic", @"Terminal", @"Retro", @"Young", @"School"];
        NSMutableString *res = [NSMutableString string];
        for (NSUInteger i = 0; i < text.length; i++) {
            NSString *ch = [text substringWithRange:NSMakeRange(i, 1)];
            NSString *rndStyle = allStyles[arc4random_uniform((uint32_t)allStyles.count)];
            [res appendString:[self convertSingleChar:ch inStyle:rndStyle]];
        }
        return res;
    }

    NSMutableString *result = [NSMutableString string];
    for (NSUInteger i = 0; i < text.length; i++) {
        NSString *ch = [text substringWithRange:NSMakeRange(i, 1)];
        [result appendString:[self convertSingleChar:ch inStyle:style]];
    }
    return result;
}

+ (NSString *)convertSingleChar:(NSString *)ch inStyle:(NSString *)style {
    if (ch.length != 1) return ch;
    unichar c = [ch characterAtIndex:0];

    // Pixel (Fullwidth)
    if ([style isEqualToString:@"Pixel"]) {
        if (c >= 'A' && c <= 'Z') return [NSString stringWithFormat:@"%C", (unichar)(0xFF21 + (c - 'A'))];
        if (c >= 'a' && c <= 'z') return [NSString stringWithFormat:@"%C", (unichar)(0xFF41 + (c - 'a'))];
        if (c >= '0' && c <= '9') return [NSString stringWithFormat:@"%C", (unichar)(0xFF10 + (c - '0'))];
        if (c == ' ') return @"　";
        return ch;
    }

    // Young (Small Caps)
    if ([style isEqualToString:@"Young"]) {
        static NSDictionary *smallCaps = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            smallCaps = @{
                @"a":@"ᴀ", @"b":@"ʙ", @"c":@"ᴄ", @"d":@"ᴅ", @"e":@"ᴇ", @"f":@"ғ",
                @"g":@"ɢ", @"h":@"ʜ", @"i":@"ɪ", @"j":@"ᴊ", @"k":@"ᴋ", @"l":@"ʟ",
                @"m":@"ᴍ", @"n":@"ɴ", @"o":@"ᴏ", @"p":@"ᴘ", @"q":@"ǫ", @"r":@"ʀ",
                @"s":@"s", @"t":@"ᴛ", @"u":@"ᴜ", @"v":@"ᴠ", @"w":@"ᴡ", @"x":@"x",
                @"y":@"ʏ", @"z":@"ᴢ"
            };
        });
        NSString *low = [ch lowercaseString];
        return smallCaps[low] ?: ch;
    }

    // Terminal (Monospace)
    if ([style isEqualToString:@"Terminal"]) {
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D670 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D68A + (c - 'a')];
        if (c >= '0' && c <= '9') return [self surrogatePairForCodePoint:0x1D7F6 + (c - '0')];
        return ch;
    }

    // Retro (Bold Serif)
    if ([style isEqualToString:@"Retro"]) {
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D400 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D41A + (c - 'a')];
        if (c >= '0' && c <= '9') return [self surrogatePairForCodePoint:0x1D7CE + (c - '0')];
        return ch;
    }

    // School (Bold Sans-Serif)
    if ([style isEqualToString:@"School"]) {
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D5D4 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D5EE + (c - 'a')];
        if (c >= '0' && c <= '9') return [self surrogatePairForCodePoint:0x1D7EC + (c - '0')];
        return ch;
    }

    // Amatic (Sans-Serif Italic)
    if ([style isEqualToString:@"Amatic"]) {
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D608 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D622 + (c - 'a')];
        return ch;
    }

    // Notes (Double-Struck)
    if ([style isEqualToString:@"Notes"]) {
        if (c == 'C') return @"ℂ";
        if (c == 'H') return @"ℍ";
        if (c == 'N') return @"ℕ";
        if (c == 'P') return @"ℙ";
        if (c == 'Q') return @"ℚ";
        if (c == 'R') return @"ℝ";
        if (c == 'Z') return @"ℤ";
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D538 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D552 + (c - 'a')];
        if (c >= '0' && c <= '9') return [self surrogatePairForCodePoint:0x1D7D8 + (c - '0')];
        return ch;
    }

    // Florence (Bold Fraktur)
    if ([style isEqualToString:@"Florence"]) {
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D56C + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D586 + (c - 'a')];
        return ch;
    }

    // Vintage (Fraktur)
    if ([style isEqualToString:@"Vintage"]) {
        if (c == 'C') return @"ℭ";
        if (c == 'H') return @"ℌ";
        if (c == 'I') return @"ℑ";
        if (c == 'R') return @"ℜ";
        if (c == 'Z') return @"ℨ";
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D504 + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D51E + (c - 'a')];
        return ch;
    }

    // Elegant (Script / Cursive)
    if ([style isEqualToString:@"Elegant"]) {
        if (c == 'B') return @"ℬ";
        if (c == 'E') return @"ℰ";
        if (c == 'F') return @"ℱ";
        if (c == 'H') return @"ℋ";
        if (c == 'I') return @"ℐ";
        if (c == 'L') return @"ℒ";
        if (c == 'M') return @"ℳ";
        if (c == 'R') return @"ℛ";
        if (c == 'e') return @"ℯ";
        if (c == 'g') return @"ℊ";
        if (c == 'o') return @"ℴ";
        if (c >= 'A' && c <= 'Z') return [self surrogatePairForCodePoint:0x1D49C + (c - 'A')];
        if (c >= 'a' && c <= 'z') return [self surrogatePairForCodePoint:0x1D4B6 + (c - 'a')];
        return ch;
    }

    return ch;
}

+ (NSString *)surrogatePairForCodePoint:(uint32_t)codePoint {
    if (codePoint < 0x10000) {
        return [NSString stringWithFormat:@"%C", (unichar)codePoint];
    }
    uint32_t val = codePoint - 0x10000;
    unichar lead = (unichar)((val >> 10) + 0xD800);
    unichar trail = (unichar)((val & 0x3FF) + 0xDC00);
    unichar pair[2] = { lead, trail };
    return [NSString stringWithCharacters:pair length:2];
}

@end
