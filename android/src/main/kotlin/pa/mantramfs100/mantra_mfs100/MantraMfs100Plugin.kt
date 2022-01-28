package pa.mantramfs100.mantra_mfs100

import android.content.Context
import android.os.SystemClock
import android.util.Log
import android.widget.Toast
import androidx.annotation.NonNull
import com.mantra.mfs100.FingerData
import com.mantra.mfs100.MFS100
import com.mantra.mfs100.MFS100Event
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** MantraMfs100Plugin */
class MantraMfs100Plugin: FlutterPlugin, MethodCallHandler{

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var mfs100: MFS100
    private lateinit var mContext: Context
    private lateinit var mfsEvent: MFS100Event
    private var isMfsInitialized=false
    private var mLastAttTime = 0L
    private val mLastClkTime: Long = 0
    private val Threshold: Long = 1500

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        mContext=flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mantra_mfs_100")
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "mantra_mfs_100/event")
        channel.setMethodCallHandler(this)
        setStreamHandler()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {

        Log.i("onMethodCall"," ${call.method} ")

        when(call.method){

            "init" ->{
                result.success(mfs100.Init())
            }

            "autoCapture" ->{

                val map = call.arguments as Map<String, Any>
                val fingerData=FingerData()
                val ret= mfs100.AutoCapture(fingerData, map["timeout"] as Int,map["detectFinger"] as Boolean)

                if (ret==0){

                    val data=HashMap<String,Any>()
                    data["finger_image"]=fingerData.FingerImage()
                    data["quality"]=fingerData.Quality()
                    data["nfiq"]=fingerData.Nfiq()
                    data["raw_data"]=fingerData.RawData()
                    data["iso_template"]=fingerData.ISOTemplate()
                    data["in_width"]=fingerData.InWidth()
                    data["in_height"]=fingerData.InHeight()
                    data["in_area"]=fingerData.InArea()
                    data["resolution"]=fingerData.Resolution()
                    data["greyscale"]=fingerData.GrayScale()
                    data["bpp"]=fingerData.Bpp()
                    data["wsq_compress_ratio"]=fingerData.WSQCompressRatio()
                    data["wsq_info"]=fingerData.WSQInfo()

                    result.success(data)

                }else{
                    result.error(ret.toString(),mfs100.GetErrorMsg(ret),null)
                }

            }

            "matchISO" ->{
                val map = call.arguments as Map<*, *>
                val ret= mfs100.MatchISO(map["firstTemplate"] as ByteArray ,map["secondTemplate"] as ByteArray)
                result.success(ret)
            }

            "stopAutoCapture" ->{
                result.success(mfs100.StopAutoCapture())
            }

            "getPlatformVersion" ->{
                result.success(0)
            }

            "getErrorMessage" ->{
                val map = call.arguments as Map<*, *>
                result.success(mfs100.GetErrorMsg(map["error"] as Int))
            }

            "dispose" ->{
                mfs100.Dispose()
            }

            "unInit" ->{
                result.success(mfs100.UnInit())
            }

            else -> result.notImplemented()

        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun showToast(msg:String){

        Toast.makeText(mContext,msg, Toast.LENGTH_SHORT).show();

    }

    private fun setStreamHandler(){

        val streamHandler= object: StreamHandler{

            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                Log.e("onListen->","$events")
                showToast("onListening")

                mfsEvent=object:MFS100Event{

                    override fun OnDeviceAttached(vid: Int, pid: Int, hasPermission: Boolean) {
                        if (SystemClock.elapsedRealtime() - mLastAttTime < Threshold) {
                            return
                        }
                        mLastAttTime = SystemClock.elapsedRealtime()
                        val ret: Int
                        if (!hasPermission) {
                            //SetTextOnUIThread("Permission denied")
                            return
                        }
                        try {
                            if (vid == 1204 || vid == 11279) {
                                if (pid == 34323) {
                                    ret = mfs100.LoadFirmware()
                                    if (ret != 0) {
                                      //  SetTextOnUIThread(mfs100.GetErrorMsg(ret))
                                    } else {
//                                        SetTextOnUIThread("Load firmware success")
                                        val hsp=HashMap<String,Any>()
                                        hsp["eventName"] = "Connected"
                                        hsp["hasPermission"] = hasPermission
                                        events.success(hsp)
                                    }
                                } else if (pid == 4101) {
                                    val key = "Without Key"
                                    ret = mfs100.Init()
                                    if (ret == 0) {
                                       // showSuccessLog(key)
                                        val hsp=HashMap<String,Any>()
                                        hsp["eventName"] = "Connected"
                                        hsp["hasPermission"] = hasPermission
                                        events.success(hsp)
                                    }/* else {
                                        SetTextOnUIThread(mfs100.GetErrorMsg(ret))
                                    }*/
                                }
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }

                    // events.success()
                    }

                    override fun OnDeviceDetached() {
                        val hsp=HashMap<String,Any>()
                        hsp["eventName"] = "Disconnected"
                        events.success(hsp)
                    }

                    override fun OnHostCheckFailed(p0: String) {
                        val hsp=HashMap<String,Any>()
                        hsp["eventName"] = "HostCheckFailed"
                        hsp["var1"] = p0
                        events.success(hsp)
                    }

                }

                if(!isMfsInitialized){
                    initMfs()
                    isMfsInitialized=true
                }

            }

            override fun onCancel(arguments: Any?) {

            }

        }
        eventChannel.setStreamHandler(streamHandler)
    }

    private fun initMfs(){
        mfs100= MFS100(mfsEvent)
        mfs100.SetApplicationContext(mContext)
    }

}