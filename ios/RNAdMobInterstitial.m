#import "RNAdMobInterstitial.h"
#import "RNAdMobUtils.h"
#import <React/RCTLog.h>

#if __has_include(<React/RCTUtils.h>)
#import <React/RCTUtils.h>
#else
#import "RCTUtils.h"
#endif

static NSString *const kEventAdLoaded = @"interstitialAdLoaded";
static NSString *const kEventAdFailedToLoad = @"interstitialAdFailedToLoad";
static NSString *const kEventAdOpened = @"interstitialAdOpened";
static NSString *const kEventAdFailedToOpen = @"interstitialAdFailedToOpen";
static NSString *const kEventAdClosed = @"interstitialAdClosed";
static NSString *const kEventAdLeftApplication = @"interstitialAdLeftApplication";

@implementation RNAdMobInterstitial
{
    BOOL hasListeners;
}
GADInterstitialAd  *_interstitial;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
    return @[
             kEventAdLoaded,
             kEventAdFailedToLoad,
             kEventAdOpened,
             kEventAdFailedToOpen,
             kEventAdClosed,
             kEventAdLeftApplication ];
}

#pragma mark exported methods

RCT_EXPORT_METHOD(requestAd:(NSString*) adUnit)
{
    if (_interstitial == nil) {
      GADRequest *request = [GADRequest request];
      [GADInterstitialAd loadWithAdUnitID:adUnit
                                  request:request
                        completionHandler:^(GADInterstitialAd *ad, NSError *error) {
        if (error) {
          NSDictionary *jsError = RCTJSErrorFromCodeMessageAndNSError(@"E_AD_REQUEST_FAILED", error.localizedDescription, error);
          [self sendEventWithName:kEventAdFailedToLoad body:jsError];
          return;
        }
        _interstitial = ad;
        _interstitial.fullScreenContentDelegate = self;
        [self sendEventWithName:kEventAdLoaded body:nil];
      }];
    }
}

RCT_EXPORT_METHOD(showAd:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if (_interstitial) {
        [_interstitial presentFromRootViewController:[UIApplication sharedApplication].delegate.window.rootViewController];
        resolve(nil);
    }
    else {
        reject(@"E_AD_NOT_READY", @"Ad is not ready.", nil);
    }
}

RCT_EXPORT_METHOD(isReady:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNumber numberWithBool:_interstitial != nil]]);
}

- (void)startObserving
{
    hasListeners = YES;
}

- (void)stopObserving
{
    hasListeners = NO;
}

#pragma mark GADInterstitialDelegate

- (void)adDidRecordImpression:(id<GADFullScreenPresentingAd>)ad{
  RCTLog(@"ADMob didRecord impression ad: %@", ad);
}

- (void)ad:(id<GADFullScreenPresentingAd>)ad didFailToPresentFullScreenContentWithError:(NSError *)error{
  if (hasListeners) {
      NSDictionary *jsError = RCTJSErrorFromCodeMessageAndNSError(@"E_AD_REQUEST_FAILED", error.localizedDescription, error);
      [self sendEventWithName:kEventAdFailedToLoad body:jsError];
  }
}

- (void)adDidPresentFullScreenContent:(id<GADFullScreenPresentingAd>)ad{
  if (hasListeners){
      [self sendEventWithName:kEventAdOpened body:nil];
  }
}

- (void)adWillDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad{
  if (hasListeners) {
      [self sendEventWithName:kEventAdClosed body:nil];
  }
}

- (void)adDidDismissFullScreenContent:(id<GADFullScreenPresentingAd>)ad{
  RCTLog(@"ADMob did Dismiss full Screen Content: %@", ad);
}

@end
