//
//  ViewController.m
//  SlidePuzzle
//
//  Created by Ryosuke Sasaki on 2013/02/16.
//  Copyright (c) 2013年 Ryosuke Sasaki. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+Cropping.h"

static NSInteger const kNumberOfRows = 4;
static NSInteger const kNumberOfColumns = 4;
static NSInteger const kNumberOfPieces = kNumberOfColumns * kNumberOfRows - 1;
//空白を作るために-1。
@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIButton *chooseImageButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) NSArray *pieceViews;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDate *startDate;
@property (assign, nonatomic) CGPoint pointOfBlank;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSMutableArray *pieceViews = [NSMutableArray array];
    for (NSInteger i = 0; i < kNumberOfPieces; i++) {
        UIImageView *pieceView = [[UIImageView alloc] init];
        [self.mainView addSubview:pieceView];
        [pieceViews addObject:pieceView];
    }
    self.pieceViews = pieceViews;
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.mainView.bounds];
    [self.mainView addSubview:imageView];
    self.imageView = imageView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Convenience Methods
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////

- (CGRect)pieceFrameAtIndex:(NSInteger)index
{
    CGPoint point = [self pointFromIndex:index];
    CGFloat width = self.mainView.frame.size.width / kNumberOfColumns;
    CGFloat height = self.mainView.frame.size.height / kNumberOfRows;
    return CGRectMake(point.x * width, point.y * height, width, height);
}

- (CGPoint)pointFromIndex:(NSInteger)index
{
    return CGPointMake(index % kNumberOfColumns, index / kNumberOfColumns);
}

- (NSInteger)indexFromPoint:(CGPoint)point
{
    return point.y * kNumberOfColumns + point.x;
}

- (BOOL)canMovePieceFromPoint:(CGPoint)point
{
    if (CGPointEqualToPoint(self.pointOfBlank, point))
        return NO;
    
    return self.pointOfBlank.x == point.x || self.pointOfBlank.y == point.y;
}

- (void)movePieceFromPoint:(CGPoint)point withAnimation:(BOOL)animation
{
    if (![self canMovePieceFromPoint:point])
        return;
    
    NSInteger step;
    if (self.pointOfBlank.x == point.x)
        step = self.pointOfBlank.y > point.y ? kNumberOfColumns : -kNumberOfColumns;
    else
        step = self.pointOfBlank.x > point.x ? 1 : -1;
    
    NSInteger indexOfBlank = [self indexFromPoint:self.pointOfBlank];
    NSMutableArray *targetPieceViews = [NSMutableArray array];
    NSInteger index = [self indexFromPoint:point];
    while (index != indexOfBlank) {
        for (UIImageView *pieceView in self.pieceViews) {
            if (pieceView.tag == index) {
                [targetPieceViews addObject:pieceView];
                break;
            }
        }
        index += step;
    }
    
    [UIView animateWithDuration:animation ? 0.2f : 0 animations:^{
        for (UIImageView *pieceView in targetPieceViews) {
            pieceView.tag += step;
            pieceView.frame = [self pieceFrameAtIndex:pieceView.tag];
        }
    }];
    
    self.pointOfBlank = point;
}

- (BOOL)isSolved
{
    for (NSInteger i = 0; i < kNumberOfPieces; i++) {
        UIImageView *pieceView = self.pieceViews[i];
        if (i != pieceView.tag)
            return NO;
    }
    
    return YES;
}

- (BOOL)isPlaying
{
    return self.imageView.hidden;
}

- (void)updateTimeLabel
{
    if (![self isPlaying])
        return;
    
    NSUInteger time = (NSUInteger)[[NSDate date] timeIntervalSinceDate:
                                   self.startDate];
    
    NSUInteger hour = time / (60 * 60);
    NSUInteger minute = (time % (60 * 60)) / 60;
    NSUInteger second = (time % (60 * 60)) % 60;
    
    self.timeLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",
                           hour, minute, second];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Event
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (![self isPlaying])
        return;
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self.mainView];
    if (CGRectContainsPoint(self.mainView.bounds, location)) {
        CGFloat width = self.mainView.frame.size.width / kNumberOfColumns;
        CGFloat height = self.mainView.frame.size.height / kNumberOfRows;
        CGPoint point = CGPointMake((int)(location.x / width), (int)(location.y / height));
        
        [self movePieceFromPoint:point withAnimation:YES];
        
        if ([self isSolved]) {
            [self.timer invalidate];
            self.timer = nil;
            
            self.imageView.hidden = NO;
            [UIView animateWithDuration:0.5f animations:^{
                self.imageView.alpha = 1;
            } completion:^(BOOL finished) {
                NSString *title = @"ゲームクリア！";
                NSString *message = [NSString stringWithFormat:
                                     @"タイムは %@ です", self.timeLabel.text];
                [[[UIAlertView alloc] initWithTitle:title
                                           message:message
                                          delegate:nil
                                 cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            }];
        }
    }
}

- (IBAction)performChooseImageButtonAction:(id)sender
{
    if ([self isPlaying])
        return;
    
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    controller.allowsEditing = YES;
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)performStartButtonAction:(id)sender
{
    if ([self isPlaying])
        return;
    
    [UIView animateWithDuration:0.5f animations:^{
        self.imageView.alpha = 0;
    } completion:^(BOOL finished) {
        self.imageView.hidden = YES;
    }];
    
    srand(time(0));
    for (NSInteger i = 0; i < 100; i++) {
        NSInteger index = rand() % kNumberOfPieces;
        CGPoint point = [self pointFromIndex:index];
        [self movePieceFromPoint:point withAnimation:NO];
    }
    
    self.startDate = [NSDate date];
    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                  target:self
                                                selector:@selector(updateTimeLabel)
                                                userInfo:nil
                                                 repeats:YES];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIImagePickerControllerDelegate
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    
    self.imageView.image = image;
    
    CGFloat width = image.size.width / kNumberOfColumns;
    CGFloat height = image.size.height / kNumberOfRows;
    
    for (NSInteger i = 0; i < kNumberOfPieces; i++) {
        CGFloat x = (i % kNumberOfColumns) * width;
        CGFloat y = (i / kNumberOfColumns) * height;
        CGRect rect = CGRectMake(x, y, width, height);
        UIImage *croppedImage = [image croppedImageInRect:rect];
        
        UIImageView *pieceView = self.pieceViews[i];
        pieceView.frame = [self pieceFrameAtIndex:i];
        pieceView.image = croppedImage;
        pieceView.tag = i;
    }
    self.pointOfBlank = CGPointMake(kNumberOfColumns - 1, kNumberOfRows);
    self.startButton.hidden = NO;
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
