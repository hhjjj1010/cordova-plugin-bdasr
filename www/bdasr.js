var exec = require('cordova/exec');

exports.startSpeechRecognize = function (arg0, success, error) {
    exec(success, error, "bdasr", "startSpeechRecognize", [arg0]);
};

exports.closeSpeechRecognize = function (arg0, success, error) {
    exec(success, error, "bdasr", "closeSpeechRecognize", [arg0]);
};

exports.cancelSpeechRecognize = function (arg0, success, error) {
    exec(success, error, "bdasr", "cancelSpeechRecognize", [arg0]);
};

exports.addEventListener = function (success, error) {
    exec(success, error, "bdasr", "addEventListener");
};