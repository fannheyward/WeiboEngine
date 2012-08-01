//
//  WBAuthorizeView.h
//  AppRankHD
//
//  Created by Heyward Fann on 12-6-27.
//  Copyright (c) 2012年 Appwill Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WBAuthorizeDelegate <NSObject>

@required
- (void)authorizeDidSucceedWithToken:(NSString *)token userID:(NSString *)uid expiresIn:(NSInteger)seconds;

- (void)authorizeDidFailedWithError:(NSError *)error;

@end

@interface WBAuthorizeView : UIView

@property (nonatomic, unsafe_unretained) id<WBAuthorizeDelegate> delegate;

- (id)initWithAppKey:(NSString *)key secret:(NSString *)secret redirectURI:(NSString *)uri;
- (void)startAuthorize;

- (void)hide;

@end
