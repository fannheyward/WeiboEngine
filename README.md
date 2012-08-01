新浪微博 SDK，支持 OAuth 2.0 认证，支持 ARC。基于官方 SDK [SinaWeiBoSDK2][1] 修改，`WBRequest` 直接使用了官方封装，不支持 ARC，在 ARC 下要添加 `-fno-objc-arc` flag.

#### 使用

1. 在 `WBEngine.m` 修改设置 appKey, appSecret, redirectURL. redirectURL 必须和微博应用设置的授权回调页一致。
1. Code

    ```objc
    [[WBEngine sharedWBEngine] setDelegate:self];
    if ([[WBEngine sharedWBEngine] isLoggedIn]) {
        [[WBEngine sharedWBEngine] loggedInUserInfo];
    } else {
        [[WBEngine sharedWBEngine] logIn];
    }
    ```

1. 实现 delegate：

    ```objc
    #pragma mark - WBEngineDelegate
    - (void)engineDidLogIn
    {
        //login success
    }

    - (void)engineDidFailLogInWithError:(NSError *)error
    {
        //login failed.
    }

    - (void)engineRequest:(WBRequestType)type didSucceedWithResult:(id)result
    {
        if (WBRequestTypeUsersShow == type) {
            if (result && [result isKindOfClass:[NSDictionary class]]) {
                //...
            }
        }
    }

    - (void)engineRequest:(WBRequestType)type didFailWithError:(NSError *)error
    {
        DLog(@"requestType:%d, error: %@", type, [error description]);
    }
    ```

[1]:https://code.google.com/p/sinaweibosdkforoauth2/downloads/list