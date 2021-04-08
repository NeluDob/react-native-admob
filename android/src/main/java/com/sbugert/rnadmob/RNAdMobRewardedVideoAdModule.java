package com.sbugert.rnadmob;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableNativeArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.OnUserEarnedRewardListener;
import com.google.android.gms.ads.rewarded.RewardItem;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;

import java.util.ArrayList;

public class RNAdMobRewardedVideoAdModule extends ReactContextBaseJavaModule {

    public static final String REACT_CLASS = "RNAdMobRewarded";

    public static final String EVENT_AD_LOADED = "rewardedVideoAdLoaded";
    public static final String EVENT_AD_FAILED_TO_LOAD = "rewardedVideoAdFailedToLoad";
    public static final String EVENT_AD_OPENED = "rewardedVideoAdOpened";
    public static final String EVENT_AD_CLOSED = "rewardedVideoAdClosed";
    public static final String EVENT_AD_LEFT_APPLICATION = "rewardedVideoAdLeftApplication";
    public static final String EVENT_REWARDED = "rewardedVideoAdRewarded";
    public static final String EVENT_VIDEO_STARTED = "rewardedVideoAdVideoStarted";
    public static final String EVENT_VIDEO_COMPLETED = "rewardedVideoAdVideoCompleted";

    RewardedAd mRewardedVideoAd;
    private ReactApplicationContext contextLocal;

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    public RNAdMobRewardedVideoAdModule(ReactApplicationContext reactContext) {
        super(reactContext);
        contextLocal = reactContext;
    }

    private void sendEvent(String eventName, @Nullable WritableMap params) {
        getReactApplicationContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class).emit(eventName, params);
    }


    @ReactMethod
    public void requestAd(final String adUnitID) {
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override
            public void run() {
                AdRequest adRequest = new AdRequest.Builder().build();

                RewardedAd.load(contextLocal, adUnitID, adRequest, new RewardedAdLoadCallback() {
                    @Override
                    public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
                        // Handle the error.
                        WritableMap event = Arguments.createMap();
                        WritableMap error = Arguments.createMap();
                        event.putString("message", loadAdError.getMessage());
                        sendEvent(EVENT_AD_FAILED_TO_LOAD, event);
                        mRewardedVideoAd = null;
                    }

                    @Override
                    public void onAdLoaded(@NonNull RewardedAd rewardedAd) {
                        mRewardedVideoAd = rewardedAd;
                        sendEvent(EVENT_AD_LOADED, null);
                        mRewardedVideoAd.setFullScreenContentCallback(new FullScreenContentCallback() {
                            @Override
                            public void onAdShowedFullScreenContent() {
                                // Called when ad is shown.
                                sendEvent(EVENT_AD_OPENED, null);
                                mRewardedVideoAd = null;
                            }

                            @Override
                            public void onAdFailedToShowFullScreenContent(AdError adError) {
                                // Called when ad fails to show.
                                WritableMap event = Arguments.createMap();
                                WritableMap error = Arguments.createMap();
                                event.putString("message", adError.getMessage());
                                sendEvent(EVENT_AD_FAILED_TO_LOAD, event);
                            }

                            @Override
                            public void onAdDismissedFullScreenContent() {
                                // Called when ad is dismissed.
                                // Don't forget to set the ad reference to null so you
                                // don't show the ad a second time.
                                sendEvent(EVENT_AD_CLOSED, null);
                            }
                        });
                    }
                });
            }
        });
    }

    @ReactMethod
    public void showAd(final Promise promise) {
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override
            public void run() {
                if (mRewardedVideoAd != null) {

                    mRewardedVideoAd.show(contextLocal.getCurrentActivity(), new OnUserEarnedRewardListener() {
                        @Override
                        public void onUserEarnedReward(@NonNull RewardItem rewardItem) {
                            WritableMap reward = Arguments.createMap();

                            reward.putInt("amount", rewardItem.getAmount());
                            reward.putString("type", rewardItem.getType());

                            sendEvent(EVENT_REWARDED, reward);
                        }
                    });
                    promise.resolve(null);
                } else {
                    promise.reject("E_AD_NOT_READY", "Ad is not ready.");
                }
            }
        });
    }

    @ReactMethod
    public void isReady(final Callback callback) {
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override
            public void run() {
                if (mRewardedVideoAd != null) {
                    callback.invoke(true);
                } else {
                    callback.invoke(false);
                }
            }
        });
    }
}
