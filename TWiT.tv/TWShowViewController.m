//
//  TWShowViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/2/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWShowViewController.h"
#import "TWEpisodeViewController.h"
#import "TWEpisodeCell.h"

@implementation TWShowViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // TODO: Configure header view
    
    [self.descLabel setText:@"Now that there is the Tec-9, a crappy spray gun from South Miami. This gun is advertised as the most popular gun in American crime. Do you believe that shit? It actually says that in the little book that comes with it: the most popular gun in American crime. Like they're actually proud of that shit."];
    
    CGSize maxSize = CGSizeMake(self.descLabel.frame.size.width, CGFLOAT_MAX);
    CGSize size = [self.descLabel.text sizeWithFont:self.descLabel.font constrainedToSize:maxSize];
    CGRect frame = self.descLabel.frame;
    frame.size.height = size.height;
    self.descLabel.frame = frame;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView addObserver:self forKeyPath:@"contentOffset"
                        options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)
                        context:NULL];
}

#pragma mark - Actions

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"episodeDetail"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
        [segue.destinationViewController setDetailItem:object];
    }
}

- (IBAction)openDetailView:(UIButton*)sender
{
    if(self.tableView.contentOffset.y <= -self.view.bounds.size.height+headerHeight)
    {
        self.tableView.scrollEnabled = YES;
        [UIView animateWithDuration:0.3f animations:^
        {
            self.tableView.contentOffset = CGPointMake(0, 0);
            sender.transform = CGAffineTransformMakeRotation(0);
            [sender setImage:[UIImage imageNamed:@"toolbar-disclose"] forState:UIControlStateNormal];
        }];
    }
    else
    {
        self.tableView.scrollEnabled = NO;
        [UIView animateWithDuration:0.3f animations:^
        {
            self.tableView.contentOffset = CGPointMake(0, -self.view.bounds.size.height+headerHeight);
            sender.transform = CGAffineTransformMakeRotation(M_PI);
            [sender setImage:[UIImage imageNamed:@"toolbar-disclose-up"] forState:UIControlStateNormal];
        }];
    }
}

#pragma mark - Table

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    
    CGPoint newPoint = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
    
    if(object == self.tableView)
    {
        if(newPoint.y < 0)
        {
            CGRect frame = self.headerView.frame;
            frame.origin.y = newPoint.y;
            frame.size.height = ceilf(headerHeight-newPoint.y);
            self.headerView.frame = frame;
            
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(frame.size.height, 0, 0, 1);
        }
        else
        {
            CGRect frame = self.headerView.frame;
            frame.origin.y = 0;
            frame.size.height = headerHeight;
            self.headerView.frame = frame;
            
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(headerHeight, 0, 0, 1);
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchedEpisodesController.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo>sectionInfo = self.fetchedEpisodesController.sections[section];
    return sectionInfo.numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"episodeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(!cell)
        cell = [[TWEpisodeCell alloc] initWithStyle:NO reuseIdentifier:identifier];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark - Configure

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    if([cell.reuseIdentifier isEqualToString:@"episodeCell"])
    {
        NSManagedObject *object = [self.fetchedEpisodesController objectAtIndexPath:indexPath];
        ((TWEpisodeCell*)cell).numberLabel.text = @"11";
        ((TWEpisodeCell*)cell).titleLabel.text = [[object valueForKey:@"timeStamp"] description];
        ((TWEpisodeCell*)cell).subtitleLabel.text = @"subtitle";
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController*)fetchedEpisodesController
{
    if(_fetchedEpisodesController != nil)
        return _fetchedEpisodesController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:10];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedEpisodesController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedEpisodesController.delegate = self;
    self.fetchedEpisodesController = aFetchedEpisodesController;
    
	NSError *error = nil;
	if(![self.fetchedEpisodesController performFetch:&error])
    {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    return _fetchedEpisodesController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController*)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if(controller == self.fetchedEpisodesController)
    {
        switch(type)
        {
            case NSFetchedResultsChangeInsert:
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
}

- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath*)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    if(controller == self.fetchedEpisodesController)
    {
        switch(type)
        {
            case NSFetchedResultsChangeInsert:
                [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeDelete:
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            case NSFetchedResultsChangeUpdate:
                [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
                break;
                
            case NSFetchedResultsChangeMove:
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView endUpdates];
}

#pragma mark - Kill

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.tableView removeObserver:self forKeyPath:@"contentOffset"];
    
    [super viewWillDisappear:animated];
}

@end
