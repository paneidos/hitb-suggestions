//
//  PDFriendsTableViewController.m
//  HITB Suggestions
//
//  Created by Sernin van de Krol on 29/05/14.
//  Copyright (c) 2014 Paneidos Desu. All rights reserved.
//

#import "PDFriendsTableViewController.h"

#import "PDAddFriendTableViewController.h"

@interface PDFriendsTableViewController ()

@property (nonatomic, strong) NSArray* friends;
@property (nonatomic, strong) NSArray* users;

@end

@implementation PDFriendsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.friends = @[];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated
{
    [self loadFriends];
    [self loadUsers];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)setTopic:(PFObject *)topic
{
    if(_topic != topic) {
        _topic = topic;
        self.users = @[];
        [self loadUsers];
    }
}

-(void)loadFriends
{
    FBRequest* request = [FBRequest requestForGraphPath:@"/me/friends"];
    FBRequestConnection* connection = [[FBRequestConnection alloc] init];
    [connection addRequest:request completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(error)
        {
            [self showMessage:@"Error loading friends"];
        }
        else
        {
            NSLog(@"Result: %@", result[@"data"]);
            self.friends = result[@"data"];
            self.navigationItem.rightBarButtonItem.enabled = YES;
            [self.tableView reloadData];
        }
    }];
    [connection start];
}
-(void)loadUsers
{
    
    if(!self.topic) return;
    PFQuery* query = [PFQuery queryWithClassName:@"TopicUser"];
    [query whereKey:@"topic" equalTo:self.topic];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error) {
            [self showMessage:@"Error loading friends"];
        } else {
            NSLog(@"Suggestions: %@", objects);
            self.users = objects;
            [self.tableView reloadData];
        }
    }];
}

-(IBAction)friendAdded:(UIStoryboardSegue*)segue
{
    [self loadUsers];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
//    FBGraphObject* friend = self.friends[indexPath.row];
    PFObject* topicUser = self.users[indexPath.row];
    // Configure the cell...
    cell.textLabel.text = topicUser[@"name"];
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"addFriend"])
    {
        PDAddFriendTableViewController* viewController = segue.destinationViewController;
        viewController.friends = self.friends;
        viewController.topic = self.topic;
    }
}


@end
