//
//  PDResponseTableViewController.m
//  HITB Suggestions
//
//  Created by Sernin van de Krol on 29/05/14.
//  Copyright (c) 2014 Paneidos Desu. All rights reserved.
//

#import "PDResponseTableViewController.h"

static NSString *responses[] = { @"yes", @"maybe", @"no" };

@interface PDResponseTableViewController ()

@property (nonatomic, strong) NSArray* suggestions;
@property (nonatomic, strong) NSMutableDictionary* responses;

@end

@implementation PDResponseTableViewController

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
    self.suggestions = @[];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewDidAppear:(BOOL)animated
{
    NSLog(@"Topic: %@", self.topic);
}

-(void)setTopic:(PFObject *)topic
{
    if(_topic != topic) {
        _topic = topic;
        self.suggestions = @[];
        self.responses = [NSMutableDictionary dictionary];
        self.navigationItem.title = topic[@"topic"];
        [self loadItems];
        [self loadResponses];
    }
}

-(void)loadItems
{
    if(!self.topic) return;
    PFQuery* query = [PFQuery queryWithClassName:@"Suggestion"];
    [query whereKey:@"topic" equalTo:self.topic];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error) {
            [self showMessage:@"Error loading suggestions"];
        } else {
//            NSLog(@"Suggestions: %@", objects);
            self.suggestions = objects;
            [self.tableView reloadData];
        }
    }];
}
-(void)loadResponses
{
    if(!self.topic) return;
    PFQuery* suggestionQuery = [PFQuery queryWithClassName:@"Suggestion"];
    [suggestionQuery whereKey:@"topic" equalTo:self.topic];
    PFQuery* query = [PFQuery queryWithClassName:@"Response"];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query includeKey:@"suggestion"];
    [query whereKey:@"suggestion" matchesQuery:suggestionQuery];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            [self showMessage:@"Error loading responses"];
        }
        else
        {
            NSLog(@"Responses: %@", objects);
            for(PFObject* response in objects) {
                self.responses[[response[@"suggestion"] objectId]] = response;
            }
            NSLog(@"Responses: %@", self.responses);
            [self.tableView reloadData];

        }
    }];
}
-(IBAction)segmentChanged:(id)sender
{
    NSLog(@"Save this!: %@", sender);
    UISegmentedControl* control = sender;
    UIView* view = control.superview;
    while(![view isKindOfClass:[UITableViewCell class]] && view.superview)
    {
        view = view.superview;
    }
    NSLog(@"Super: %@", view);
    if(view)
    {
        NSIndexPath* indexPath = [self.tableView indexPathForCell:(UITableViewCell*)view];
        PFObject* suggestion = self.suggestions[indexPath.row];
        NSLog(@"Suggestion: %@", suggestion);
        [self saveResponse:responses[control.selectedSegmentIndex] forSuggestion:suggestion];
    }
}
-(void)saveResponse:(NSString*)result forSuggestion:(PFObject*)suggestion
{
    PFQuery* query = [PFQuery queryWithClassName:@"Response"];
    [query whereKey:@"suggestion" equalTo:suggestion];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            [self showMessage:@"Not saved"];
        }
        else
        {
            PFObject* response;
            if(objects.count > 0)
            {
                response = objects.firstObject;
            }
            else
            {
                response = [PFObject objectWithClassName:@"Response"];
                response[@"user"] = [PFUser currentUser];
                response[@"suggestion"] = suggestion;
            }
            response[@"result"] = result;
            [response saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if(!succeeded) {
                    [self showMessage:@"Not saved"];
                }
            }];
        }
    }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.suggestions.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    PFObject* suggestion = self.suggestions[indexPath.row];
    if(self.topic[@"resultId"] && [self.topic[@"resultId"] isEqualToString:suggestion.objectId])
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"WinningResponseCell" forIndexPath:indexPath];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ResponseCell" forIndexPath:indexPath];
    }
    UILabel* label = (UILabel*)[cell viewWithTag:42];
    UISegmentedControl* segmentControl = (UISegmentedControl*)[cell viewWithTag:69];
    label.text = suggestion[@"title"];
    PFObject* response = self.responses[suggestion.objectId];
    if(response) {
        NSUInteger index = -1;
        NSString* result = response[@"result"];
        for(NSUInteger i=0;i<3;i++)
        {
            if([result isEqualToString:responses[i]]) {
                index = i;
            }
        }
        if(index != -1)
        {
            [segmentControl setSelectedSegmentIndex:index];
        }
    }
    NSLog(@"Cell: %@", cell);
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
