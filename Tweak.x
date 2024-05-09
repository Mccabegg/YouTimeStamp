#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>

#import "../YTVideoOverlay/Header.h"
#import "../YTVideoOverlay/Init.x"
#import "../YouTubeHeader/YTColor.h"
#import "../YouTubeHeader/YTMainAppVideoPlayerOverlayViewController.h"
#import "../YouTubeHeader/YTMainAppControlsOverlayView.h"
#import "../YouTubeHeader/MLFormat.h"
#import "../YouTubeHeader/YTIFormatStream.h"
#import "../YouTubeHeader/YTIShareVideoEndpoint.h"

#define TweakKey @"YouTimeStamp"

@interface YTMainAppControlsOverlayView (YouTimeStamp)
@property (retain, nonatomic) YTQTMButton *timestampButton;
@property (nonatomic, strong) YTLabel *currentTimeLabel; // YTInlinePlayerBarContainerView
@property (nonatomic, copy) NSString *videoShareURL; // YTIShareVideoEndpoint
- (AVPlayer *)getPlayer;
- (void)didPressYouTimeStamp:(id)arg;
- (void)copyURLToClipboard:(NSString *)modifiedURL;
- (void)copyModifiedURLToClipboard:(NSString *)originalURL withTimeFromAVPlayer:(AVPlayer *)player;
- (NSString *)getCurrentTimeFromAVPlayer:(AVPlayer *)player;
@end

@interface YTInlinePlayerBarContainerView (YouTimeStamp)
@property (retain, nonatomic) YTQTMButton *timestampButton;
@property (nonatomic, strong) YTLabel *currentTimeLabel; // YTInlinePlayerBarContainerView
@property (nonatomic, copy) NSString *videoShareURL; // YTIShareVideoEndpoint
- (AVPlayer *)getPlayer;
- (void)didPressYouTimeStamp:(id)arg;
- (void)copyURLToClipboard:(NSString *)modifiedURL;
- (void)copyModifiedURLToClipboard:(NSString *)originalURL withTimeFromAVPlayer:(AVPlayer *)player;
- (NSString *)getCurrentTimeFromAVPlayer:(AVPlayer *)player;
@end

// For displaying snackbars - @theRealfoxster
@interface YTHUDMessage : NSObject
+ (id)messageWithText:(id)text;
- (void)setAction:(id)action;
@end

@interface GOOHUDMessageAction : NSObject
- (void)setTitle:(NSString *)title;
- (void)setHandler:(void (^)(id))handler;
@end

@interface GOOHUDManagerInternal : NSObject
- (void)showMessageMainThread:(id)message;
+ (id)sharedInstance;
@end
//

NSBundle *YouTimeStampBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:TweakKey ofType:@"bundle"];
        if (tweakBundlePath)
            bundle = [NSBundle bundleWithPath:tweakBundlePath];
        else
            bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:ROOT_PATH_NS(@"/Library/Application Support/%@.bundle"), TweakKey]];
    });
    return bundle;
}

static UIImage *timestampImage(NSString *qualityLabel) {
    return [%c(QTMIcon) tintImage:[UIImage imageNamed:[NSString stringWithFormat:@"Timestamp@%@", qualityLabel] inBundle: YouTimeStampBundle() compatibleWithTraitCollection:nil] color:[%c(YTColor) white1]];
}

%group Top

%hook YTMainAppControlsOverlayView

%property (retain, nonatomic) YTQTMButton *timestampButton;

- (id)initWithDelegate:(id)delegate {
    self = %orig;
    self.timestampButton = [self createButton:TweakKey accessibilityLabel:@"Copy Timestamp" selector:@selector(didPressYouTimeStamp:)];
    return self;
}

- (id)initWithDelegate:(id)delegate autoplaySwitchEnabled:(BOOL)autoplaySwitchEnabled {
    self = %orig;
    self.timestampButton = [self createButton:TweakKey accessibilityLabel:@"Copy Timestamp" selector:@selector(didPressYouTimeStamp:)];
    return self;
}

- (YTQTMButton *)button:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? self.timestampButton : %orig;
}

- (UIImage *)buttonImage:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? timestampImage(@"3") : %orig;
}

