//
//  BBViewController.m
//  BreakBricks
//
//  Created by 王梦杰 on 16/1/21.
//  Copyright (c) 2016年 Mooney_wang. All rights reserved.
//

#import "BBViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "BBSettingView.h"

enum BBlevelType {
    BBlevelTypeEasy = 1,
    BBlevelTypeHard,
    BBlevelTypeCreazy,
};
typedef enum BBlevelType BBlevelType;

@interface BBViewController () <BBSettingViewDelegate>
/**
 *  砖块
 */
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *bricks;

/**
 *  球
 */
@property (weak, nonatomic) IBOutlet UIView *ballView;
/**
 *  板
 */
@property (weak, nonatomic) IBOutlet UIView *paddle;
/**
 *  文字提示栏
 */
@property (weak, nonatomic) IBOutlet UILabel *labelView;

/**
 *  毛玻璃层
 */
@property(nonatomic ,strong)UIVisualEffectView *effectView;
/**
 *  设置界面
 */
@property(nonatomic ,strong)BBSettingView *setView;

/**
 *  游戏的难易
 */
@property(nonatomic, assign)BBlevelType levelType;

@end


@implementation BBViewController
{
    //滑板的初始位置
    CGPoint _originPaddleCenter;
    //小球的初始位置
    CGPoint _originBallCenter;
    //游戏时钟
    CADisplayLink *_displayLink;
    //屏幕点击手势
    UITapGestureRecognizer *_tapScreen;
    //小球的移动速度
    CGPoint _ballVelocity;
    //滑板的水平速度
    CGFloat _paddleVelocityX;
    //背景音乐播放器
    AVAudioPlayer *_audioPlayer;
}

-(UIVisualEffectView *)effectView{
    if (_effectView == nil) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        _effectView.frame = self.view.frame;
        _effectView.alpha = 0.9;
        UITapGestureRecognizer *tapEffect = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(effectTapped)];
        [_effectView addGestureRecognizer:tapEffect];
    }
    return _effectView;
}

- (void)effectTapped{
    [UIView animateWithDuration:1.0 animations:^{
        [self.setView removeFromSuperview];
        [self.effectView removeFromSuperview];
    }];
    
}

- (BBSettingView *)setView{
    if (_setView == nil) {
        _setView = [[[NSBundle mainBundle] loadNibNamed:@"BBSettingView" owner:nil options:nil] lastObject];
        _setView.bounds = CGRectMake(0, 0, 300, 200);
        _setView.center = CGPointMake(self.view.frame.size.width * 0.5, self.view.frame.size.height * 0.5);
        _setView.backgroundColor = [UIColor colorWithRed:1.000 green:0.940 blue:0.758 alpha:1.000];
        _setView.alpha = 0.0;
        _setView.layer.cornerRadius = 12;
        _setView.layer.masksToBounds = YES;
        _setView.delegate = self;
    }
    return _setView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //界面初始化
    [self viewConfig];
    //游戏设置初始化
    [self settingInit];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewConfig{
    //小球的初始位置
    _originBallCenter = self.ballView.center;
    //滑板的初始位置
    _originPaddleCenter = self.paddle.center;
    //小球
    self.ballView.layer.cornerRadius = 20;
    //板
    self.paddle.layer.cornerRadius = 15;
    //砖块
    for (UIView *brick in self.bricks) {
        //圆角
        brick.layer.cornerRadius = 12;
    }
    //屏幕点击手势
    _tapScreen = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenTapped)];
    [self.view addGestureRecognizer:_tapScreen];
    //拖拽滑板手势
    UIPanGestureRecognizer *panPaddle = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(paddlePanning:)];
    [self.paddle addGestureRecognizer:panPaddle];
    //屏幕双击手势
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenDoubleTapped)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
}

- (void)settingInit{
    //播放音乐
    [self musicOn];
    //简单
    self.levelType = BBlevelTypeEasy;
}

/**
 *  点击屏幕
 */
