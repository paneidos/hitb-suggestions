//
//  UIViewController+ProgressHUD.m
//  HITB Suggestions
//
//  Created by Sernin van de Krol on 29/05/14.
//  Copyright (c) 2014 Paneidos Desu. All rights reserved.
//

#import "UIViewController+ProgressHUD.h"
#import <MBProgressHUD.h>

@implementation UIViewController (ProgressHUD)

-(void)showMessage:(NSString*)message
{
    MBProgressHUD* HUD = [MBProgressHUD HUDForView:self.view];
    HUD.labelText = message;
    [HUD show:YES];
    [HUD hide:YES afterDelay:3.0];
}

@end