%new(v@:@)
- (void)didPressYouTimeStamp:(id)arg {
    AVPlayer *player = [self getPlayer];
    if (player) {
        NSString *currentTime = [self getCurrentTimeFromAVPlayer:player];
        if (self.videoShareURL) {
            [self copyModifiedURLToClipboard:self.videoShareURL withTimeFromAVPlayer:player];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.timestampButton setImage:timestampImage(@"3") forState:0];
                [[%c(GOOHUDManagerInternal) sharedInstance] showMessageMainThread:[%c(YTHUDMessage) messageWithText:@"URL copied with timestamp"]];
            });
        } else {
            [self copyURLToClipboard:self.videoShareURL];
            [[%c(GOOHUDManagerInternal) sharedInstance] showMessageMainThread:[%c(YTHUDMessage) messageWithText:@"No video URL available"]];
        }
    } else {
        NSLog(@"AVPlayer instance is not available");
    }
}

- (NSString *)getCurrentTimeFromAVPlayer:(AVPlayer *)player {
    CMTime currentTime = player.currentTime;
    NSTimeInterval timeInterval = CMTimeGetSeconds(currentTime);
    NSInteger minutes = timeInterval / 60;
    NSInteger seconds = (NSInteger)timeInterval % 60;
    return [NSString stringWithFormat:@"%02ldm%02lds", (long)minutes, (long)seconds];
}

- (void)copyModifiedURLToClipboard:(NSString *)originalURL withTimeFromAVPlayer:(AVPlayer *)player {
    NSString *currentTime = [self getCurrentTimeFromAVPlayer:player];
    NSString *timestampString = [NSString stringWithFormat:@"&t=%@", currentTime];
    NSString *modifiedURL = [originalURL stringByAppendingString:timestampString];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:modifiedURL];
    [[%c(GOOHUDManagerInternal) sharedInstance] showMessageMainThread:[%c(YTHUDMessage) messageWithText:@"Successfully copied URL with Timestamp"]];
}

%end

%end

%group Bottom

%hook YTInlinePlayerBarContainerView

%property (retain, nonatomic) YTQTMButton *timestampButton;

- (id)init {
    self = %orig;
    self.timestampButton = [self createButton:TweakKey accessibilityLabel:@"Copy Timestamp" selector:@selector(didPressYouTimeStamp:)];
    return self;
}

- (YTQTMButton *)button:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? self.timestampButton : %orig;
}

- (UIImage *)buttonImage:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? timestampImage(@"3") : %orig;
}

%new(v@:@)
- (void)didPressYouTimeStamp:(id)arg {
    AVPlayer *player = [self getPlayer];
    if (player) {
        NSString *currentTime = [self getCurrentTimeFromAVPlayer:player];
        if (self.videoShareURL) {
            [self copyModifiedURLToClipboard:self.videoShareURL withTimeFromAVPlayer:player];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.timestampButton setImage:timestampImage(@"3") forState:0];
                [[%c(GOOHUDManagerInternal) sharedInstance] showMessageMainThread:[%c(YTHUDMessage) messageWithText:@"URL copied with timestamp"]];
            });
        } else {
            [self copyURLToClipboard:self.videoShareURL];
            [[%c(GOOHUDManagerInternal) sharedInstance] showMessageMainThread:[%c(YTHUDMessage) messageWithText:@"No video URL available"]];
        }
    } else {
        NSLog(@"AVPlayer instance is not available");
    }
}

- (NSString *)getCurrentTimeFromAVPlayer:(AVPlayer *)player {
    CMTime currentTime = player.currentTime;
    NSTimeInterval timeInterval = CMTimeGetSeconds(currentTime);
    CMTime duration = player.currentItem.duration;
    NSTimeInterval durationInSeconds = CMTimeGetSeconds(duration);
    NSInteger minutes = timeInterval / 60;
    NSInteger seconds = (NSInteger)timeInterval % 60;
    NSInteger totalMinutes = durationInSeconds / 60;
    NSInteger totalSeconds = (NSInteger)durationInSeconds % 60;    
    return [NSString stringWithFormat:@"Current Time: %02ldm%02lds, Total duration: %02ldm%02lds", (long)minutes, (long)seconds, (long)totalMinutes, (long)totalSeconds];
}

- (void)copyModifiedURLToClipboard:(NSString *)originalURL withTimeFromAVPlayer:(AVPlayer *)player {
    NSString *currentTime = [self getCurrentTimeFromAVPlayer:player];
    NSString *timestampString = [NSString stringWithFormat:@"&t=%@", currentTime];
    NSString *modifiedURL = [originalURL stringByAppendingString:timestampString];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:modifiedURL];
    [[%c(GOOHUDManagerInternal) sharedInstance] showMessageMainThread:[%c(YTHUDMessage) messageWithText:@"Successfully copied URL with Timestamp"]];
}

%end

%end

%ctor {
    initYTVideoOverlay(TweakKey);
    %init(Top);
    %init(Bottom);
}
