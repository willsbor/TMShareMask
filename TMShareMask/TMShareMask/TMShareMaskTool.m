//
//  TMShareMaskTool.m
//  TMShareMask
//
//  Created by willsborKang on 13/5/15.
//  Copyright (c) 2013年 thinkermobile. All rights reserved.
//

#import "TMShareMaskTool.h"
#import "TMShareMaskItem.h"

#import <FacebookSDK/FBSessionTokenCachingStrategy.h>
#import <FacebookSDK/FacebookSDK.h>
#import <LineKit/Line.h>
#import <MessageUI/MessageUI.h>

#import <NSLogger/LoggerCommon.h>
#import <NSLogger/LoggerClient.h>

#ifdef DEBUG
#define LOG_NETWORK(level, ...)    LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"network",level,__VA_ARGS__)
#define LOG_GENERAL(level, ...)    LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"general",level,__VA_ARGS__)
#define LOG_GRAPHICS(level, ...)   LogMessageF(__FILE__,__LINE__,__FUNCTION__,@"graphics",level,__VA_ARGS__)
#else
#define LOG_NETWORK(...)    do{}while(0)
#define LOG_GENERAL(...)    do{}while(0)
#define LOG_GRAPHICS(...)   do{}while(0)
#endif

#define USER_DEFAULT_FB_LOGIN @"wejiiji22#wekoj2ij3ijjdije"

@interface TMShareMaskTool () <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>

@end

@implementation TMShareMaskTool
@synthesize activeItem = _activeItem;

static TMShareMaskTool *g_sharedInstance = nil;

+ (TMShareMaskTool *) sharedInstance
{
    static dispatch_once_t pred;
	dispatch_once(&pred, ^{
        g_sharedInstance = [[self alloc] init];
    });
	return g_sharedInstance;
}

- (void) executeItem:(TMShareMaskItem *)aItem
{
    _activeItem = aItem;
    switch (aItem.action) {
        case TMShareMaskItem_Action_SMS_Text:
            [self _shareTextToSMS];
            break;
            
        case TMShareMaskItem_Action_Email_Text:
            [self _shareTextToMail];
            break;
            
        case TMShareMaskItem_Action_Line_Text:
            [self _shareTextToLine];
            break;
            
        case TMShareMaskItem_Action_FaceBook_Text_By_Message_Dialog:
            [self _shareTextToFacebook];
            break;
            
        case TMShareMaskItem_Action_FaceBook_Create_Album_With_Upload_Photos:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _createAlbumWithUploadPhotos];
            });
            break;
        }
        case TMShareMaskItem_Action_FaceBook_Create_Album:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _createAlbum];
            });
            break;
        }
        case TMShareMaskItem_Action_FaceBook_Upload_Photos_To_Album:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _uploadPhotosToAlbum];
            });
            break;
        }
        default:
            NSAssert(false, @"Not support this type");
            break;
    }
}

- (void) _finishWithSuccess{
    [self _finishWithSuccessWithUserInfo:nil];
}

- (void) _finishWithSuccessWithUserInfo:(id)aUserInfo{
    NSError *error = ([NSError errorWithDomain:NSStringFromClass([TMShareMaskTool class]) code:TMShareMaskTool_Errcode_Finish userInfo:aUserInfo]);
    if (_delegate) [_delegate shareMask:self
                             FinishItem:_activeItem
                                  Error:error];
    if (_activeItem.taskHandler) {
        _activeItem.taskHandler(_activeItem, 1.0f, error);
    }
}

- (void) _finishWithError:(TMShareMaskTool_Errcode)aError
{
    [self _finishWithError:aError WithUserInfo:nil];
}

- (void) _finishWithError:(TMShareMaskTool_Errcode)aError WithUserInfo:(id)aUserInfo
{
    NSError *error = ([NSError errorWithDomain:NSStringFromClass([TMShareMaskTool class])
                                          code:aError
                                      userInfo:aUserInfo]);
    if (_delegate)
        [_delegate shareMask:self FinishItem:_activeItem Error:error];
    
    if (_activeItem.taskHandler) {
        _activeItem.taskHandler(_activeItem, 1.0f, error);
    }
}

