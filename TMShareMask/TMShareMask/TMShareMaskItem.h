//
//  TMShareMaskItem.h
//  TMShareMask
//
//  Created by willsborKang on 13/5/15.
//  Copyright (c) 2013年 thinkermobile. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    TMShareMaskItem_Action_None = 0,
    TMShareMaskItem_Action_SMS_Text = 1000,
    TMShareMaskItem_Action_Email_Text = 2000,
    TMShareMaskItem_Action_FaceBook_Text_By_Message_Dialog = 3000,
    TMShareMaskItem_Action_Line_Text = 4000,
    
} TMShareMaskItem_Action;

@interface TMShareMaskItem : NSObject

@property (nonatomic) TMShareMaskItem_Action action;

@property (nonatomic, strong) NSDictionary *shareContent;

@property (nonatomic, weak) UIViewController *baseViewController;

//+ (TMShareMaskItem *) shareMaskItemWithText:(NSString *) atAction:(TMShareMaskItem_Action)aAction;

@end
