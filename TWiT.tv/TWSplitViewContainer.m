//
//  TWSplitViewContainer.m
//  TWiT.tv
//
//  Created by Stuart Moore on 1/9/13.
//  Copyright (c) 2013 Stuart Moore. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "TWAppDelegate.h"
#import "TWSplitViewContainer.h"
#import "TWMainViewController.h"
#import "TWEpisodeViewController.h"
#import "TWPlaybarViewController.h"

#import "TWEnclosureViewController.h"
#import "TWStreamViewController.h"

@implementation TWSplitViewContainer

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"masterEmbed"])
    {
        _masterController = segue.destinationViewController;
        TWMainViewController *episodesController = (TWMainViewController*)self.masterController.topViewController;
        episodesController.splitViewContainer = self;
    }
    else if([segue.identifier isEqualToString:@"detailEmbed"])
    {
        _detailController = segue.destinationViewController;
        TWMainViewController *showsController = (TWMainViewController*)self.detailController.topViewController;
        showsController.splitViewContainer = self;
    }
    else if([segue.identifier isEqualToString:@"modalEmbed"])
    {
        _modalController = segue.destinationViewController;
        TWEpisodeViewController *episodeController = (TWEpisodeViewController*)self.modalController.topViewController;
        episodeController.splitViewContainer = self;
    }
    else if([segue.identifier isEqualToString:@"barEmbed"])
    {
        _playbarController = segue.destinationViewController;
        self.playbarController.splitViewContainer = self;
    }
}

#pragma mark - Movements
#pragma mark Playbar

- (void)showPlaybar
{
    if(!self.playbarContainer.hidden)
        return;
    
    [(TWPlaybarViewController*)self.playbarController updateView];
    CGFloat height = self.playbarContainer.frame.size.height + 4 + 4;
    
    UITableViewController *episodesTableViewController = (UITableViewController*)self.masterController.topViewController;
    UITableViewController *showsTableViewController = (UITableViewController*)self.detailController.topViewController;
    
    
    UIEdgeInsets insets = episodesTableViewController.tableView.contentInset;
    insets.bottom = height;
    episodesTableViewController.tableView.contentInset = insets;
    
    insets = episodesTableViewController.tableView.scrollIndicatorInsets;
    insets.bottom = height;
    episodesTableViewController.tableView.scrollIndicatorInsets = insets;
    
    
    insets = showsTableViewController.tableView.contentInset;
    insets.bottom = height;
    showsTableViewController.tableView.contentInset = insets;
    
    insets = showsTableViewController.tableView.scrollIndicatorInsets;
    insets.bottom = height;
    showsTableViewController.tableView.scrollIndicatorInsets = insets;
    
    
    CGRect modalFrame = self.modalFlyout.frame;
    modalFrame.size.height = self.modalContainer.bounds.size.height-height;
    self.modalFlyout.frame = modalFrame;
    
    self.playbarContainer.alpha = 0;
    self.playbarContainer.hidden = NO;
    [UIView animateWithDuration:0.3f animations:^{
        self.playbarContainer.alpha = 1;
    } completion:^(BOOL fin){
    }];
    
    TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    [NSNotificationCenter.defaultCenter addObserver:self.playbarController
                                           selector:@selector(playerStateChanged:)
                                               name:MPMoviePlayerPlaybackStateDidChangeNotification
                                             object:delegate.player];
}

- (void)hidePlaybar
{
    if(self.playbarContainer.hidden)
        return;
    
    CGFloat height = 0;
    
    UITableViewController *episodesTableViewController = (UITableViewController*)self.masterController.topViewController;
    UITableViewController *showsTableViewController = (UITableViewController*)self.detailController.topViewController;
    
    
    UIEdgeInsets insets = episodesTableViewController.tableView.contentInset;
    insets.bottom = height;
    episodesTableViewController.tableView.contentInset = insets;
    
    insets = episodesTableViewController.tableView.scrollIndicatorInsets;
    insets.bottom = height;
    episodesTableViewController.tableView.scrollIndicatorInsets = insets;
    
    
    insets = showsTableViewController.tableView.contentInset;
    insets.bottom = height;
    showsTableViewController.tableView.contentInset = insets;
    
    insets = showsTableViewController.tableView.scrollIndicatorInsets;
    insets.bottom = height;
    showsTableViewController.tableView.scrollIndicatorInsets = insets;
    
    
    CGRect modalFrame = self.modalFlyout.frame;
    modalFrame.size.height = self.modalContainer.bounds.size.height;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.playbarContainer.alpha = 0;
    } completion:^(BOOL fin){
        self.playbarContainer.hidden = YES;
        self.playbarContainer.alpha = 1;
        self.modalFlyout.frame = modalFrame;
    }];
    
    TWAppDelegate *delegate = (TWAppDelegate*)UIApplication.sharedApplication.delegate;
    [NSNotificationCenter.defaultCenter removeObserver:self.playbarController
                                                  name:MPMoviePlayerPlaybackStateDidChangeNotification
                                                object:delegate.player];
}

