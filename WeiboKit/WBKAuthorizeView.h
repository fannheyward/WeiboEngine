//
//  WBKAuthorizeView.h
//  ShareKit
//
//  Created by Heyward Fann on 12-8-16.
//  Copyright (c) 2012年 Heyward Fann. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^AuthorizeSuccess)(NSString *token, NSString *uid, NSInteger expires);
typedef void(^AuthorizeFailure)(NSError *error);

@interface WBKAuthorizeView : UIView

- (void)authorizeWithAppKey:(NSString *)key
                     secret:(NSString *)secret
                redirectURI:(NSString *)uri
                    success:(AuthorizeSuccess)sucess
                    failure:(AuthorizeFailure)failure;

- (void)hide;

@end
