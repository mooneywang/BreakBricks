//
//  BBSettingView.h
//  BreakBricks
//
//  Created by 王梦杰 on 16/1/21.
//  Copyright (c) 2016年 Mooney_wang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BBSettingViewDelegate <NSObject>

@optional
- (void)settingViewDidChangedLevel:(UISegmentedControl *)sender;
- (void)settingViewDidChangedMusicSwitch:(UISwitch *)sender;

@end

@interface BBSettingView : UIView

@property(nonatomic ,weak)id<BBSettingViewDelegate> delegate;

- (IBAction)levelChange:(UISegmentedControl *)sender;

@property (weak, nonatomic) IBOutlet UISwitch *musicSwitch;

- (IBAction)musicSwitchChange:(UISwitch *)sender;


@end
