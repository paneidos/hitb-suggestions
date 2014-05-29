//
//  PDFacebookLoginViewController.m
//  HITB Suggestions
//
//  Created by Sernin van de Krol on 29/05/14.
//  Copyright (c) 2014 Paneidos Desu. All rights reserved.
//

#import "PDFacebookLoginViewController.h"

@interface PDFacebookLoginViewController ()

@end

@implementation PDFacebookLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImage * backgroundImage;
    if ([[UIScreen mainScreen] bounds].size.height == 568)
    {
        backgroundImage = [UIImage imageNamed:@"ConnectBG-568h@2x.png"];
    }
    else
    {
        backgroundImage = [UIImage imageNamed:@"ConnectBG.png"];
    }
    self.bgView.image = backgroundImage;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)loginButtonPressed:(id)sender
{
    [PFFacebookUtils logInWithPermissions:@[@"public_profile",@"email", @"user_friends"] block:^(PFUser *user, NSError *error) {
        if(error)
        {
            [self showMessage:@"Login failed"];
        }
        else
        {
            if(user) {
                [self performSegueWithIdentifier:@"loginDone" sender:self];
            } else {
                [self showMessage:@"Not logged in"];
            }
            NSLog(@"User: %@", user);
        }
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
