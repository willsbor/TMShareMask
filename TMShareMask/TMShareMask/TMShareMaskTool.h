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
    TMShareMaskTool_Errcode_Failed = 1,
    TMShareMaskTool_Errcode_Not_Support = 1000,
    TMShareMaskTool_Errcode_User_Cancel = 2000,
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

@end
