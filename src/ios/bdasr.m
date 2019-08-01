/********* bdasr.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "BDSEventManager.h"
#import "BDSASRDefines.h"
#import "BDSASRParameters.h"
#import <AVFoundation/AVFoundation.h>

@interface bdasr : CDVPlugin<BDSClientASRDelegate, UIAlertViewDelegate> {
    // Member variables go here.
    NSString* API_KEY;
    NSString* SECRET_KEY;
    NSString* APP_ID;
    
    NSString *callbackId;
}

@property (strong, nonatomic) BDSEventManager *asrEventManager;
@property (strong, nonatomic) NSBundle *bdsClientBundle;

- (void)startSpeechRecognize:(CDVInvokedUrlCommand *)command;
- (void)closeSpeechRecognize:(CDVInvokedUrlCommand *)command;
- (void)cancelSpeechRecognize:(CDVInvokedUrlCommand *)command;

@end

@implementation bdasr

- (NSBundle *)bdsClientBundle {
    if (!_bdsClientBundle) {
        NSString *strResourcesBundle = [[NSBundle mainBundle] pathForResource:@"BDSClientResource" ofType:@"bundle"];
        _bdsClientBundle = [NSBundle bundleWithPath:strResourcesBundle];
    }
    
    return _bdsClientBundle;
}

- (void)pluginInitialize {
    [self.commandDelegate runInBackground:^{
        CDVViewController *viewController = (CDVViewController *)self.viewController;
        APP_ID = [viewController.settings objectForKey:@"bdasrappid"];
        API_KEY = [viewController.settings objectForKey:@"bdasrapikey"];
        SECRET_KEY = [viewController.settings objectForKey:@"bdasrsecretkey"];
        
        [self initAsrEventManager];
    }];
}

- (NSInteger)checkMicPermission {
    NSInteger flag = 0;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (authStatus) {
        case AVAuthorizationStatusNotDetermined:
        //没有询问是否开启麦克风
        flag = 1;
        break;
        case AVAuthorizationStatusRestricted:
        //未授权，家长限制
        flag = 0;
        break;
        case AVAuthorizationStatusDenied:
        //玩家未授权
        flag = 0;
        break;
        case AVAuthorizationStatusAuthorized:
        //玩家授权
        flag = 2;
        break;
        default:
        break;
    }
    return flag;
}


- (void)startSpeechRecognize:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        if ([self checkMicPermission] == 0) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"您还未授权[美车驿站]使用麦克风" delegate:self
                                                  cancelButtonTitle:@"知道了" otherButtonTitles:@"去设置", nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert show];
            });
        } else {
            // 发送指令：启动识别
            [self.asrEventManager sendCommand:BDS_ASR_CMD_START];
        }
    }];
    
}

- (void)closeSpeechRecognize:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        [self.asrEventManager sendCommand:BDS_ASR_CMD_STOP];
    }];
    
}

- (void)cancelSpeechRecognize:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        [self.asrEventManager sendCommand:BDS_ASR_CMD_CANCEL];
    }];
    
}

- (void)addEventListener:(CDVInvokedUrlCommand *)command {
    [self.commandDelegate runInBackground:^{
        callbackId = command.callbackId;
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
        [result setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    }];
}



- (void)initAsrEventManager {
    // 创建语音识别对象
    self.asrEventManager = [BDSEventManager createEventManagerWithName:BDS_ASR_NAME];
    // 设置语音识别代理
    [self.asrEventManager setDelegate:self];
    // 参数配置：在线身份验证
    [self.asrEventManager setParameter:@[API_KEY, SECRET_KEY] forKey:BDS_ASR_API_SECRET_KEYS];
    //设置 APPID
    [self.asrEventManager setParameter:APP_ID forKey:BDS_ASR_OFFLINE_APP_CODE];
    
    //配置端点检测（二选一）
    //    [self configModelVAD];
    [self configDNNMFE];
    
    //     [self.asrEventManager setParameter:@"15361" forKey:BDS_ASR_PRODUCT_ID];
    // ---- 语义与标点 -----
    [self enableNLU];
    //    [self enablePunctuation];
    // ------------------------
}

- (void) enableNLU {
    // ---- 开启语义理解 -----
    [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_NLU];
    [self.asrEventManager setParameter:@"15361" forKey:BDS_ASR_PRODUCT_ID];
}

- (void) enablePunctuation {
    // ---- 开启标点输出 -----
    [self.asrEventManager setParameter:@(NO) forKey:BDS_ASR_DISABLE_PUNCTUATION];
    // 普通话标点
    //    [self.asrEventManager setParameter:@"1537" forKey:BDS_ASR_PRODUCT_ID];
    // 英文标点
    [self.asrEventManager setParameter:@"1737" forKey:BDS_ASR_PRODUCT_ID];
    
}


- (void)configModelVAD {
    NSString *modelVAD_filepath = [self.bdsClientBundle pathForResource:@"bds_easr_basic_model" ofType:@"dat"];
    [self.asrEventManager setParameter:modelVAD_filepath forKey:BDS_ASR_MODEL_VAD_DAT_FILE];
    [self.asrEventManager setParameter:@(YES) forKey:BDS_ASR_ENABLE_MODEL_VAD];
}

- (void)configDNNMFE {
    NSString *mfe_dnn_filepath = [self.bdsClientBundle pathForResource:@"bds_easr_mfe_dnn" ofType:@"dat"];
    [self.asrEventManager setParameter:mfe_dnn_filepath forKey:BDS_ASR_MFE_DNN_DAT_FILE];
    NSString *cmvn_dnn_filepath = [self.bdsClientBundle pathForResource:@"bds_easr_mfe_cmvn" ofType:@"dat"];
    [self.asrEventManager setParameter:cmvn_dnn_filepath forKey:BDS_ASR_MFE_CMVN_DAT_FILE];
    // 自定义静音时长
    //    [self.asrEventManager setParameter:@(501) forKey:BDS_ASR_MFE_MAX_SPEECH_PAUSE];
    //    [self.asrEventManager setParameter:@(500) forKey:BDS_ASR_MFE_MAX_WAIT_DURATION];
}

#pragma mark - MVoiceRecognitionClientDelegate

- (void)VoiceRecognitionClientWorkStatus:(int)workStatus obj:(id)aObj {
    switch (workStatus) {
        case EVoiceRecognitionClientWorkStatusNewRecordData: {
            //            [self.fileHandler writeData:(NSData *)aObj];
            break;
        }
        
        case EVoiceRecognitionClientWorkStatusStartWorkIng: {
            NSDictionary *logDic = [self parseLogToDic:aObj];
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK: start vr, log: %@\n", logDic]];
            NSDictionary *dict = @{
                                   @"type": @"asrReady",
                                   @"message": @"ok"
                                   };
            [self sendEvent:dict];
            break;
        }
        case EVoiceRecognitionClientWorkStatusStart: {
            NSDictionary *dict = @{
                                   @"type": @"asrBegin",
                                   @"message": @"ok"
                                   };
            [self sendEvent:dict];
            break;
        }
        case EVoiceRecognitionClientWorkStatusEnd: {
            
            NSDictionary *dict = @{
                                   @"type": @"asrEnd",
                                   @"message": @"ok"
                                   };
            [self sendEvent:dict];
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusFlushData: {
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK: partial result - %@.\n\n", [self getDescriptionForDic:aObj]]];
            if (aObj && [aObj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = @{
                                       @"type": @"asrText",
                                       @"message" :aObj
                                       };
                
                [self sendEvent:dict];
            }
            break;
        }
        case EVoiceRecognitionClientWorkStatusFinish: {
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK: asr finish - %@.\n\n", [self getDescriptionForDic:aObj]]];
            
            if (aObj && [aObj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = @{
                                       @"type": @"asrText",
                                       @"message" :aObj
                                       };
                
                [self sendEvent:dict];
            }
            NSDictionary *dict = @{
                                   @"type": @"asrFinish",
                                   @"message": @"ok"
                                   };
            [self sendEvent:dict];
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusMeterLevel: {
            break;
        }
        case EVoiceRecognitionClientWorkStatusCancel: {
            NSDictionary *dict = @{
                                   @"type": @"asrCancel",
                                   @"message": @"ok"
                                   };
            [self sendEvent:dict];
            break;
        }
        case EVoiceRecognitionClientWorkStatusError: {
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK: encount error - %@.\n", (NSError *)aObj]];
            [self sendError:[NSString stringWithFormat:@"CALLBACK: encount error - %@.\n", (NSError *)aObj]];
            break;
        }
        case EVoiceRecognitionClientWorkStatusLoaded: {
            [self printLogTextView:@"CALLBACK: offline engine loaded.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusUnLoaded: {
            [self printLogTextView:@"CALLBACK: offline engine unLoaded.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkThirdData: {
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK: Chunk 3-party data length: %lu\n", (unsigned long)[(NSData *)aObj length]]];
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkNlu: {
            NSString *nlu = [[NSString alloc] initWithData:(NSData *)aObj encoding:NSUTF8StringEncoding];
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK: Chunk NLU data: %@\n", nlu]];
            NSLog(@"%@", nlu);
            break;
        }
        case EVoiceRecognitionClientWorkStatusChunkEnd: {
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK: Chunk end, sn: %@.\n", aObj]];
            
            break;
        }
        case EVoiceRecognitionClientWorkStatusFeedback: {
            NSDictionary *logDic = [self parseLogToDic:aObj];
            [self printLogTextView:[NSString stringWithFormat:@"CALLBACK Feedback: %@\n", logDic]];
            break;
        }
        case EVoiceRecognitionClientWorkStatusRecorderEnd: {
            [self printLogTextView:@"CALLBACK: recorder closed.\n"];
            break;
        }
        case EVoiceRecognitionClientWorkStatusLongSpeechEnd: {
            [self printLogTextView:@"CALLBACK: Long Speech end.\n"];
            break;
        }
        default:
        break;
    }
}

- (void)sendEvent:(NSDictionary *)dict {
    if (!callbackId) return;
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict];
    [result setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    
}

- (void)sendError:(NSString *)errMsg {
    if (!callbackId) return;
    
    NSDictionary *dict = @{
                           @"type": @"asrError",
                           @"message": errMsg
                           };
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:dict];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}



- (void)printLogTextView:(NSString *)logString
{
    NSLog(@"%@", logString);
}

- (NSDictionary *)parseLogToDic:(NSString *)logString
{
    NSArray *tmp = NULL;
    NSMutableDictionary *logDic = [[NSMutableDictionary alloc] initWithCapacity:3];
    NSArray *items = [logString componentsSeparatedByString:@"&"];
    for (NSString *item in items) {
        tmp = [item componentsSeparatedByString:@"="];
        if (tmp.count == 2) {
            [logDic setObject:tmp.lastObject forKey:tmp.firstObject];
        }
    }
    return logDic;
}

- (NSString *)getDescriptionForDic:(NSDictionary *)dic {
    if (dic) {
        return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic
                                                                              options:NSJSONWritingPrettyPrinted
                                                                                error:nil] encoding:NSUTF8StringEncoding];
    }
    return nil;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}


@end