#pragma mark - SMS

- (void) _shareTextToSMS
{
    if ( NO == [MFMessageComposeViewController canSendText])
    {
        [self _finishWithError:(TMShareMaskTool_Errcode_Not_Support)];
        return;
    }
    
    MFMessageComposeViewController *smsPicker = [[MFMessageComposeViewController alloc] init];
    smsPicker.messageComposeDelegate = self;
    smsPicker.body = _activeItem.shareContent[@"text"];
    smsPicker.recipients = _activeItem.shareContent[@"recipients"];
    [_activeItem.baseViewController presentViewController:smsPicker animated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [controller dismissViewControllerAnimated:YES completion:^{
        switch (result) {
            case MessageComposeResultCancelled:
                [self _finishWithError:(TMShareMaskTool_Errcode_User_Cancel)];
                break;
            case MessageComposeResultSent:
                [self _finishWithSuccess];
                break;
            default:
            case MessageComposeResultFailed:
                [self _finishWithError:(TMShareMaskTool_Errcode_Failed)];
                break;
        }
    }];
}

#pragma mark - mail

- (void) _shareTextToMail
{
    if (NO == [MFMailComposeViewController canSendMail])
    {
        [self _finishWithError:(TMShareMaskTool_Errcode_Not_Support)];
        return;
    }
    
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    if(mailController)
    {
        NSString *title = _activeItem.shareContent[@"subject"];
        
        mailController.mailComposeDelegate = self;
        //[mailController setToRecipients:@[NSLocalizedStringFromTable(@"TMSG_UI_Send_Bad_mail_receive", @"StreetGpsWords", nil)]];
        [mailController setSubject:title];
        [mailController setMessageBody:_activeItem.shareContent[@"text"]  isHTML:NO];
        [_activeItem.baseViewController presentViewController:mailController animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:^{
        switch (result) {
            case MFMailComposeResultCancelled:
                [self _finishWithError:(TMShareMaskTool_Errcode_User_Cancel)];
                break;
            case MFMailComposeResultSaved:
                [self _finishWithError:(TMShareMaskTool_Errcode_User_Cancel)];
                break;
            case MFMailComposeResultSent:
                [self _finishWithSuccess];
                break;
            default:
            case MFMailComposeResultFailed:
                [self _finishWithError:(TMShareMaskTool_Errcode_Failed)];
                break;
        }
    }];
    
    
}

#pragma mark - line

- (void) _shareTextToLine
{
    if ([Line isLineInstalled] == NO) {
        [self _finishWithError:(TMShareMaskTool_Errcode_Not_Support)];
        return;
    }
    
    if ([Line shareText:_activeItem.shareContent[@"text"]])
        [self _finishWithSuccess];
    else
        [self _finishWithError:(TMShareMaskTool_Errcode_Failed)];
}

#pragma mark - facebook

- (void) logoutFacebook
{
    // if a user logs out explicitly, we delete any cached token information, and next
    // time they run the applicaiton they will be presented with log in UX again; most
    // users will simply close the app or switch away, without logging out; this will
    // cause the implicit cached-token login to occur on next launch of the application
    [[FBSession activeSession] closeAndClearTokenInformation];
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def removeObjectForKey:USER_DEFAULT_FB_LOGIN];
    [def synchronize];
}

- (void) loginFacebook:(FBSessionStateHandler)handler
{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    
    NSString *cacheString = [def objectForKey:USER_DEFAULT_FB_LOGIN];
    if (cacheString == nil) {
        cacheString = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    }
    
    FBSessionTokenCachingStrategy *tokenCachingStrategy = [[FBSessionTokenCachingStrategy alloc] initWithUserDefaultTokenInformationKeyName:cacheString];
    
    if (tokenCachingStrategy != nil) {
        if ([FBSession activeSession].isOpen) {
            return;
        }
        
        FBSession *session = [[FBSession alloc] initWithAppID:nil
                                                  permissions:nil
                                              urlSchemeSuffix:nil
                                           tokenCacheStrategy:tokenCachingStrategy];
        [FBSession setActiveSession:session];
        
        [session openWithBehavior:FBSessionLoginBehaviorUseSystemAccountIfPresent //FBSessionLoginBehaviorWithFallbackToWebView
                completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                    
                    if (status == FBSessionStateClosed
                        || status == FBSessionStateClosedLoginFailed
                        || status == FBSessionStateOpenTokenExtended) {
                        return ;
                    }
                    
                    if (error == nil) {
                        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
                        [def setObject:cacheString forKey:USER_DEFAULT_FB_LOGIN];
                        [def synchronize];
                    } else {
                        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
                        [def removeObjectForKey:USER_DEFAULT_FB_LOGIN];
                        [def synchronize];
                    }
                    
                    LOG_GENERAL(1, @"FaceBook session = %d", status);

                    handler(session, status, error);
                }];
    } else
        NSAssert(FALSE, @"undefined ");
}

