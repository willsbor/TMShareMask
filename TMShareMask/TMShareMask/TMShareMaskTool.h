//
//  TMShareMaskTool.h
//  TMShareMask
//
//  Created by willsborKang on 13/5/15.
//  Copyright (c) 2013年 thinkermobile. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum
{
    TMShareMaskTool_Errcode_Finish = 0,
    TMShareMaskTool_Errcode_Doing = 1,
    TMShareMaskTool_Errcode_Failed = 1000,
    TMShareMaskTool_Errcode_Not_Support = 1001,
    TMShareMaskTool_Errcode_User_Cancel = 1002,
} TMShareMaskTool_Errcode;

@class TMShareMaskItem;
@class TMShareMaskTool;
@protocol TMShareMaskToolProtocol <NSObject>

- (void) shareMask:(TMShareMaskTool *)aTool FinishItem:(TMShareMaskItem *)aItem Error:(NSError *)aError;

@end


@interface TMShareMaskTool : NSObject

@property (nonatomic, readonly) TMShareMaskItem *activeItem;
@property (nonatomic, weak) id<TMShareMaskToolProtocol> delegate;

+ (TMShareMaskTool *) sharedInstance;

- (void) executeItem:(TMShareMaskItem *)aItem;

- (void) logoutFacebook;

@end
