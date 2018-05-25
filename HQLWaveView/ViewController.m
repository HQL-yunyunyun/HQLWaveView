//
//  ViewController.m
//  HQLWaveView
//
//  Created by 何启亮 on 2018/5/17.
//  Copyright © 2018年 hql_personal_team. All rights reserved.
//

#import "ViewController.h"
#import "HQLWaveView.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;

@property (nonatomic, weak) IBOutlet HQLWaveView *waveView;

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (weak, nonatomic) IBOutlet UIButton *startAnimationButton;
@property (weak, nonatomic) IBOutlet UIButton *stopAnimationButton;
@property (weak, nonatomic) IBOutlet UIButton *startRecordButton;
@property (weak, nonatomic) IBOutlet UIButton *stopRecordButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupWaveView];
    [self setupRecorder];
}

- (void)setupWaveView {
    __weak typeof(self) _self = self;
    self.waveView.waveLevelCallback = ^CGFloat(HQLWaveView *waveView) {
        
        if (!_self.recorder.isRecording) { // 没有在录音
            return 0.1;
        }
        [_self.recorder updateMeters];
        
        CGFloat level = pow(10, [_self.recorder averagePowerForChannel:0] / 40);
        
        return level;
    };
}

- (IBAction)startButtonClick:(id)sender {
    [self.waveView startAnimate];
}

- (IBAction)startAnimationButtonClick:(id)sender {
    [self.waveView startAnimateWithOpeningAnimation];
}

- (IBAction)stopAnimationButtonClick:(id)sender {
    [self.waveView stopAnimateWithEndingAnimation];
}

- (IBAction)stopButtonClick:(id)sender {
    [self.waveView stopAnimate];
}

- (IBAction)startRecordButtonClic:(id)sender {
    if (self.recorder.isRecording) {
        return;
    }
    
    [self.recorder prepareToRecord];
    [self.recorder setMeteringEnabled:YES];
    [self.recorder record];
}

- (IBAction)stopRecordButtonClick:(id)sender {
    [self.recorder stop];
}


-(void)setupRecorder
{
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    
    NSDictionary *settings = @{AVSampleRateKey:          [NSNumber numberWithFloat: 44100.0],
                               AVFormatIDKey:            [NSNumber numberWithInt: kAudioFormatAppleLossless],
                               AVNumberOfChannelsKey:    [NSNumber numberWithInt: 2],
                               AVEncoderAudioQualityKey: [NSNumber numberWithInt: AVAudioQualityMin]};
    
    NSError *error;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    
    if(error) {
        NSLog(@"Ups, could not create recorder %@", error);
        return;
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
    }
}

@end