// Convenience method to perform some action that requires the "publish_actions" permissions.
- (void) performPermissions:(NSArray *)aPermissions Action:(void (^)(void)) action {
    
    NSAssert([FBSession activeSession] != nil, @"FBSession.activeSession is nil");
    
    //NSAssert([FBSession activeSession].isOpen, @"FBSession.activeSession.isOpen is not open");
    LOG_GENERAL(1, @"[FBSession activeSession].isOpen = %d", [FBSession activeSession].isOpen);
    
    if (![FBSession activeSession].isOpen) {
        void (^_fbaction)(void);
        _fbaction = [action copy];
        
        __weak TMShareMaskTool *selfItem = self;
        [self loginFacebook:^(FBSession *session,
                              FBSessionState status,
                              NSError *error) {
            if (error == nil) {
                [selfItem performPermissions:aPermissions Action:_fbaction];
            } else {
                //LogEvent_Error_FaceBook_Login(error)
                NSLog(@"fb login error = %@", error);
            }
        }];
    } else {
        // we defer request for permission to post to the moment of post, then we check for the permission
        NSMutableArray *addPermissions = [[NSMutableArray alloc] init];
        
        for (NSString *object in aPermissions) {
            if (NO == [[FBSession activeSession].permissions containsObject:object]) {
                [addPermissions addObject:object];
            }
        }
        
        if ([addPermissions count] > 0) {
            void (^_fbaction)(void);
            _fbaction = [action copy];
            
            //__unsafe_unretained PTGlobalVar *selfItem = self;
            // if we don't already have the permission, then we request it now
            [[FBSession activeSession] requestNewPublishPermissions:addPermissions
                                                    defaultAudience:FBSessionDefaultAudienceFriends
                                                  completionHandler:^(FBSession *session, NSError *error) {
                                                      if (!error) {
                                                          _fbaction();
                                                      } else {
                                                          //LogEvent_Error_FaceBook_PublishPermissions(error)
                                                      }
                                                      //For this example, ignore errors (such as if user cancels).
                                                  }];
        } else {
            action();
        }
    }
}

- (void) _createAlbum
{
    __weak TMShareMaskTool *selfItem = self;
    [self __createAlbumComplete:^(FBRequestConnection *connection,
                                  id result,
                                  NSError *error)
     {
         if (error)
         {
             //showing an alert for failure
             LOG_GENERAL(0, @"create Album failed = %@", error);
             [selfItem _finishWithError:(TMShareMaskTool_Errcode_Failed)];
         }
         else
         {
             //showing an alert for success
             LOG_GENERAL(0, @"create Album OK result = %@", result);
             
             [self _finishWithSuccessWithUserInfo:result];
         }
     }];
}

- (void) __createAlbumComplete:(FBRequestHandler)aBlock
{
    [self performPermissions:@[@"publish_actions", @"user_photos", @"publish_stream", @"photo_upload"] Action:^{
        NSMutableDictionary *postParams = [NSMutableDictionary dictionary];
        postParams[@"name"] = _activeItem.shareContent[@"name"];
        postParams[@"message"] = _activeItem.shareContent[@"message"];
        postParams[@"privacy"] = _activeItem.shareContent[@"privacy"];
        
        
        [FBRequestConnection startWithGraphPath:@"me/albums"
                                     parameters:postParams
                                     HTTPMethod:@"POST"
                              completionHandler:aBlock];
    }];
}

