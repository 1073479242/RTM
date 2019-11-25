//
//  MainViewController.m
//  Agora-Rtm-Tutorial
//
//  Created by CavanSu on 2019/2/19.
//  Copyright © 2019 Agora. All rights reserved.
//

#import "MainViewController.h"
#import "PeerChannelViewController.h"
#import "AgoraRtm.h"

@interface MainViewController () <PeerChannelVCDelegate, AgoraRtmDelegate>
@property (weak, nonatomic) IBOutlet NSTextField *accountTextField;
@property (weak) IBOutlet NSButton *enableOneToOneBox;
@end

@implementation MainViewController

- (void)viewWillAppear {
    [super viewWillAppear];
    [self logout];
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
    NSString *identifier = segue.identifier;
    
    if (![identifier isEqualToString:@"mainToTab"]) {
        return;
    }
    
    PeerChannelViewController *vc = (PeerChannelViewController *)segue.destinationController;
    vc.delegate = self;
}

- (IBAction)doLoginPressed:(NSButton *)sender {
    [self login];
}

- (void)login {
    NSString *account = self.accountTextField.stringValue;
    if (!account.length) {
        return;
    }
    
    [AgoraRtm updateDelegate:self];
    [AgoraRtm setCurrent:account];
    [AgoraRtm setOneToOneMessageType:self.enableOneToOneBox.state == NSControlStateValueOn ? OneToOneMessageTypeOffline : OneToOneMessageTypeNormal];
    
    [AgoraRtm.kit loginByToken:nil user:account completion:^(AgoraRtmLoginErrorCode errorCode) {
        if (errorCode != AgoraRtmLoginErrorOk) {
            [self showAlert: [NSString stringWithFormat:@"login error: %ld", errorCode]];
            return;
        }
        
        [AgoraRtm setStatus:LoginStatusOnline];
        
        __weak MainViewController *weakSelf = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf performSegueWithIdentifier:@"mainToTab" sender:nil];
        });
    }];
}

- (void)logout {
    if (AgoraRtm.status == LoginStatusOffline) {
        return;
    }
    
    [AgoraRtm.kit logoutWithCompletion:^(AgoraRtmLogoutErrorCode errorCode) {
        if (errorCode != AgoraRtmLogoutErrorOk) {
            return;
        }
        
        [AgoraRtm setStatus:LoginStatusOffline];
    }];
}

- (void)peerChannelVCWillClose:(PeerChannelViewController *)vc {
    vc.view.window.contentViewController = self;
}

// Receive one to one offline messages
- (void)rtmKit:(AgoraRtmKit *)kit messageReceived:(AgoraRtmMessage *)message fromPeer:(NSString *)peerId {
    [AgoraRtm addOfflineMessage:message fromUser:peerId];
}

@end
