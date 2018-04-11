/*
     File: SessionContainer.m
 Abstract:  This container class is used to encapsulate the Multipeer Connectivity API classes and their respective delegate callbacks.  The is the MOST IMPORTANT source file in the entire example.  In this class you see examples of managing MCSession state, sending and receving data based messages, and sending and receving URL resources via the convenience API. 
 
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

@import MultipeerConnectivity;

#import "SessionContainer.h"
#import "Transcript.h"

@interface SessionContainer()
// Framework UI class for handling incoming invitations
//受信した招待状を処理するフレームワークUIクラス
@property (retain, nonatomic) MCAdvertiserAssistant *advertiserAssistant;
@end

@implementation SessionContainer

// Session container designated initializer
//セッションコンテナで指定された初期化子
- (id)initWithDisplayName:(NSString *)displayName serviceType:(NSString *)serviceType
{
    if (self = [super init]) {
        // Create the peer ID with user input display name.  This display name will be seen by other browsing peers
        //ユーザー入力の表示名でピアIDを作成します。この表示名は他の閲覧ピアによって表示されます
        MCPeerID *peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
        // Create the session that peers will be invited/join into.  You can provide an optinal security identity for custom authentication.  Also you can set the encryption preference for the session.
        //ピアを招待/参加するセッションを作成します。カスタム認証のためのオプティカルセキュリティIDを提供できます。また、セッションの暗号化設定を設定することもできます。
        _session = [[MCSession alloc] initWithPeer:peerID securityIdentity:nil encryptionPreference:MCEncryptionRequired];
        // Set ourselves as the MCSessionDelegate
        //自分自身をMCSessionDelegateとして設定する
        _session.delegate = self;
        // Create the advertiser assistant for managing incoming invitation
        //招待状を管理するための広告主アシスタントを作成する
        _advertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:serviceType discoveryInfo:nil session:_session];
        // Start the assistant to begin advertising your peers availability
        //アシスタントを起動してピアの可用性を広告する
        [_advertiserAssistant start];
    }
    return self;
}

// On dealloc we should clean up the session by disconnecting from it.
// deallocでは、セッションを切断してセッションをクリーンアップする必要があります。
- (void)dealloc
{
    [_advertiserAssistant stop];
    [_session disconnect];
}

// Helper method for human readable printing of MCSessionState.  This state is per peer.
//人間が読めるMCSessionStateの印刷のヘルパーメソッド。この状態はピアごとです。
- (NSString *)stringForPeerConnectionState:(MCSessionState)state
{
    switch (state) {
        case MCSessionStateConnected:
            return @"Connected";

        case MCSessionStateConnecting:
            return @"Connecting";

        case MCSessionStateNotConnected:
            return @"Not Connected";
    }
}

#pragma mark - Public methods

// Instance method for sending a string bassed text message to all remote peers
//すべてのリモートピアに文字列ベースのテキストメッセージを送信するためのインスタンスメソッド
- (Transcript *)sendMessage:(NSString *)message
{
    // Convert the string into a UTF8 encoded data
    //文字列をUTF8でエンコードされたデータに変換する
    NSData *messageData = [message dataUsingEncoding:NSUTF8StringEncoding];
    // Send text message to all connected peers
    //文字列をUTF8でエンコードされたデータに変換する
    NSError *error;
    [self.session sendData:messageData toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
    // Check the error return to know if there was an issue sending data to peers.  Note any peers in the 'toPeers' array argument are not connected this will fail.
    //エラーを確認して、ピアにデータを送信する際に問題があるかどうかを確認します。'toPeers'配列引数のいずれかのピアが接続されていない場合、これは失敗します。
    if (error) {
        NSLog(@"Error sending message to peers [%@]", error);
        return nil;
    }
    else {
        // Create a new send transcript
        //新しい送信トランスクリプトを作成する
        return [[Transcript alloc] initWithPeerID:_session.myPeerID message:message direction:TRANSCRIPT_DIRECTION_SEND];
    }
}

// Method for sending image resources to all connected remote peers.  Returns an progress type transcript for monitoring tranfer
//接続されているすべてのリモートピアにイメージリソースを送信する方法。トランスポートを監視するための進捗タイプのトランスクリプトを返します。
- (Transcript *)sendImage:(NSURL *)imageUrl
{
    NSProgress *progress;
    // Loop on connected peers and send the image to each
    //接続されたピアをループし、それぞれに画像を送信する
    for (MCPeerID *peerID in _session.connectedPeers) {
//        imageUrl = [NSURL URLWithString:@"http://images.apple.com/home/images/promo_logic_pro.jpg"];
        // Send the resource to the remote peer.  The completion handler block will be called at the end of sending or if any errors occur
        //リソースをリモートピアに送信します。完了ハンドラブロックは、送信の最後に呼び出されるか、エラーが発生した場合に呼び出されます
        progress = [self.session sendResourceAtURL:imageUrl withName:[imageUrl lastPathComponent] toPeer:peerID withCompletionHandler:^(NSError *error) {
            //このブロックを実装して、送信リソース転送がいつ完了し、エラーがあるかを確認します。
            if (error) {
                NSLog(@"Send resource to peer [%@] completed with Error [%@]", peerID.displayName, error);
            }
            else {
                //この受信したイメージリソースのイメージトランスクリプトを作成します。
                Transcript *transcript = [[Transcript alloc] initWithPeerID:_session.myPeerID imageUrl:imageUrl direction:TRANSCRIPT_DIRECTION_SEND];
                [self.delegate updateTranscript:transcript];
            }
        }];
    }
    //進行中の進捗記録を作成します。わかりやすくするために、単一のNSProgressを監視します。しかし、ユーザーは必要に応じて個別に返された各NSProgressを測定できます
    Transcript *transcript = [[Transcript alloc] initWithPeerID:_session.myPeerID imageName:[imageUrl lastPathComponent] progress:progress direction:TRANSCRIPT_DIRECTION_SEND];

    return transcript;
}

#pragma mark - MCSessionDelegate methods

//このメソッドをオーバーライドして、ピアセッション状態の変更を処理します。
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"Peer [%@] changed state to %@", peerID.displayName, [self stringForPeerConnectionState:state]);

    NSString *adminMessage = [NSString stringWithFormat:@"'%@' is %@", peerID.displayName, [self stringForPeerConnectionState:state]];
    //ローカルのトランスクリプトを作成する
    Transcript *transcript = [[Transcript alloc] initWithPeerID:peerID message:adminMessage direction:TRANSCRIPT_DIRECTION_LOCAL];

    //ピアからデータの新しい塊を受け取ったことをデリゲートに通知する
    [self.delegate receivedTranscript:transcript];
}

// MCSession指定されたセッションのピアからデータを受け取るときの代理コールバック
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    //着信データをUTF8でエンコードされた文字列にデコードする
    NSString *receivedMessage = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
    //受信したトランスクリプトを作成する
    Transcript *transcript = [[Transcript alloc] initWithPeerID:peerID message:receivedMessage direction:TRANSCRIPT_DIRECTION_RECEIVE];
    
    //ピアからデータの新しい塊を受け取ったことをデリゲートに通知する
    [self.delegate receivedTranscript:transcript];
}

//指定されたセッション内のピアからリソースを受信し始めたときのMCSession代理コールバック
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    NSLog(@"Start receiving resource [%@] from peer %@ with progress [%@]", resourceName, peerID.displayName, progress);
    //リソース進捗記録を作成する
    Transcript *transcript = [[Transcript alloc] initWithPeerID:peerID imageName:resourceName progress:progress direction:TRANSCRIPT_DIRECTION_RECEIVE];
    // UIデリゲートに通知する
    [self.delegate receivedTranscript:transcript];
}

//着信リソース転送が終了したとき（おそらくエラーが発生した場合）MCSessionデリゲートコールバック
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    //エラーが無かった場合何かが間違っていた
    if (error)
    {
        NSLog(@"Error [%@] receiving resource from peer %@ ", [error localizedDescription], peerID.displayName);
    }
    else
    {
        //これで転送が完了したのでエラーは発生しません。リソースは一時的な場所にあり、すぐに永続的な場所にコピーする必要があります。
        //ドキュメントディレクトリに書き込む
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *copyPath = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], resourceName];
        if (![[NSFileManager defaultManager] copyItemAtPath:[localURL path] toPath:copyPath error:nil])
        {
            NSLog(@"Error copying resource to documents directory");
        }
        else {
            //リソースをコピーしたばかりのパスのURLを取得する
            NSURL *imageUrl = [NSURL fileURLWithPath:copyPath];
            //この受信したイメージリソースのイメージトランスクリプトを作成します。
            Transcript *transcript = [[Transcript alloc] initWithPeerID:peerID imageUrl:imageUrl direction:TRANSCRIPT_DIRECTION_RECEIVE];
            [self.delegate updateTranscript:transcript];
        }
    }
}

//このサンプルコードでは使用されていないストリーミングAPI
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    NSLog(@"Received data over stream with name %@ from peer %@", streamName, peerID.displayName);
}

@end