- (void) _uploadPhotosToAlbum
{
    NSString *albumID = _activeItem.shareContent[@"albumID"];
    [self _uploadPhotosToAlbumBy:albumID];
}

- (void) _uploadPhotosToAlbumBy:(NSString *)albumID
{
    [self performPermissions:@[@"publish_actions", @"user_photos", @"publish_stream", @"photo_upload"] Action:^{
        NSArray *photos = _activeItem.shareContent[@"photos"];
        [self _sequenUploadIndex:0 AtArray:photos onAlbum:albumID];
    }];
}

- (void) _createAlbumWithUploadPhotos
{
    __weak TMShareMaskTool *selfItem = self;
    [self __createAlbumComplete:^(FBRequestConnection *connection,
                                  id result,
                                  NSError *error)
     {
         if (error)
         {
             //showing an alert for failure
             LOG_GENERAL(0, @"create Album failed = %@", error);
             [selfItem _finishWithError:(TMShareMaskTool_Errcode_Failed)];
         }
         else
         {
             //showing an alert for success
             LOG_GENERAL(0, @"create Album OK result = %@", result);
             
             
             if (_activeItem.taskHandler) {
                 NSError *error = ([NSError errorWithDomain:NSStringFromClass([TMShareMaskTool class])
                                                       code:TMShareMaskTool_Errcode_Doing
                                                   userInfo:result]);
                     _activeItem.taskHandler(_activeItem, 0.1f, error);
             }
             
             /// 接著傳圖片
             [self _uploadPhotosToAlbumBy:result[@"id"]];
         }
     }];
}

- (void) _sequenUploadIndex:(int)aIndex AtArray:(NSArray *)aDatas onAlbum:(NSString *)aAlbumID
{
    NSDictionary *photo = aDatas[aIndex];
    
    LOG_GENERAL(6, @"upload photo parameters = %@", photo[@"message"]);

    __weak TMShareMaskTool *selfItem = self;
    [FBRequestConnection startWithGraphPath:[NSString stringWithFormat:@"%@/photos", aAlbumID]
                                 parameters:photo
                                 HTTPMethod:@"POST"
                          completionHandler:^(FBRequestConnection *connection,
                                              id result,
                                              NSError *error)
     {
         if (error)
         {
             //showing an alert for failure
             LOG_GENERAL(0, @"upload photo failed = %@", error);
             
             [selfItem _finishWithError:(TMShareMaskTool_Errcode_Failed)
                           WithUserInfo:@{@"index": @(aIndex), @"result": (result == nil) ? @{} : result}];
         }
         else
         {
             //showing an alert for success
             
             if (_activeItem.taskHandler) {
                 NSError *error = ([NSError errorWithDomain:NSStringFromClass([TMShareMaskTool class])
                                                       code:TMShareMaskTool_Errcode_Doing
                                                   userInfo:@{@"index": @(aIndex),
                                                              @"result": (result == nil) ? @{} : result}]);
                     _activeItem.taskHandler(_activeItem, 0.1f + ((CGFloat)aIndex / [aDatas count]) * 0.9f, error);
             }
             
             if (aIndex + 1 < [aDatas count]) {
                 [self _sequenUploadIndex:aIndex + 1  AtArray:aDatas onAlbum:aAlbumID];
             }
             else {
                 LOG_GENERAL(0, @"upload photo OK result = %@", result);
                 [selfItem _finishWithSuccess];
             }
         }
     }];
}

