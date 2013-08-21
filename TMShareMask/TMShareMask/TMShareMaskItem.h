//
//  TMShareMaskItem.h
//  TMShareMask
//
//  Created by willsborKang on 13/5/15.
//  Copyright (c) 2013年 thinkermobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TMShareMaskItem;

typedef void(^ShareMaskItemTask)(TMShareMaskItem *item, float ratio, NSError *error);
typedef BOOL(^ShareMaskItemCancelBlock)(void);

typedef enum
{
    TMShareMaskItem_Action_None = 0,
    TMShareMaskItem_Action_SMS_Text = 1000,
    TMShareMaskItem_Action_Email_Text = 2000,
    TMShareMaskItem_Action_FaceBook_Text_By_Message_Dialog = 3000,
    TMShareMaskItem_Action_FaceBook_Create_Album_With_Upload_Photos = 3100,
    TMShareMaskItem_Action_FaceBook_Create_Album = 3101,
    TMShareMaskItem_Action_FaceBook_Upload_Photos_To_Album = 3102,
    TMShareMaskItem_Action_Line_Text = 4000,
    
} TMShareMaskItem_Action;

@interface TMShareMaskItem : NSObject

@property (nonatomic) TMShareMaskItem_Action action;

@property (nonatomic, strong) NSDictionary *shareContent;

@property (nonatomic, weak) UIViewController *baseViewController;

@property (nonatomic, copy) ShareMaskItemTask taskHandler;

@property (nonatomic, copy) ShareMaskItemCancelBlock cancelHandler;

@end
