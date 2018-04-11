/*
     File: SessionContainer.h
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

#import <Foundation/Foundation.h>

@class Transcript;

@protocol SessionContainerDelegate;

// MCSessionの状態、API呼び出し、および代理コールバックを管理するためのコンテナユーティリティクラス
@interface SessionContainer : NSObject <MCSessionDelegate>

@property (readonly, nonatomic) MCSession *session;
@property (assign, nonatomic) id<SessionContainerDelegate> delegate;

//指定された初期化子
- (id)initWithDisplayName:(NSString *)displayName serviceType:(NSString *)serviceType;
//接続されているすべてのリモートピアにテキストメッセージを送信する方法。返信メッセージタイプのトランスクリプト
- (Transcript *)sendMessage:(NSString *)message;
//接続されているすべてのリモートピアにイメージリソースを送信する方法。トランスポートを監視するための進捗タイプのトランスクリプトを返します。
- (Transcript *)sendImage:(NSURL *)imageUrl;

@end

// Delegate protocol for updating UI when we receive data or resources from peers.
//ピアからデータやリソースを受け取ったときにUIを更新するためのプロトコルを委譲します。
@protocol SessionContainerDelegate <NSObject>

// Method used to signal to UI an initial message, incoming image resource has been received
//最初のメッセージにUIに信号を送るために使用されるメソッド、着信イメージリソースが受信された
- (void)receivedTranscript:(Transcript *)transcript;
// Method used to signal to UI an image resource transfer (send or receive) has completed
//イメージリソース転送（送信または受信）が完了したことをUIに通知するために使用されるメソッド
- (void)updateTranscript:(Transcript *)transcript;

@end