- (void)screenTapped{
    //禁用屏幕点击手势
    _tapScreen.enabled = NO;
    //显示砖块
    for (UIView *brick in self.bricks) {
        brick.hidden = NO;
    }
    //隐藏label
    self.labelView.hidden = YES;
    //设置小球的初始速度,默认x方向速度为0，y方向每次刷新屏幕向上移动5像素
    _ballVelocity = CGPointMake(0.0, - 5.0 * _levelType);
    //开启游戏时钟
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    //添加到runloop,此时就会开始不断调用update方法，每秒60次
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

//移动小球，刷新屏幕
- (void)update{
    NSLog(@"update");
    //碰撞检测
    [self intersectWithScreen];
    [self intersectWithPaddle];
    [self intersectWithBrick];
    //改变小球的位置
    self.ballView.center = CGPointMake(self.ballView.center.x + _ballVelocity.x, self.ballView.center.y + _ballVelocity.y);
}

/**
 *  拖拽滑板
 */
- (void)paddlePanning:(UIPanGestureRecognizer *)panGesture{
    //判读手指是否在移动，可以根据手势的state属性来判断
    /*
     * UIGestureRecognizerStateBegan    :开始移动
     * UIGestureRecognizerStateChanged  :移动中
     * UIGestureRecognizerStateEnded    :结束移动
     */
    if (panGesture.state == UIGestureRecognizerStateChanged) {//移动中
        //取出手指的点
        CGPoint currentPoint = [panGesture locationInView:self.view];
        //根据手指的移动修改滑板的位置
        self.paddle.center = CGPointMake(currentPoint.x, _originPaddleCenter.y);
        //记录滑板的水平速度
        _paddleVelocityX = [panGesture velocityInView:self.view].x;
        
    }else if (panGesture.state == UIGestureRecognizerStateEnded){//移动结束
        //滑板的水平速度清零
        _paddleVelocityX = 0.0;
    }
}

/**
 *  双击屏幕
 */
- (void)screenDoubleTapped{
    //透明毛玻璃层（ios8之后引进）
    [self.view addSubview:self.effectView];
    //设置层
    [self.view addSubview:self.setView];
    [UIView animateWithDuration:1.0 animations:^{
        _setView.alpha = 1.0;
    }];
}

#pragma mark - 碰撞检测

/**
 *  与屏幕碰撞
 */
- (void)intersectWithScreen{
    //与屏幕上边界碰撞
    if (CGRectGetMinY(self.ballView.frame) <= 0) {
        _ballVelocity.y = ABS(_ballVelocity.y);
    }
    
    //与屏幕左边界碰撞
    if (CGRectGetMinX(self.ballView.frame) <= 0) {
        _ballVelocity.x = ABS(_ballVelocity.x);
    }
    
    //与屏幕右边界碰撞
    if (CGRectGetMaxX(self.ballView.frame) >= self.view.frame.size.width) {
        _ballVelocity.x = - ABS(_ballVelocity.x);
    }
    
    //与屏幕下边界碰撞
    if (CGRectGetMinY(self.ballView.frame) >= self.view.frame.size.height) {
        //取消时钟
        [_displayLink invalidate];
        //显示你输了字样
        self.labelView.text = @"你输了~~~";
        self.labelView.hidden = NO;
        //启动点击手势
        _tapScreen.enabled = YES;
        //恢复小球和滑板的位置
        self.ballView.center = _originBallCenter;
        self.paddle.center = _originPaddleCenter;
    }
    
    BOOL win = YES;
    //遍历砖块，如果都没了，表示赢了
    for (UIView *brick in self.bricks) {
        //只要有一个还显示就表明没赢
        if (!brick.hidden) {
            win = NO;
            break;
        }
    }
    if (win) {
        //停止游戏时钟
        [_displayLink invalidate];
        //显示你赢了
        self.labelView.text = @"恭喜你赢了，点击屏幕再来一局";
        self.labelView.hidden = NO;
        //开启屏幕点击手势
        _tapScreen.enabled = YES;
    }
    
}

/**
 *  与滑板碰撞
 */
- (void)intersectWithPaddle{
    if (CGRectIntersectsRect(self.ballView.frame, self.paddle.frame)) {
        //改变小球的垂直方向
        _ballVelocity.y = - ABS(_ballVelocity.y);
        //将滑板的速度传递给小球的水平速度
        _ballVelocity.x = _paddleVelocityX / 100;
    }
}

/**
 *  与砖块碰撞
 */
- (void)intersectWithBrick{
    //遍历砖块
    for (UIView *brick in self.bricks) {
        //与砖块碰撞，并且该砖块显示在屏幕上
        if (CGRectIntersectsRect(brick.frame, self.ballView.frame) && !brick.hidden) {
            //砖块消失
            brick.hidden = YES;
            //小球改变方向
            _ballVelocity.y *= -1;
        }
    }
}

/**
 *  开启音乐
 */
- (void)musicOn{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"xunwei" withExtension:@"mp3"];
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [_audioPlayer play];
}

/**
 *  关闭音乐
 */
- (void)musicOff{
    [_audioPlayer pause];
    _audioPlayer = nil;
}

#pragma mark - BBSettingViewDelegate
- (void)settingViewDidChangedLevel:(UISegmentedControl *)sender{
    if (sender.selectedSegmentIndex == 0) {
        _levelType = BBlevelTypeEasy;
        _ballVelocity = CGPointMake(0.0, - 5.0 * _levelType);
    }else if (sender.selectedSegmentIndex == 1){
        _levelType = BBlevelTypeHard;
        _ballVelocity = CGPointMake(0.0, - 5.0 * _levelType);
    }else if (sender.selectedSegmentIndex == 2){
        _levelType = BBlevelTypeCreazy;
        _ballVelocity = CGPointMake(0.0, - 5.0 * _levelType);
    }
}

- (void)settingViewDidChangedMusicSwitch:(UISwitch *)sender{
    if (sender.isOn) {
        [self musicOn];
    }else{
        [self musicOff];
    }
}

@end
