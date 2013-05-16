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
            
        default:
            NSAssert(false, @"Not support this type");
            break;
    }
}

- (void) _finishWithSuccess{
    if (_delegate) [_delegate shareMask:self
                             FinishItem:_activeItem
                                  Error:nil];
}

- (void) _finishWithError:(TMShareMaskTool_Errcode)aError
{
    if (_delegate)
        [_delegate shareMask:self FinishItem:_activeItem Error:([NSError errorWithDomain:NSStringFromClass([TMShareMaskTool class]) code:aError userInfo:nil])];
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
    smsPicker.body = _activeItem.text;
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
        NSString *title = _activeItem.title;
        
        mailController.mailComposeDelegate = self;
        //[mailController setToRecipients:@[NSLocalizedStringFromTable(@"TMSG_UI_Send_Bad_mail_receive", @"StreetGpsWords", nil)]];
        [mailController setSubject:title];
        [mailController setMessageBody:_activeItem.text  isHTML:NO];
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
    
    if ([Line shareText:_activeItem.text])
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
        FBSession *session = [[FBSession alloc] initWithAppID:nil
                                                  permissions:nil
                                              urlSchemeSuffix:nil
                                           tokenCacheStrategy:tokenCachingStrategy];
        [FBSession setActiveSession:session];
        
        [session openWithBehavior:FBSessionLoginBehaviorWithFallbackToWebView
                completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                    
                    if (status == FBSessionStateClosed ||
                        status == FBSessionStateClosedLoginFailed) {
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
                    
                    handler(session, status, error);
                }];
    } else
        NSAssert(FALSE, @"undefined ");
}

// Convenience method to perform some action that requires the "publish_actions" permissions.
- (void) performPublishAction:(void (^)(void)) action {
    
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
                [selfItem performPublishAction:_fbaction];
            } else {
                //LogEvent_Error_FaceBook_Login(error)
                NSLog(@"fb login error = %@", error);
            }
        }];
    } else {
        // we defer request for permission to post to the moment of post, then we check for the permission
        if ([[FBSession activeSession].permissions indexOfObject:@"publish_actions"] == NSNotFound) {
            void (^_fbaction)(void);
            _fbaction = [action copy];
            
            //__unsafe_unretained PTGlobalVar *selfItem = self;
            // if we don't already have the permission, then we request it now
            [[FBSession activeSession] requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
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

- (void) _shareTextToFacebook
{
    [self performPublishAction:^{
        
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
