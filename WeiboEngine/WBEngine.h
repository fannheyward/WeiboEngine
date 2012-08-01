//
//  WBEngine.h
//  AppRankHD
//
//  Created by Heyward Fann on 12-5-9.
//  Copyright (c) 2012年 Appwill Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WBRequest.h"

@class WBEngine;

@protocol WBEngineDelegate <NSObject>

@optional
- (void)engineDidLogIn;
- (void)engineDidFailLogInWithError:(NSError *)error;

- (void)engineRequest:(WBRequestType)type didSucceedWithResult:(id)result;
- (void)engineRequest:(WBRequestType)type didFailWithError:(NSError *)error;

@end

@interface WBEngine : NSObject

@property (nonatomic, unsafe_unretained) id<WBEngineDelegate> delegate;

+ (WBEngine *)sharedWBEngine;

- (void)logIn;
- (void)logOut;
- (void)resignOAuth;

- (BOOL)isLoggedIn;

- (void)sendWeiboWithText:(NSString *)text image:(UIImage *)image;

- (void)loggedInUserInfo;

- (void)followByUserName:(NSString *)name;
- (void)followByUserID:(long long)uid;

- (void)bilateralFriendsList;
- (void)followedFriendsListFromCursor:(NSInteger)cursor;
- (void)checkFriendShipWithUID:(NSString *)target_id;

@end
