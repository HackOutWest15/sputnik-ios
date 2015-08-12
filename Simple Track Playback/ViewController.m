/*
 Copyright 2015 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "Config.h"
#import "ViewController.h"
#import <Spotify/SPTDiskCache.h>

@interface ViewController () <SPTAudioStreamingDelegate>

@property NSUInteger *realOne;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverViewTL;
@property (weak, nonatomic) IBOutlet UIImageView *coverViewTR;
@property (weak, nonatomic) IBOutlet UIImageView *coverViewBL;
@property (weak, nonatomic) IBOutlet UIImageView *coverViewBR;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
@property int secondsLeft;

@property (nonatomic, strong) SPTAudioStreamingController *player;

@end

@implementation ViewController

- (void)runScheduledTask: (NSTimer *) runningTimer {
    self.secondsLeft--;
    self.timerLabel.text =[NSString stringWithFormat:@"%01d", self.secondsLeft];
    if (self.secondsLeft<=0) {
        NSLog(@"wtf");
        [self fastForward:(nil)];
    }
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.titleLabel.text = @"Nothing Playing";
    self.albumLabel.text = @"";
    self.artistLabel.text = @"";
    self.coverViewTR.contentMode = UIViewContentModeScaleAspectFit;
    self.coverViewTL.contentMode = UIViewContentModeScaleAspectFit;
    self.coverViewBL.contentMode = UIViewContentModeScaleAspectFit;
    self.coverViewBR.contentMode = UIViewContentModeScaleAspectFit;
    self.secondsLeft = 9;
    
    UITapGestureRecognizer *tapRecognizer1 = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(fastForward:)];
    self.coverViewTR.userInteractionEnabled = YES;
    [self.coverViewTR addGestureRecognizer:tapRecognizer1];
    
    UITapGestureRecognizer *tapRecognizer2 = [[UITapGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(fastForward:)];
    self.coverViewTL.userInteractionEnabled = YES;
    [self.coverViewTL addGestureRecognizer:tapRecognizer2];
    
    UITapGestureRecognizer *tapRecognizer3 = [[UITapGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(fastForward:)];
    self.coverViewBR.userInteractionEnabled = YES;
    [self.coverViewBR addGestureRecognizer:tapRecognizer3];
    
    UITapGestureRecognizer *tapRecognizer4 = [[UITapGestureRecognizer alloc]
                                              initWithTarget:self action:@selector(fastForward:)];
    self.coverViewBL.userInteractionEnabled = YES;
    [self.coverViewBL addGestureRecognizer:tapRecognizer4];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(runScheduledTask:) userInfo:nil repeats:YES];
    
}



- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Actions

-(IBAction)rewind:(id)sender {
    [self.player skipPrevious:nil];
}

-(IBAction)playPause:(id)sender {
    [self.player setIsPlaying:!self.player.isPlaying callback:nil];
}

-(IBAction)fastForward:(UITapGestureRecognizer *) sender {
    NSUInteger calledBy = 0;
    
    if(sender.view == self.coverViewTL){
        calledBy = 0;
    }
    if(sender.view == self.coverViewTR){
        calledBy = 1;
    }
    if(sender.view == self.coverViewBR){
        calledBy = 2;
    }
    if(sender.view == self.coverViewBL){
        calledBy = 3;
    }
    if(calledBy == self.realOne){
        NSLog(@"CORRECT");
        [self flashScreenPressed: [UIColor greenColor]];
    } else {
        [self flashScreenPressed: [UIColor redColor]];
    }
    self.secondsLeft = 9;

    
    [self.player skipNext:nil];
}

- (IBAction)logoutClicked:(id)sender {
    SPTAuth *auth = [SPTAuth defaultInstance];
    if (self.player) {
        [self.player logout:^(NSError *error) {
            auth.session = nil;
            [self.navigationController popViewControllerAnimated:YES];
        }];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Logic


- (UIImage *)applyBlurOnImage: (UIImage *)imageToBlur
                   withRadius: (CGFloat)blurRadius {

    CIImage *originalImage = [CIImage imageWithCGImage: imageToBlur.CGImage];
    CIFilter *filter = [CIFilter filterWithName: @"CIGaussianBlur"
                                  keysAndValues: kCIInputImageKey, originalImage,
                        @"inputRadius", @(blurRadius), nil];

    CIImage *outputImage = filter.outputImage;
    CIContext *context = [CIContext contextWithOptions:nil];

    CGImageRef outImage = [context createCGImage: outputImage
                                        fromRect: [outputImage extent]];

    UIImage *ret = [UIImage imageWithCGImage: outImage];

    CGImageRelease(outImage);

    return ret;
}

- (UIImageView *) getRandomCoverView {
    
    return self.coverViewTR;
}

- (IBAction)flashScreenPressed: (UIColor *) color
{

    UIView *flashView = [[UIView alloc]
                     initWithFrame:CGRectMake(0,
                                              0,
                                              self.view.frame.size.width,
                                              self.view.frame.size.height)];
        flashView.backgroundColor = color;
        [self.view addSubview:flashView];
    
    
    [flashView setAlpha:0.7f];
    
    
    //flash animation code
    [UIView beginAnimations:@"flash screen" context:nil];
    [UIView setAnimationDuration:0.7f];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    
    [flashView setAlpha:0.0f];
    
    [UIView commitAnimations];
    
    //flashLabel.text = @"Flashed";
}

- (void)setImage: (NSURL *) imageURL withCoverPic:(UIImageView *) coverPic {
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        UIImage *image = nil;
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL options:0 error:&error];
        
        if (imageData != nil) {
            image = [UIImage imageWithData:imageData];
        }
        
        
        // …and back to the main queue to display the image.
        //dispatch_async(dispatch_get_main_queue(), ^{
            [self.spinner stopAnimating];
            coverPic.image = image;
            if (image == nil) {
                NSLog(@"Couldn't load cover image with error: %@", error);
                return;
            }
        //});
        
    //});
}

-(void)updateUI {
    SPTAuth *auth = [SPTAuth defaultInstance];

    if (self.player.currentTrackURI == nil) {
        [self getRandomCoverView].image = nil;
        return;
    }
    
    [self.spinner startAnimating];

    [SPTTrack trackWithURI:self.player.currentTrackURI
                   session:auth.session
                  callback:^(NSError *error, SPTTrack *track) {

                      self.titleLabel.text = track.name;
                      self.albumLabel.text = track.album.name;

                      SPTPartialArtist *artist = [track.artists objectAtIndex:0];
                      self.artistLabel.text = artist.name;

                      [SPTPlaylistSnapshot requestStarredListForUserWithSession:auth.session callback:^(NSError *error, SPTPlaylistSnapshot *object) {
                          //NSLog(@"Starred :%@ tracks:%d",object.name, object.trackCount);
                          //NSLog(@"tracks on page 1 = %@", [object.firstTrackPage tracksForPlayback]);
                          
                          int numberOfItems = [object.firstTrackPage.items count];
                          
                          if (numberOfItems == 0){
                              numberOfItems = 1;
                          }
                          
                          NSUInteger randomIndex1 = arc4random() % numberOfItems;
                          
                          NSUInteger randomIndex2 = arc4random() % numberOfItems;
                          
                          NSUInteger randomIndex3 = arc4random() % numberOfItems;
                          
                          NSUInteger randomIndex4 = arc4random() % numberOfItems;
                          
                          self.realOne = arc4random_uniform(3);
                          
                         
                          [SPTTrack trackWithURI:[object.firstTrackPage.items[randomIndex1] playableUri] session:auth.session callback:^(NSError *error, SPTTrack *theTrack) {
                            
                              NSURL *imageURL = theTrack.album.largestCover.imageURL;
                              
                              if(self.realOne == 0){
                                  imageURL = track.album.largestCover.imageURL;
                              }
                            
                              [self setImage: imageURL withCoverPic: self.coverViewTL];
                              
                              
                          }];
          
                          
                          [SPTTrack trackWithURI:[object.firstTrackPage.items[randomIndex2] playableUri] session:auth.session callback:^(NSError *error, SPTTrack *theTrack) {
                              
                              NSURL *imageURL = theTrack.album.largestCover.imageURL;
                              
                              if(self.realOne == 1){
                                  imageURL = track.album.largestCover.imageURL;
                              }
                              
                              [self setImage: imageURL withCoverPic: self.coverViewTR];
                              
                          }];
                          
                          [SPTTrack trackWithURI:[object.firstTrackPage.items[randomIndex3] playableUri] session:auth.session callback:^(NSError *error, SPTTrack *theTrack) {
                              
                              NSURL *imageURL = theTrack.album.largestCover.imageURL;
                              
                              if(self.realOne == 2){
                                  imageURL = track.album.largestCover.imageURL;
                              }
                              
                              [self setImage: imageURL withCoverPic: self.coverViewBR];
                              
                          }];
                          
                          [SPTTrack trackWithURI:[object.firstTrackPage.items[randomIndex4] playableUri] session:auth.session callback:^(NSError *error, SPTTrack *theTrack) {
                              
                              NSURL *imageURL = theTrack.album.largestCover.imageURL;
                              
                              if(self.realOne == 3){
                                  imageURL = track.album.largestCover.imageURL;
                              }
                              
                              [self setImage: imageURL withCoverPic: self.coverViewBL];
    
                              
                          }];
                          
                          
                        
                      }];
                      

                      
                      

    }];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self handleNewSession];
}

-(void)handleNewSession {
    SPTAuth *auth = [SPTAuth defaultInstance];

    if (self.player == nil) {
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:auth.clientID];
        self.player.playbackDelegate = self;
        self.player.diskCache = [[SPTDiskCache alloc] initWithCapacity:1024 * 1024 * 1024];
    }

    [self.player loginWithSession:auth.session callback:^(NSError *error) {

		if (error != nil) {
			NSLog(@"*** Enabling playback got error: %@", error);
			return;
		}

        //[self updateUI];
        
    [SPTPlaylistSnapshot requestStarredListForUserWithSession:auth.session callback:^(NSError *error, SPTPlaylistSnapshot *object) {
            //NSLog(@"Starred :%@ tracks:%d",object.name, object.trackCount);
            //NSLog(@"tracks on page 1 = %@", [object.firstTrackPage tracksForPlayback]);
        
//        NSUInteger randomIndex0 = arc4random() % [object.firstTrackPage.items count];
//        
//        NSUInteger randomIndex1 = arc4random() % [object.firstTrackPage.items count];
//        
        NSUInteger randomIndex2 = arc4random() % [object.firstTrackPage.items count];
//        
//        NSUInteger randomIndex3 = arc4random() % [object.firstTrackPage.items count];
//        
//        NSUInteger randomIndex4 = arc4random() % [object.firstTrackPage.items count];
//        
//        [SPTTrack trackWithURI:[object.firstTrackPage.items[randomIndex1] playableUri] session:auth.session callback:^(NSError *error, SPTTrack *theTrack) {
//            
//            NSURL *imageURL = theTrack.album.largestCover.imageURL;
//            [self setImage: imageURL withCoverPic: self.coverViewTL];
//            
//        }];
//        
//        [SPTTrack trackWithURI:[object.firstTrackPage.items[randomIndex2] playableUri] session:auth.session callback:^(NSError *error, SPTTrack *theTrack) {
//            
//            NSURL *imageURL = theTrack.album.largestCover.imageURL;
//            [self setImage: imageURL withCoverPic: self.coverViewTR];
//            
//        }];
//        
//        [SPTTrack trackWithURI:[object.firstTrackPage.items[randomIndex3] playableUri] session:auth.session callback:^(NSError *error, SPTTrack *theTrack) {
//            
//            NSURL *imageURL = theTrack.album.largestCover.imageURL;
//            [self setImage: imageURL withCoverPic: self.coverViewBR];
//            
//        }];
//        
//        [SPTTrack trackWithURI:[object.firstTrackPage.items[randomIndex4] playableUri] session:auth.session callback:^(NSError *error, SPTTrack *theTrack) {
//            
//            NSURL *imageURL = theTrack.album.largestCover.imageURL;
//            [self setImage: imageURL withCoverPic: self.coverViewBL];
//            
//        }];
        
        [self.player playURIs:object.firstTrackPage.items fromIndex:randomIndex2 callback:nil];
        }];
        
//        NSURLRequest *playlistReq = [SPTPlaylistSnapshot createRequestForPlaylistWithURI:[NSURL URLWithString:@"spotify:user:cariboutheband:playlist:4Dg0J0ICj9kKTGDyFu0Cv4"]
//                                                                             accessToken:auth.session.accessToken
//                                                                                   error:nil];
        
//        [[SPTRequest sharedHandler] performRequest:playlistReq callback:^(NSError *error, NSURLResponse *response, NSData *data) {
//            if (error != nil) {
//                NSLog(@"*** Failed to get playlist %@", error);
//                return;
//            }
//            
//            SPTPlaylistSnapshot *playlistSnapshot = [SPTPlaylistSnapshot playlistSnapshotFromData:data withResponse:response error:nil];
//            
//            [self.player playURIs:playlistSnapshot.firstTrackPage.items fromIndex:0 callback:nil];
//        }];
	}];
}

#pragma mark - Track Player Delegates

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceiveMessage:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Message from Spotify"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didFailToPlayTrack:(NSURL *)trackUri {
    NSLog(@"failed to play track: %@", trackUri);
}

- (void) audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeToTrack:(NSDictionary *)trackMetadata {
    NSLog(@"track changed = %@", [trackMetadata valueForKey:SPTAudioStreamingMetadataTrackURI]);
    [self updateUI];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePlaybackStatus:(BOOL)isPlaying {
    NSLog(@"is playing = %d", isPlaying);
}

@end
