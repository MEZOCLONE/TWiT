//
//  TWShowsViewController.m
//  TWiT.tv
//
//  Created by Stuart Moore on 11/10/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import "TWShowsViewController.h"
#import "TWSplitViewContainer.h"
#import "TWWatchListController.h"
#import "TWShowViewController.h"
#import "TWStreamViewController.h"

#import "TWShowCell.h"
#import "TWLargeHeaderCell.h"
#import "TWPlayButton.h"

#import "Channel.h"
#import "Show.h"
#import "Poster.h"

#define NAVBAR_INSET 64

@interface TWShowsViewController ()

@end

@implementation TWShowsViewController

- (void)viewDidLoad
{
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(albumArtDidChange:)
                                               name:@"albumArtDidChange"
                                             object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(redrawSchedule:)
                                               name:@"ScheduleDidUpdate"
                                             object:self.channel.schedule];
    
    self.headerView.translatesAutoresizingMaskIntoConstraints = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self redrawSchedule:nil];
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        UIImage *backIcon = [[UIImage imageNamed:@"navbar-back-twit-icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.navigationItem.backBarButtonItem = [UIBarButtonItem.alloc initWithImage:backIcon
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:nil
                                                                              action:nil];
    }
}

#pragma mark - Actions

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
    Show *selectedShow = [self.fetchedShowsController objectAtIndexPath:indexPath];
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [self performSegueWithIdentifier:@"showDetail" sender:selectedShow];
    }
    else
    {
        TWSplitViewContainer *splitViewContainer = (TWSplitViewContainer*)self.view.window.rootViewController;
        UINavigationController *masterController = (UINavigationController*)splitViewContainer.masterController;
        
        if(masterController.viewControllers.count > 1)
        {
            TWShowViewController *showController = (TWShowViewController*)masterController.topViewController;
            Show *currentShow = showController.show;
            
            if(currentShow == selectedShow)
            {
                // Crashes
                //self.showSelectedView = nil;
                //[masterController popToRootViewControllerAnimated:YES];
            }
            else
            {
                /*
                CGRect frame = [showCell frameForColumn:column];
                frame = [showCell convertRect:frame toView:self.tableView];
                frame = CGRectInset(frame, -11, -11);
                frame.origin.y += 1;
                self.showSelectedView.frame = frame;
                self.showSelectedView.tag = index;
                */
                
                [selectedShow updateEpisodes];
                showController.show = selectedShow;
                
                [showController.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
            }
        }
        else
        {
            /*
            CGRect frame = [showCell frameForColumn:column];
            frame = [showCell convertRect:frame toView:self.tableView];
            frame = CGRectInset(frame, -11, -11);
            frame.origin.y += 1;
          
            self.showSelectedView = self.showSelectedView ?: [[UIImageView alloc] init];
            self.showSelectedView.frame = frame;
            self.showSelectedView.tag = index;
            */
            
            TWWatchListController *episodesController = (TWWatchListController*)masterController.topViewController;
            [episodesController performSegueWithIdentifier:@"showDetail" sender:selectedShow];
        }
    }
}

#pragma mark - Notifications

- (void)redrawSchedule:(NSNotification*)notification
{
    BOOL didSucceed = [notification.userInfo[@"scheduleDidSucceed"] boolValue];
    
    if(!didSucceed)
    {
        self.headerView.liveTimeLabel.text = @"Sorry";
        self.headerView.liveTitleLabel.text = @"Unable To Load Schedule";
        self.headerView.nextTimeLabel.text = @"What?";
        self.headerView.nextTitleLabel.text = @"Don’t ask me, it’s your Internet.";
        return;
    }
    
    if(!self.channel.schedule || self.channel.schedule.days.count == 0)
        return;
    
    Event *currentShow = self.channel.schedule.currentShow;
    
    Show *show = currentShow.show ?: self.channel.shows.anyObject;
    self.headerView.livePosterView.image = show.poster.image;
    
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        self.headerView.liveTimeLabel.text = currentShow.until;
        self.headerView.liveTitleLabel.text = currentShow.title;
        
        Event *nextShow = [self.channel.schedule showAfterShow:currentShow];
        self.headerView.nextTimeLabel.text = [nextShow untilStringWithPrevious:currentShow];
        self.headerView.nextTitleLabel.text = nextShow.title;
        
        self.headerView.liveAlbumArtView.image = currentShow.show ? currentShow.show.albumArt.image : [UIImage imageNamed:@"generic.jpg"];
        self.headerView.playButton.percentage = currentShow.percentageElapsed;
    }
    
    // TODO: Optimize
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(redrawSchedule:) object:nil];
    [self performSelector:@selector(redrawSchedule:) withObject:nil afterDelay:60];
}