- (void) _shareTextToFacebook
{
    [self performPermissions:@[@"publish_actions"] Action:^{
        
        /*
         NSMutableDictionary *postParams = [NSMutableDictionary dictionary];
         [postParams setObject:_activeItem.text forKey:@"message"];
         
         
         __weak TMShareMaskTool *selfItem = self;
         [FBRequestConnection startWithGraphPath:@"me/photos"
         parameters:postParams
         HTTPMethod:@"POST"
         completionHandler:^(FBRequestConnection *connection,
         id result,
         NSError *error)
         {
         if (error)
         {
         //LogEvent_Error_Share_FB(error)
         //showing an alert for failure
         LOG_GENERAL(0, @"send failed = %@", error);
         [selfItem _finishWithSuccess];
         }
         else
         {
         //showing an alert for success
         //LogEvent_Event_FBShareSure
         LOG_GENERAL(0, @"send Photo OK");
         [selfItem _finishWithError:(TMShareMaskTool_Errcode_Failed)];
         }
         }];*/
        
        /*
         NSError *error;
         NSData *jsonData = [NSJSONSerialization
         dataWithJSONObject:@{
         @"social_karma": @"5",
         @"badge_of_awesomeness": @"1"}
         options:0
         error:&error];
         if (!jsonData) {
         NSLog(@"JSON error: %@", error);
         return;
         }
         NSString *giftStr = [[NSString alloc]
         initWithData:jsonData
         encoding:NSUTF8StringEncoding];
         NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
         giftStr, @"data",
         nil];
         
         // Display the requests dialog
         [FBWebDialogs
         presentRequestsDialogModallyWithSession:nil
         message:@"Learn how to make your iOS apps social."
         title:nil
         parameters:params
         handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
         if (error) {
         // Error launching the dialog or sending the request.
         NSLog(@"Error sending request.");
         } else {
         if (result == FBWebDialogResultDialogNotCompleted) {
         // User clicked the "x" icon
         NSLog(@"User canceled request.");
         } else {
         // Handle the send request callback
         NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
         if (![urlParams valueForKey:@"request"]) {
         // User clicked the Cancel button
         NSLog(@"User canceled request.");
         } else {
         // User clicked the Send button
         NSString *requestID = [urlParams valueForKey:@"request"];
         NSLog(@"Request ID: %@", requestID);
         }
         }
         }
         }];
         */
        
        // Put together the dialog parameters
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:_activeItem.shareContent];
        /*[NSMutableDictionary dictionaryWithObjectsAndKeys:
         @"Facebook SDK for iOS", @"name",
         @"Build great social apps and get more installs.", @"caption",
         @"The Facebook SDK for iOS makes it easier and faster to develop Facebook integrated iOS apps.", @"description",
         @"https://developers.facebook.com/ios", @"link",
         @"https://raw.github.com/fbsamples/ios-3.x-howtos/master/Images/iossdk_logo.png", @"picture",
         nil];
         */
        /*
         [FBWebDialogs presentDialogModallyWithSession:session
         dialog:@"feed"
         parameters:parameters
         handler:handler
         */
        
        // Invoke the dialog
        [FBWebDialogs presentDialogModallyWithSession:nil
                                               dialog:@"feed"
                                           parameters:params
                                              handler:
         ^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
             if (error) {
                 // Error launching the dialog or publishing a story.
                 LOG_GENERAL(2, @"Error publishing story.");
                 [self _finishWithError:(TMShareMaskTool_Errcode_Failed)];
             } else {
                 if (result == FBWebDialogResultDialogNotCompleted) {
                     // User clicked the "x" icon
                     LOG_GENERAL(2, @"User canceled story publishing.");
                     [self _finishWithError:(TMShareMaskTool_Errcode_User_Cancel)];
                 } else {
                     // Handle the publish feed callback
                     NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                     if (![urlParams valueForKey:@"post_id"]) {
                         // User clicked the Cancel button
                         LOG_GENERAL(2, @"User canceled story publishing.");
                         [self _finishWithError:(TMShareMaskTool_Errcode_User_Cancel)];
                     } else {
                         // User clicked the Share button
                         /*NSString *msg = [NSString stringWithFormat:
                          @"Posted story, id: %@",
                          [urlParams valueForKey:@"post_id"]];
                          NSLog(@"%@", msg);
                          // Show the result in an alert
                          [[[UIAlertView alloc] initWithTitle:@"Result"
                          message:msg
                          delegate:nil
                          cancelButtonTitle:@"OK!"
                          otherButtonTitles:nil]
                          show];*/
                         
                         [self _finishWithSuccess];
                     }
                 }
             }
         }];
        
    }];
}

- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [params setObject:val forKey:[kv objectAtIndex:0]];
    }
    return params;
}

@end
