//
//  BBSettingView.m
//  BreakBricks
//
//  Created by 王梦杰 on 16/1/21.
//  Copyright (c) 2016年 Mooney_wang. All rights reserved.
//

#import "BBSettingView.h"

@implementation BBSettingView

- (id)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        
    }
    return self;
}

- (IBAction)levelChange:(UISegmentedControl *)sender {
    if ([self.delegate respondsToSelector:@selector(settingViewDidChangedLevel:)]) {
        [self.delegate settingViewDidChangedLevel:sender];
    }
}

- (IBAction)musicSwitchChange:(UISwitch *)sender {
    if ([self.delegate respondsToSelector:@selector(settingViewDidChangedMusicSwitch:)]) {
        [self.delegate settingViewDidChangedMusicSwitch:sender];
    }
}
@end
