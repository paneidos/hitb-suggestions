//
//  PDMasterViewController.m
//  HITB Suggestions
//
//  Created by Sernin van de Krol on 29/05/14.
//  Copyright (c) 2014 Paneidos Desu. All rights reserved.
//

#import "PDMasterViewController.h"

#import "PDDetailViewController.h"

#import "PDMySuggestionViewController.h"

#import "PDResponseTableViewController.h"

@interface PDMasterViewController () <UIAlertViewDelegate> {
    NSMutableArray *_objects;
    PFObject* _newTopic;
    NSString* _facebookId;
}

@property (nonatomic, strong) NSMutableArray *myTopics;
@property (nonatomic, strong) NSMutableArray *otherTopics;

@end

@implementation PDMasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.myTopics = [NSMutableArray array];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
}

-(void)viewWillAppear:(BOOL)animated
{
    if([PFUser currentUser]) {
        [self reloadData];
    }
    _newTopic = nil;
}

-(void)viewDidAppear:(BOOL)animated
{
    NSLog(@"Current user: %@", [PFUser currentUser]);
    if(![PFUser currentUser])
    {
        [self performSegueWithIdentifier:@"facebookLogin" sender:self];
    }
}

-(void)reloadData
{
    // Exit if not logged in
    if(![PFUser currentUser]) return;
    NSLog(@"Reload data");
    PFQuery* myQuery = [PFQuery queryWithClassName:@"Topic"];
    [myQuery whereKey:@"user" equalTo:[PFUser currentUser]];
    [myQuery orderByDescending:@"createdAt"];
    myQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [myQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            [self showMessage:@"Error loading"];
        }
        else
        {
            self.myTopics = [NSMutableArray arrayWithArray:objects];
            [self.tableView reloadData];
        }
    }];
    if(!_facebookId) {
        [self getOwnFacebookId];
    }
    else
    {
        [self reloadOtherTopics:nil];
    }
}
-(void)reloadOtherTopics:(id)sender
{
    if(!_facebookId) return;
    NSLog(@"FB Id: %@", _facebookId);
    
    PFQuery* otherQuery = [PFQuery queryWithClassName:@"TopicUser"];
    [otherQuery whereKey:@"facebookId" equalTo:_facebookId];
    [otherQuery includeKey:@"topic"];
    PFQuery* topicQuery = [PFQuery queryWithClassName:@"Topic"];
    [topicQuery orderByDescending:@"createdAt"];
//    [otherQuery orderByDescending:@"topic.createdAt"];
    [otherQuery whereKey:@"topic" matchesQuery:topicQuery];
    otherQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [otherQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            [self showMessage:@"Error loading"];
        }
        else
        {
            NSLog(@"Other stuff: %@", objects);
            self.otherTopics = [NSMutableArray arrayWithArray:objects];
            [self.tableView reloadData];
        }
    }];
}
-(void)getOwnFacebookId
{
    FBRequest* request = [FBRequest requestForMe];
    FBRequestConnection* connection = [[FBRequestConnection alloc] init];
    [connection addRequest:request completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(error) {
            [self showMessage:@"Error loading"];
        }
        else
        {
            _facebookId = result[@"id"];
            [self performSelectorInBackground:@selector(reloadOtherTopics:) withObject:nil];
        }
    }];
    [connection start];
}

-(IBAction)loginDone:(UIStoryboardSegue*)segue
{
    NSLog(@"User is now logged in");
    [self reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    UIAlertView* newTopicView = [[UIAlertView alloc] initWithTitle:@"New topic" message:@"Enter the topic" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
    newTopicView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [newTopicView show];
}

-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != 0)
    {
        PFObject* newTopic = [PFObject objectWithClassName:@"Topic"];
        newTopic[@"user"] = [PFUser currentUser];
        newTopic[@"topic"] = [alertView textFieldAtIndex:0].text;
        [newTopic saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(!succeeded)
            {
                [self showMessage:@"Failed to add suggestion"];
            }
            else
            {
                [self reloadData];
                _newTopic = newTopic;
                [self performSegueWithIdentifier:@"mySuggestion" sender:self];
            }
        }];
    }
}
#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
    {
        return self.myTopics.count;
    }
    else
    {
        return self.otherTopics.count;
    }
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        return @"My topics";
    }
    else
    {
        return @"Other topics";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if(indexPath.section == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell" forIndexPath:indexPath];
        PFObject* object = self.myTopics[indexPath.row];
        cell.textLabel.text = object[@"topic"];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
        PFObject* topicUser = self.otherTopics[indexPath.row];
        PFObject* topic = topicUser[@"topic"];
        cell.textLabel.text = topic[@"topic"];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"respond"]) {
        PDResponseTableViewController* viewController = segue.destinationViewController;
        viewController.topic = self.otherTopics[self.tableView.indexPathForSelectedRow.row][@"topic"];
    } else if([[segue identifier] isEqualToString:@"mySuggestion"]) {
        PFObject* topic = _newTopic;
        if(!topic) {
            topic = self.myTopics[self.tableView.indexPathForSelectedRow.row];
        }
        PDMySuggestionViewController* viewController = segue.destinationViewController;
        viewController.topic = topic;
    }
}

@end
