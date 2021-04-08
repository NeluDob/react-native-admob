#import "RNAdMobRewarded.h"
#import "RNAdMobUtils.h"
#import <React/RCTLog.h>

#if __has_include(<React/RCTUtils.h>)
#import <React/RCTUtils.h>
#else
#import "RCTUtils.h"
#endif

static NSString *const kEventAdLoaded = @"rewardedVideoAdLoaded";
static NSString *const kEventAdFailedToLoad = @"rewardedVideoAdFailedToLoad";
static NSString *const kEventAdOpened = @"rewardedVideoAdOpened";
static NSString *const kEventAdClosed = @"rewardedVideoAdClosed";
static NSString *const kEventAdLeftApplication = @"rewardedVideoAdLeftApplication";
static NSString *const kEventRewarded = @"rewardedVideoAdRewarded";
static NSString *const kEventVideoStarted = @"rewardedVideoAdVideoStarted";
static NSString *const kEventVideoCompleted = @"rewardedVideoAdVideoCompleted";

@implementation RNAdMobRewarded
{
    BOOL hasListeners;
}

GADRewardedAd *rewardedAd;


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
             kEventRewarded,
             kEventAdLoaded,
             kEventAdFailedToLoad,
             kEventAdOpened,
             kEventVideoStarted,
             kEventAdClosed,
             kEventAdLeftApplication,
             kEventVideoCompleted ];
}

#pragma mark exported methods

RCT_EXPORT_METHOD(requestAd: (NSString*) adUnit)
{
  GADRequest *request = [GADRequest request];
  [GADRewardedAd loadWithAdUnitID:adUnit request:request completionHandler:^(GADRewardedAd *ad, NSError *error) {
    if (error) {
      NSDictionary *jsError = RCTJSErrorFromCodeMessageAndNSError(@"E_AD_REQUEST_FAILED", error.localizedDescription, error);
      [self sendEventWithName:kEventAdFailedToLoad body:jsError];
      return;
    }
    rewardedAd = ad;
    rewardedAd.fullScreenContentDelegate = self;
    [self sendEventWithName:kEventAdLoaded body:nil];
  }];
}

RCT_EXPORT_METHOD(showAd:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  if (rewardedAd) {
    UIViewController *rootVC = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    [rewardedAd presentFromRootViewController:rootVC userDidEarnRewardHandler:^{
      GADAdReward *reward = rewardedAd.adReward;
      [self sendEventWithName:kEventRewarded body:@{@"type": reward.type, @"amount": reward.amount}];
    }];
    resolve(nil);
  }
  else {
    reject(@"E_AD_NOT_READY", @"Ad is not ready.", nil);
  }
}

RCT_EXPORT_METHOD(isReady:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNumber numberWithBool: rewardedAd != nil]]);
}

- (void)startObserving
{
    hasListeners = YES;
}

- (void)stopObserving
{
    hasListeners = NO;
}

#pragma mark GADRewardBasedVideoAdDelegate

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
