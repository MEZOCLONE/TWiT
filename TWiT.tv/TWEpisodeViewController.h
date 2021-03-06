//
//  TWEpisodeViewController.h
//  TWiT.tv
//
//  Created by Stuart Moore on 12/29/12.
//  Copyright (c) 2012 Stuart Moore. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Episode, TWPlayButton, TWSegmentedButton, TWSplitViewContainer;

@interface TWEpisodeViewController : UIViewController <UIActionSheetDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) TWSplitViewContainer *splitViewContainer;
@property (strong, nonatomic) Episode *episode;

@property (weak, nonatomic) IBOutlet UIImageView *posterView;
@property (weak, nonatomic) IBOutlet TWPlayButton *playButton;
@property (weak, nonatomic) IBOutlet UIView *gradientView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel, *timeLabel, *numberLabel, *guestsLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet TWSegmentedButton *segmentedButton;

@property (nonatomic) BOOL unlockRotation;

- (void)configureView;

- (void)watchPressed:(TWSegmentedButton*)sender;
- (void)listenPressed:(TWSegmentedButton*)sender;
- (void)downloadPressed:(TWSegmentedButton*)sender;
- (void)updateProgress:(NSNotification*)notification;
- (void)cancelPressed:(TWSegmentedButton*)sender;
- (void)deletePressed:(TWSegmentedButton*)sender;

@end
