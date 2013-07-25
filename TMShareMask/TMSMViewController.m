//
//  TMSMViewController.m
//  TMShareMask
//
//  Created by willsborKang on 13/5/15.
//  Copyright (c) 2013年 thinkermobile. All rights reserved.
//

#import "TMSMViewController.h"

#import "TMShareMaskItem.h"
#import "TMShareMaskTool.h"

@interface TMSMViewController () <TMShareMaskToolProtocol>

@end

@implementation TMSMViewController

- (IBAction)clickSMS:(id)sender {
    TMShareMaskItem *item = [[TMShareMaskItem alloc] init];
    item.shareContent = @{@"text": @"test text"};
    item.action = TMShareMaskItem_Action_SMS_Text;
    item.baseViewController = self;
    [[TMShareMaskTool sharedInstance] executeItem:item];
}

- (IBAction)clickMail:(id)sender {
    TMShareMaskItem *item = [[TMShareMaskItem alloc] init];
    item.shareContent = @{@"text": @"test text", @"title": @"title"};
    item.action = TMShareMaskItem_Action_Email_Text;
    item.baseViewController = self;
    [[TMShareMaskTool sharedInstance] executeItem:item];
}

- (IBAction)clickLine:(id)sender {
    TMShareMaskItem *item = [[TMShareMaskItem alloc] init];
    item.shareContent = @{@"text": @"test text"};
    item.action = TMShareMaskItem_Action_Line_Text;
    item.baseViewController = self;
    [[TMShareMaskTool sharedInstance] executeItem:item];
}

- (IBAction)clickShareFaceBook:(id)sender {
    TMShareMaskItem *item = [[TMShareMaskItem alloc] init];
    item.shareContent = @{@"name": @"abc"};
    item.action = TMShareMaskItem_Action_FaceBook_Text_By_Message_Dialog;
    item.baseViewController = self;
    [[TMShareMaskTool sharedInstance] executeItem:item];
}

- (IBAction)clickShareFB_CreateAlbum:(id)sender {
    TMShareMaskItem *item = [[TMShareMaskItem alloc] init];
    item.shareContent = @{@"name": @"abc",
                          @"message": @"detail message",
                          @"privacy": @"{'value':'EVERYONE'}",
                          @"photos": @[@{@"source": UIImagePNGRepresentation([UIImage imageNamed:@"Default.png"]),
                                         @"message": @"test1"},
                                       @{@"source": UIImagePNGRepresentation([UIImage imageNamed:@"Default-568h@2x.png"]),
                                         @"message": @"test2"},
                                       @{@"source": UIImagePNGRepresentation([UIImage imageNamed:@"Default.png"]),
                                         @"message": @"test3"}]};
    item.action = TMShareMaskItem_Action_FaceBook_Create_Album_With_Upload_Photos;
    item.baseViewController = self;
    [[TMShareMaskTool sharedInstance] executeItem:item];
}


- (void) shareMask:(TMShareMaskTool *)aTool FinishItem:(TMShareMaskItem *)aItem Error:(NSError *)aError
{
    if (aError == nil ||
        aError.code == TMShareMaskTool_Errcode_Finish) {
        NSString *msg = @"success";
        if (aItem.action == TMShareMaskItem_Action_SMS_Text) {
            msg = @"sms success";
        }
        else if (aItem.action == TMShareMaskItem_Action_Email_Text) {
            msg = @"email success";
        }
        else if (aItem.action == TMShareMaskItem_Action_Line_Text) {
            msg = @"line success";
        }
        [[[UIAlertView alloc] initWithTitle:@"" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    else {
        if (aError.code == TMShareMaskTool_Errcode_Not_Support)
            [[[UIAlertView alloc] initWithTitle:@"" message:@"TMShareMaskTool_Errcode_Not_Support" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        else if (aError.code == TMShareMaskTool_Errcode_User_Cancel)
            [[[UIAlertView alloc] initWithTitle:@"" message:@"TMShareMaskTool_Errcode_User_Cancel" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        else if (aError.code == TMShareMaskTool_Errcode_Failed)
            [[[UIAlertView alloc] initWithTitle:@"" message:@"TMShareMaskTool_Errcode_Failed" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [TMShareMaskTool sharedInstance].delegate = self;
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [TMShareMaskTool sharedInstance].delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
