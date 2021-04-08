#import "RNGADBannerView.h"
#import "RNAdMobUtils.h"

#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#import <React/UIView+React.h>
#import <React/RCTLog.h>
#else
#import "RCTBridgeModule.h"
#import "UIView+React.h"
#import "RCTLog.h"
#endif

@implementation RNGADBannerView
{
    GADBannerView *_bannerView;
}

- (void)dealloc
{
    _bannerView.delegate = nil;
    _bannerView.adSizeDelegate = nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        super.backgroundColor = [UIColor clearColor];
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        UIViewController *rootViewController = [keyWindow rootViewController];
        _bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
        _bannerView.delegate = self;
        _bannerView.adSizeDelegate = self;
        _bannerView.rootViewController = rootViewController;
        [self addSubview:_bannerView];
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
- (void)insertReactSubview:(UIView *)subview atIndex:(NSInteger)atIndex
{
    RCTLogError(@"RNGADBannerView cannot have subviews");
}
#pragma clang diagnostic pop

- (void)loadBanner
{
    if(self.onSizeChange) {
        CGSize size = CGSizeFromGADAdSize(_bannerView.adSize);
        if(!CGSizeEqualToSize(size, self.bounds.size)) {
            self.onSizeChange(@{
                                @"width": @(size.width),
                                @"height": @(size.height)
                                });
        }
    }
    GADRequest *request = [GADRequest request];
    [_bannerView loadRequest:request];
}

- (void)setTestDevices:(NSArray *)testDevices
{
    _testDevices = RNAdMobProcessTestDevices(testDevices, kGADSimulatorID);
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    _bannerView.frame = self.bounds;
}

# pragma mark GADBannerViewDelegate

/// Tells the delegate an ad request loaded an ad.
- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView{
  if (self.onAdLoaded) {
      self.onAdLoaded(@{});
  }

}

- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error{
  if (self.onAdFailedToLoad) {
      self.onAdFailedToLoad(@{ @"error": @{ @"message": [error localizedDescription] } });
  }

}

///// Tells the delegate that a full screen view will be presented in response
///// to the user clicking on an ad.

- (void)bannerViewWillPresentScreen:(GADBannerView *)bannerView{
  if (self.onAdOpened) {
      self.onAdOpened(@{});
  }
}

///// Tells the delegate that the full screen view will be dismissed.
- (void)bannerViewWillDismissScreen:(GADBannerView *)bannerView{
  if (self.onAdClosed) {
      self.onAdClosed(@{});
  }
}


- (void)bannerViewDidRecordImpression:(GADBannerView *)bannerView{
  
}

# pragma mark GADAdSizeDelegate

- (void)adView:(__unused GADBannerView *)bannerView willChangeAdSizeTo:(GADAdSize)size
{
    CGSize adSize = CGSizeFromGADAdSize(size);
    self.onSizeChange(@{
                              @"width": @(adSize.width),
                              @"height": @(adSize.height) });
}

@end
