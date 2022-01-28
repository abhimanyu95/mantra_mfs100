export 'msf_100_event.dart';
export 'finger_data.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mantra_mfs100/finger_data.dart';
import 'msf_100_event.dart';

class MantraMfs100 {

  /// Singleton Instance;
  static MantraMfs100? instance;
  final MSF100Event mfsEvent;

  factory MantraMfs100(MSF100Event mfsEvent){
    instance ??= MantraMfs100._(mfsEvent);
    return instance!;
  }

  MantraMfs100._(this.mfsEvent){
    _init();
  }

  _init(){
   _registerEventChannel();
  }

  static const MethodChannel _channel =  MethodChannel('mantra_mfs_100');
  static const EventChannel _eventChannel =  EventChannel('mantra_mfs_100/event');

  _registerEventChannel(){

    /// Static MFS Events are : Connected, Disconnected, HostCheckFailed
    _eventChannel.receiveBroadcastStream().listen((event) {

      var eventName=event['eventName'];

      switch(eventName.toString()){

        case 'Connected':{
          mfsEvent.onDeviceAttached(event['hasPermission']);
        }
        break;

        case 'Disconnected':{
          mfsEvent.onDeviceDetached();
        }
        break;

        case 'HostCheckFailed':{
          mfsEvent.onHostCheckFailed(event['var1'].toString());
        }
        break;

      }

    });

  }

   Future<int>  init() async {
    final int res = await _channel.invokeMethod('init');
    return res;
   }

   Future<FingerData>  startAutoCapture(int timeOut,bool detectFastFinger) async {
     var data=<String,dynamic>{
       'detectFinger':detectFastFinger,
       'timeout':timeOut
     };
    final  res = await _channel.invokeMethod('autoCapture',data);
    return Future.value(FingerData.load(res));
   }

   Future<int>  matchISO(Uint8List firstTemplate, Uint8List secondTemplate) async {
     var data=<String,dynamic>{
       'firstTemplate':firstTemplate,
       'secondTemplate':secondTemplate
     };
    final  res = await _channel.invokeMethod('matchISO',data);
    print('matchISO '+res.toString());
    return Future.value(res);
   }

   Future<String> getErrorMsg(int errorCode) async {
    final res = await _channel.invokeMethod('getErrorMessage',{'error':errorCode});
    return Future.value(res);
  }

  Future<int> stopAutoCapture() async {
   final res = await _channel.invokeMethod('stopAutoCapture');
    return Future.value(res);
  }

  Future<int> unInit() async {
    return Future.value(await _channel.invokeMethod('unInit'));
  }

  Future dispose() async {
    await _channel.invokeMethod('dispose');
  }

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

}

showAlert(BuildContext context, String msg){

  final AlertDialog alert=AlertDialog(
    title: const Text('Testing'),
    content: Text(msg),
    actions: [TextButton(onPressed: (){
      Navigator.pop(context);
    }, child: const Text('OK'))],
  );

  showDialog(context: context, builder: (ctx)=> alert);

}