- (void)albumArtDidChange:(NSNotification*)notification
{
}

#pragma mark - Collection View

- (void)scrollViewDidScroll:(UIScrollView*)scrollView
{
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    CGFloat headerHeight = 180;
    
    if(self.headerView && scrollView == self.collectionView)
    {
        CGRect frame = self.headerView.frame;
        CGFloat sectionHeaderHeight = (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? 28 : 0;
        
        if(scrollView.contentOffset.y < -NAVBAR_INSET)
        {
            frame.origin.y = scrollView.contentOffset.y + NAVBAR_INSET;
            frame.size.height = ceilf(headerHeight - scrollView.contentOffset.y - NAVBAR_INSET);
        }
        else
        {
            frame.origin.y = 0;
            frame.size.height = headerHeight;
        }
        
        self.headerView.frame = frame;
        
        UIEdgeInsets scrollerInsets = self.collectionView.scrollIndicatorInsets;
        scrollerInsets.top = frame.size.height + sectionHeaderHeight + NAVBAR_INSET;
        self.collectionView.scrollIndicatorInsets = scrollerInsets;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
    if(collectionView == self.collectionView)
    {
        return self.fetchedShowsController.sections.count;
    }
    
    return 0;
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    if(collectionView == self.collectionView)
    {
        id <NSFetchedResultsSectionInfo>sectionInfo;
        sectionInfo = self.fetchedShowsController.sections[section];
        
        return sectionInfo.numberOfObjects;
    }
    
    return 0;
}

- (UICollectionReusableView*)collectionView:(UICollectionView*)collectionView viewForSupplementaryElementOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath
{
    TWLargeHeaderCell *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader)
    {
        TWLargeHeaderCell *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                           withReuseIdentifier:@"liveHeader" forIndexPath:indexPath];
        
        
        
        reusableview = headerView;
        self.headerView = headerView;
    }
    
    return reusableview;
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
    NSString *identifier = @"showCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    cell.backgroundColor = UIColor.clearColor;
    
    return cell;
}

- (void)configureCell:(UICollectionViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    Show *show = [self.fetchedShowsController objectAtIndexPath:indexPath];
    TWShowCell *showCell = (TWShowCell*)cell;
    
    showCell.show = show;
    self.accessibilityLabel = show.title;
}

#pragma mark - Fetched Results Controller

- (NSFetchedResultsController*)fetchedShowsController
{
    if(_fetchedShowsController != nil)
        return _fetchedShowsController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Show" inManagedObjectContext:self.managedObjectContext];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sort" ascending:YES];
    
    [fetchRequest setFetchBatchSize:15];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                 managedObjectContext:self.managedObjectContext
                                                                                   sectionNameKeyPath:nil cacheName:nil];
    controller.delegate = self;
    self.fetchedShowsController = controller;
    
	NSError *error = nil;
	if(![self.fetchedShowsController performFetch:&error])
    {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	}
    
    return _fetchedShowsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
}

- (void)controller:(NSFetchedResultsController*)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
}

- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath*)newIndexPath
{
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
}

#pragma mark - Setttings

- (NSUInteger)supportedInterfaceOrientations
{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    else
        return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"showDetail"])
    {
        NSIndexPath *indexPath = (NSIndexPath*)sender;
        Show *show = [self.fetchedShowsController objectAtIndexPath:indexPath];
        [show updateEpisodes];
        
        if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
            [segue.destinationViewController setSplitViewContainer:self.splitViewContainer];
        
        [segue.destinationViewController setShow:show];
    }
    else if([segue.identifier isEqualToString:@"scheduleView"])
    {
        [segue.destinationViewController setSchedule:self.channel.schedule];
    }
    else if([segue.identifier isEqualToString:@"liveVideoDetail"])
    {
        [segue.destinationViewController setStream:[self.channel streamForType:TWTypeVideo]];
    }
}
    
@end