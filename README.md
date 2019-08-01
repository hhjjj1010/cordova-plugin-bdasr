# 百度语音识别cordova插件（更新至bdasr_V3_20190515_c9eed5d.jar）

- 这是一个百度语音识别的cordova插件。为什么使用百度语音识别，因为是免费的，识别的准确度也还挺不错的。
- 这个插件只包含语音识别功能，不包含其他的比如唤醒、长语音功能。
- 百度语音开发文档 http://ai.baidu.com/docs#/ASR-API/top

# 支持平台
1. Android（bdasr_V3_20190515_c9eed5d.jar）
2. iOS

# 安装
## 在线npm安装

## 本地安装

github文件超过100M之后只能使用LFS才能上传，但是同时也有带宽限制。为了避免各种限制，所以只能辛苦各位自行下载[libBaiduSpeech.a](https://ai.baidu.com/sdk#asr)，并放到插件的src/ios/BDSClientLib目录中。

- 第一步，将插件下载到本地
- 第二步，下载iOS SDK中缺少的[libBaiduSpeech.a](https://ai.baidu.com/sdk#asr)
- 第三步，添加libBaiduSpeech.a到src/ios/BDSClientLib
- 第四步，安装插件

``` shell
cordova plugin add /your localpath --variable APIKEY=your apikey --variable SECRETKEY=your secretkey --variable APPID=your appid
```

## 在线npm安装（推荐）
在线npm安装不受任何限制，可直接安装。
 ``` shell
cordova plugin add cordova-plugin-bdasr --variable APIKEY=your apikey --variable SECRETKEY=your secretkey --variable APPID=your appid
 ```

# API使用

#### 开启语音识别
startSpeechRecognize

__代码示例__
``` js
cordova.plugins.bdasr.startSpeechRecognize();
```

#### 关闭语音识别
closeSpeechRecognize

__代码示例__
``` js
cordova.plugins.bdasr.closeSpeechRecognize();
```

#### 取消语音识别
cancelSpeechRecognize

__代码示例__
``` js
cordova.plugins.bdasr.cancelSpeechRecognize();
```

#### 事件监听
addEventListener

__代码示例__
``` js
// 语音识别事件监听
cordova.plugins.bdasr.addEventListener(function (res) {
  // res参数都带有一个type
  if (!res) {
    return;
  }

  switch (res.type) {
    case "asrReady": {
      // 识别工作开始，开始采集及处理数据
      $scope.$apply(function () {
        // TODO
      });
      break;
    }

    case "asrBegin": {
      // 检测到用户开始说话
      $scope.$apply(function () {
        // TODO
      });
      break;
    }

    case "asrEnd": {
      // 本地声音采集结束，等待识别结果返回并结束录音
      $scope.$apply(function () {
      // TODO
      });
      break;
    }

    case "asrText": {
      // 语音识别结果
      $scope.$apply(function () {
        var message = angular.fromJson(res.message);
        var results = message["results_recognition"];
      });
      break;
    }

    case "asrFinish": {
      // 语音识别功能完成
      $scope.$apply(function () {
        // TODO
      });
      break;
    }

    case "asrCancel": {
      // 语音识别取消
      $scope.$apply(function () {
        // TODO
      });
      break;
    }

    default:
      break;
  }

}, function (err) {
   alert("语音识别错误");
});
```

# 写在最后
因为对android开发并不是很熟悉，所以特此记录在开发插件的android端时遇到的一些问题
1. 加载so库，对应不同的平台，需要添加不同平台的.so文件

``` xml
<source-file src="src/android/libs/armeabi/libBaiduSpeechSDK.so" target-dir="libs/armeabi"/>
<source-file src="src/android/libs/armeabi/libvad.dnn.so" target-dir="libs/armeabi"/>

<source-file src="src/android/libs/x86_64/libBaiduSpeechSDK.so" target-dir="libs/x86_64"/>
<source-file src="src/android/libs/x86_64/libvad.dnn.so" target-dir="libs/x86_64"/>

<source-file src="src/android/libs/x86/libBaiduSpeechSDK.so" target-dir="libs/x86"/>
<source-file src="src/android/libs/x86/libvad.dnn.so" target-dir="libs/x86"/>

<source-file src="src/android/libs/arm64-v8a/libBaiduSpeechSDK.so" target-dir="libs/arm64-v8a"/>
<source-file src="src/android/libs/arm64-v8a/libvad.dnn.so" target-dir="libs/arm64-v8a"/>

<source-file src="src/android/libs/armeabi-v7a/libBaiduSpeechSDK.so" target-dir="libs/armeabi-v7a"/>
<source-file src="src/android/libs/armeabi-v7a/libvad.dnn.so" target-dir="libs/armeabi-v7a"/>
```

2. PermissionHelper.requestPermission()方法封装了动态获取权限的代码
动态获取权限的回调方法：
``` java
public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {}）
```
