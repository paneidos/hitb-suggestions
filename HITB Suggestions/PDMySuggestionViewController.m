//
//  PDMySuggestionViewController.m
//  HITB Suggestions
//
//  Created by Sernin van de Krol on 29/05/14.
//  Copyright (c) 2014 Paneidos Desu. All rights reserved.
//

#import "PDMySuggestionViewController.h"

#import "PDFriendsTableViewController.h"

#import "PDResponseTableViewController.h"

@interface PDMySuggestionViewController () <UIAlertViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) NSArray* suggestions;
@property (nonatomic, strong) NSMutableDictionary* responses;

@end

@implementation PDMySuggestionViewController

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
-(void)viewWillAppear:(BOOL)animated
{
    [self loadResponses];
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
        self.suggestions = @[];
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
            NSLog(@"Suggestions: %@", objects);
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
    [query includeKey:@"suggestion"];
    [query whereKey:@"suggestion" matchesQuery:suggestionQuery];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(error)
        {
            [self showMessage:@"Error loading responses"];
        }
        else
        {
            NSMutableDictionary* responses = [NSMutableDictionary dictionary];
            NSLog(@"Responses: %@", objects);
            for(PFObject* response in objects) {
                NSLog(@"R: %@", response);
                PFObject* suggestion = response[@"suggestion"];
                NSString* suggestionId = suggestion.objectId;
                NSString* resultKey = response[@"result"];
                if(!responses[suggestionId])
                {
                    responses[suggestionId] = [NSMutableDictionary dictionaryWithDictionary:@{ @"yes": @0, @"no": @0, @"maybe": @0 }];
                }
                responses[suggestionId][resultKey] = [NSNumber numberWithInt:([responses[suggestionId][resultKey] intValue] + 1)];
                NSLog(@"Value: %@", responses[suggestionId][resultKey]);
            }
            self.responses = responses;
            NSLog(@"Responses: %@", self.responses);
            [self.tableView reloadData];
            
        }
    }];
}

-(IBAction)addItem:(id)sender
{
    
    UIAlertView* newSuggestionView = [[UIAlertView alloc] initWithTitle:@"New suggestion" message:@"Enter the suggestion" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
    newSuggestionView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [newSuggestionView show];
}

-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    
    if(buttonIndex != 0)
    {
        PFObject* newSuggestion = [PFObject objectWithClassName:@"Suggestion"];
        newSuggestion[@"title"] = [alertView textFieldAtIndex:0].text;
        newSuggestion[@"topic"] = self.topic;
        [newSuggestion saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(!succeeded)
            {
                [self showMessage:@"Failed to add suggestion"];
            }
            else
            {
                [self loadItems];
            }
        }];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
    {
        PFObject* suggestion = self.suggestions[self.tableView.indexPathForSelectedRow.row];
        self.topic[@"result"] = suggestion[@"title"];
        self.topic[@"resultId"] = suggestion.objectId;
        [self.topic saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if(!succeeded)
            {
                [self showMessage:@"Failed to save"];
            }
            else
            {
                [self loadItems];
            }
        }];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        return @"Actions";
    }
    else
    {
        return @"Suggestions";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
    {
        return 2;
    }
    else
    {
        return self.suggestions.count;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section != 0)
    {
        UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"Pick this one?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Pick this one", nil];
        [actionSheet showInView:self.view];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell;
    if(indexPath.section == 0)
    {
        if(indexPath.row == 0)
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"inviteFriendsCell" forIndexPath:indexPath];
        }
        else
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"submitResponseCell" forIndexPath:indexPath];
        }
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"SuggestionCell" forIndexPath:indexPath];
        PFObject* suggestion = self.suggestions[indexPath.row];
        cell.textLabel.text = suggestion[@"title"];
        if(self.topic[@"resultId"] && [self.topic[@"resultId"] isEqualToString:suggestion.objectId])
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        NSDictionary* dict;
        if((dict = self.responses[suggestion.objectId]))
        {
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Yes: %@, Maybe: %@, No: %@", dict[@"yes"], dict[@"maybe"], dict[@"no"]];
        }
        else
        {
            cell.detailTextLabel.text = @"No responses";
        }
    }
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
    if([segue.identifier isEqualToString:@"friends"])
    {
        PDFriendsTableViewController* viewController = segue.destinationViewController;
        viewController.topic = self.topic;
    }
    else if([segue.identifier isEqualToString:@"submitResponse"])
    {
        PDResponseTableViewController* viewController = segue.destinationViewController;
        viewController.topic = self.topic;
    }
}

@end