#pragma mark Modal

- (void)showModalFlyout
{
    if(!self.modalContainer.hidden)
        return;
    
    self.modalBlackground.alpha = 0;
    self.modalContainer.hidden = NO;
    
    self.modalLeftContraint.constant = 0;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.modalBlackground.alpha = 1;
        [self.modalContainer layoutIfNeeded];
    }];
}

- (void)hideModalFlyout
{
    if(self.modalContainer.hidden)
        return;
    
    self.modalLeftContraint.constant = -448;
    
    [UIView animateWithDuration:0.3f animations:^{
        [self.modalContainer layoutIfNeeded];
        self.modalBlackground.alpha = 0;
    } completion:^(BOOL fin){
        self.modalContainer.hidden = YES;
        self.modalBlackground.alpha = 1;
    }];
}

#pragma mark - Actions

- (void)didTapModalBackground:(UITapGestureRecognizer*)recognizer
{
    [self hideModalFlyout];
    
    UITableViewController *tableController = (UITableViewController*)self.masterController.topViewController;
    [tableController.tableView deselectRowAtIndexPath:tableController.tableView.indexPathForSelectedRow animated:NO];
}

- (IBAction)didPanModalFlyout:(UIPanGestureRecognizer*)recognizer
{
    if(recognizer.state == UIGestureRecognizerStateBegan)
    {
    }
    else if(recognizer.state == UIGestureRecognizerStateChanged)
    {
        CGFloat x = [recognizer translationInView:self.modalFlyout].x;
        
        self.modalLeftContraint.constant = MIN(0, MAX(x, -448));
        [self.modalContainer layoutIfNeeded];
        
        self.modalBlackground.alpha = MAX(0, x / self.modalFlyout.frame.size.width + 1);
    }
    else if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        CGFloat speed = [recognizer velocityInView:self.modalFlyout].x;
        
        if(self.modalFlyout.frame.origin.x > self.modalFlyout.frame.size.width/2
        || self.modalFlyout.frame.origin.x < -self.modalFlyout.frame.size.width/2
        || fabs(speed) > 1000)
        {
            [self hideModalFlyout];
            
            UITableViewController *tableController = (UITableViewController*)self.masterController.topViewController;
            [tableController.tableView deselectRowAtIndexPath:tableController.tableView.indexPathForSelectedRow animated:YES];
        }
        else
        {
            self.modalLeftContraint.constant = 0;
            
            [UIView animateWithDuration:0.3f animations:^{
                self.modalBlackground.alpha = 1;
                [self.modalContainer layoutIfNeeded];
            }];
        }
    }
}

#pragma mark - Settings

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    UIViewController *controller = self.childViewControllers.lastObject;
    
    if(![controller isKindOfClass:TWEnclosureViewController.class]
    && ![controller isKindOfClass:TWStreamViewController.class])
        return super.preferredStatusBarStyle;
    
    if([controller respondsToSelector:@selector(preferredStatusBarStyle)])
        return controller.preferredStatusBarStyle;
    else
        return super.preferredStatusBarStyle;
}

- (BOOL)prefersStatusBarHidden
{
    UIViewController *controller = self.childViewControllers.lastObject;
    
    if(![controller isKindOfClass:TWEnclosureViewController.class]
    && ![controller isKindOfClass:TWStreamViewController.class])
        return super.preferredStatusBarStyle;
    
    if([controller respondsToSelector:@selector(prefersStatusBarHidden)])
        return controller.prefersStatusBarHidden;
    else
        return super.prefersStatusBarHidden;
}

@end
