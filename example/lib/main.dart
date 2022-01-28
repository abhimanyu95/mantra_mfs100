
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mantra_mfs100/mantra_mfs100.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with MSF100Event {

  String _platformVersion = 'Unknown';

  late MantraMfs100 mfs;

  String status = 'Disconnected';

  bool _isCapturing = false;

  Uint8List? memoryImage;

  List<int> firstTemplate=[];

  @override
  void initState() {
    super.initState();
    mfs = MantraMfs100(this);
    mfs.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MFS100'),
              Text(status),
            ],
          ),
        ),
        body: Center(
          child: Column(
            children: [

              memoryImage != null
                  ? Image.memory(memoryImage!, height: 128, width: 128)
                  : const SizedBox(),

              const SizedBox(height: 20),

              TextButton(
                  onPressed: () async {
                    try{

                    if (_isCapturing) return;
                    _isCapturing = true;
                     FingerData res = await mfs.startAutoCapture(6000,true);

                     firstTemplate.clear();
                     firstTemplate.addAll(res.iSOTemplate);

                    setState(() {
                      _platformVersion = 'Sucess ${res.quality}';
                      memoryImage = Uint8List.fromList(res.fingerImage);
                      debugPrint('onCapturing-> ${res.iSOTemplate}');
                      print('onCapturing-> Length:${res.iSOTemplate.length}');
                    });

                    }catch(err,stack){

                      if(err is PlatformException){
                        setState(() {
                          _platformVersion=err.message.toString();
                        });
                      }
                      print('While Capturing-> $err, $stack');
                    }finally{
                      _isCapturing = false;
                    }
                  },
                  child: const Text('Capture')),
              const SizedBox(height: 20),
              TextButton( /// Verify Image
                  onPressed: () async {
                    try{

                    if (_isCapturing) return;
                    _isCapturing = true;

                     FingerData res = await mfs.startAutoCapture(6000,true);

                     var ret = await mfs.matchISO(Uint8List.fromList(firstTemplate),Uint8List.fromList(res.iSOTemplate));

                     if(ret < 0){
                       setState(() {
                         _platformVersion = 'Error: ${mfs.getErrorMsg(ret)}';
                       });
                     }else{

                       if (ret >= 96) {
                         setState(() {
                           _platformVersion = 'Finger matched with score: $ret';
                         });
                       } else {
                         setState(() {
                           _platformVersion =' Finger not matched, score: $ret' ;
                         });
                       }
                     }

                    }catch(err,stack){

                      if(err is PlatformException){
                        setState(() {
                          _platformVersion=err.message.toString();
                        });
                      }
                      print('While Verifying-> $err, $stack');
                    }finally{
                      _isCapturing = false;
                    }
                  },
                  child: const Text('Match')),

              const SizedBox(height: 20),

              TextButton(
                  onPressed: () async {
                    if (!_isCapturing) return;
                    var res = await mfs.stopAutoCapture();
                    _isCapturing = false;
                  },
                  child: const Text('Stop')),

              Text('Status: $_platformVersion\n'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void onDeviceAttached(bool hasPermission) {
    setState(() {
      status = 'Connected';
    });
    print('onDeviceAttached-> $hasPermission');
  }

  @override
  void onDeviceDetached() {
    setState(() {
      status = 'Disconnected';
    });
    print('onDeviceDetached: ---');
  }

  @override
  void onHostCheckFailed(String var1) {}

  @override
  void dispose() {
    mfs.unInit();
    mfs.dispose();
    super.dispose();
  }

  test(){

    List<int> first=[1,2,3,4];

    List<int> second=List.filled(first.length, 0);

    List.copyRange(second, 0, first);

    print('New range $second');

  }

}
