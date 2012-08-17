//
//  WBKHTTPClient.m
//  ShareKit
//
//  Created by Heyward Fann on 12-8-16.
//  Copyright (c) 2012年 Heyward Fann. All rights reserved.
//

#import "WBKHTTPClient.h"

#import "AFNetworking.h"

#import "WBKAuthorizeView.h"
#import "SSKeychain.h"

#define kWBAPIURL   @"https://api.weibo.com/2/"

#define kWBKeychainServiceName          @"WeiboApp"
#define kWBKeychainUserID               @"WeiboUserID"
#define kWBKeychainAccessToken          @"WeiboAccessToken"
#define kWBKeychainExpireTime           @"WeiboExpireTime"

@interface WBKHTTPClient ()

@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic) NSTimeInterval expireTime;

@end

@implementation WBKHTTPClient

+ (WBKHTTPClient *)sharedClient
{
    static WBKHTTPClient *sharedClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedClient = [[WBKHTTPClient alloc] init];
    });

    return sharedClient;
}

- (id)init
{
    self = [super initWithBaseURL:[NSURL URLWithString:kWBAPIURL]];
    if (self) {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];

        [self readAuthorizeDataFromKeychain];
    }

    return self;
}

- (BOOL)isAuthorizeExpired
{
    if ([[NSDate date] timeIntervalSince1970] > _expireTime) {
        [self deleteAuthorizeDataInKeychain];
        return YES;
    }
    return NO;
}

- (BOOL)isLoggedIn
{
    return _userID && _accessToken && ![self isAuthorizeExpired];
}

- (void)loginSuccess:(void (^)())success failure:(void (^)(NSError *))failure
{
    WBKAuthorizeView *auth = [[WBKAuthorizeView alloc] init];
    [auth authorizeWithAppKey:kWeiboAppKey
                       secret:kWeiboAppSecret
                  redirectURI:kWeiboRedirectURL
                      success:^(NSString *token, NSString *uid, NSInteger expires) {
                          self.accessToken = token;
                          self.userID = uid;
                          self.expireTime = [[NSDate date] timeIntervalSince1970]+expires;

                          [self saveAuthorizeDataFromKeychain];

                          if (success) {
                              success();
                          }
                      } failure:^(NSError *error) {
                          DLog(@"login error: %@", [error description]);
                          [self deleteAuthorizeDataInKeychain];
                          
                          if (failure) {
                              failure(error);
                          }
                      }];
}

- (void)logout
{
    [self deleteAuthorizeDataInKeychain];
}

#pragma mark - Keychain Methods
- (NSString *)serviceName
{
    return [NSString stringWithFormat:@"%@_%@", kWBKeychainServiceName, kWeiboAppKey];
}

- (void)saveAuthorizeDataFromKeychain
{
    [SSKeychain setPassword:_userID
                 forService:[self serviceName]
                    account:kWBKeychainUserID];
    [SSKeychain setPassword:_accessToken
                 forService:[self serviceName]
                    account:kWBKeychainAccessToken];
    [SSKeychain setPassword:[NSString stringWithFormat:@"%lf", _expireTime]
                 forService:[self serviceName]
                    account:kWBKeychainExpireTime];
}

- (void)readAuthorizeDataFromKeychain
{
    self.userID = [SSKeychain passwordForService:[self serviceName]
                                         account:kWBKeychainUserID];
    self.accessToken = [SSKeychain passwordForService:[self serviceName]
                                              account:kWBKeychainAccessToken];
    self.expireTime = [[SSKeychain passwordForService:[self serviceName]
                                              account:kWBKeychainExpireTime] doubleValue];
}

- (void)deleteAuthorizeDataInKeychain
{
    self.userID = nil;
    self.accessToken = nil;
    self.expireTime = 0;
    
    [SSKeychain deletePasswordForService:[self serviceName]
                                 account:kWBKeychainUserID];
    [SSKeychain deletePasswordForService:[self serviceName]
                                 account:kWBKeychainAccessToken];
    [SSKeychain deletePasswordForService:[self serviceName]
                                 account:kWBKeychainExpireTime];
}

#pragma mark - weibo request
- (NSMutableDictionary *)defaultParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:_accessToken forKey:@"access_token"];
    return parameters;
}

- (NSError *)notLoggedInError
{
    NSDictionary *userinfo = [NSDictionary dictionaryWithObject:@"Need login."
                                                         forKey:@"ErrorKey"];
    NSError *error = [NSError errorWithDomain:@"WeiboErrorDomain"
                                         code:0
                                     userInfo:userinfo];
    return error;
}

- (void)getLoggedInUserInfoSuccess:(void (^)(NSDictionary *))success
                           failure:(void (^)(NSError *))failure
{
    if (![self isLoggedIn]) {
        if (failure) {
            failure([self notLoggedInError]);
        }
        
        return;
    }

    NSMutableDictionary *parameters = [self defaultParameters];
    [parameters setObject:_userID forKey:@"uid"];
    [self getPath:@"users/show.json"
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (success) {
                  NSDictionary *userinfo = (NSDictionary *)responseObject;
                  success(userinfo);
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

- (void)updateStatus:(NSString *)text
         withSuccess:(SuccessBlock)success
             failure:(FailureBlock)failure
{
    if (![self isLoggedIn]) {
        if (failure) {
            failure([self notLoggedInError]);
        }
        
        return;
    }

    NSMutableDictionary *parameters = [self defaultParameters];
    [parameters setObject:text forKey:@"status"];
    [self postPath:@"statuses/update.json"
        parameters:parameters
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               if (success) {
                   NSDictionary *dict = (NSDictionary *)responseObject;
                   success(dict);
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               if (failure) {
                   failure(error);
               }
           }];
}

- (void)updateStatus:(NSString *)text
               image:(UIImage *)img
         withSuccess:(SuccessBlock)success
             failure:(FailureBlock)failure
{
    if (![self isLoggedIn]) {
        if (failure) {
            failure([self notLoggedInError]);
        }
        
        return;
    }

    NSMutableDictionary *parameters = [self defaultParameters];
    [parameters setObject:(text ? text : @"") forKey:@"status"];
    NSMutableURLRequest *request = [self multipartFormRequestWithMethod:@"POST"
                                                                   path:@"statuses/upload.json"
                                                             parameters:parameters
                                              constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                  [formData appendPartWithFileData:UIImagePNGRepresentation(img)
                                                                              name:@"pic"
                                                                          fileName:@"file.png"
                                                                          mimeType:@"image/png"];
                                              }];
    AFJSONRequestOperation *operation = [[AFJSONRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            NSDictionary *dict = (NSDictionary *)responseObject;
            success(dict);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    [self enqueueHTTPRequestOperation:operation];
}

- (void)getHomeTimelineWithSuccess:(void (^)(NSArray *statuses))success
                           failure:(FailureBlock)failure
{
    if (![self isLoggedIn]) {
        if (failure) {
            failure([self notLoggedInError]);
        }

        return;
    }

    NSMutableDictionary *parameters = [self defaultParameters];
    [self getPath:@"statuses/home_timeline.json"
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if (success) {
                  NSDictionary *dict = (NSDictionary *)responseObject;
                  NSArray *statuses = [dict objectForKey:@"statuses"];

                  success(statuses);
              }
              
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              if (failure) {
                  failure(error);
              }
          }];
}

@end
