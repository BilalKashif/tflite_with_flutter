package com.example.obj_det

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.support.image.TensorImage
import org.tensorflow.lite.task.core.BaseOptions
import org.tensorflow.lite.task.vision.detector.ObjectDetector

class MainActivity: FlutterActivity() {


  /*
  * Channel name through which we communicate with flutter app
  */
    private val CHANNEL = "RunModel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            val args = call.arguments as HashMap<*, *>
            if (call.method == "objectDetection") {
                result.success(runObjectDetection(args["path"].toString()))
            } else {
                result.notImplemented()
            }
        }
    }

    // -----Convert the image from url into bitmap
    fun convertBitmap(imageUri: String): Bitmap {
        val bitmap: Bitmap = BitmapFactory.decodeFile(imageUri)
        return bitmap
    }

    private fun runObjectDetection(
        imageUri: String,
    ): List<HashMap<String, String>> { // Use ByteArray if you want to return U8list

        // -------List of detected objects------
        var finalRes: MutableList<HashMap<String, String>> = mutableListOf<HashMap<String, String>>()
        //--------Image Bitmap------------------

        var bitmap : Bitmap = convertBitmap(imageUri)

        // Step 1: Create TFLite's TensorImage object
        val image = TensorImage.fromBitmap(bitmap)

        // This code enables Gpu delegate------
        //------Check if Gpu is available------
         val baseOptions =  BaseOptions.builder().setNumThreads(4)

        // if(CompatibilityList().isDelegateSupportedOnThisDevice){
        //   Log.d("GPU Delegate", "Gpu is available")
        //   baseOptions.useGpu()
        // }else{
        //   Log.d("GPU Delegate", "Gpu is not available in this deviece")
        // }
        //------------------------------------


        // Step 2: Initialize the detector object
        val options =
            ObjectDetector.ObjectDetectorOptions.builder()
                 .setBaseOptions(baseOptions.build())
                .setMaxResults(5)
                .setScoreThreshold(0.3f)



        val detector = ObjectDetector.createFromFileAndOptions(this, "efficientdet-lite0.tflite", options.build())

        // Step 3: Feed given image to the detector

        // --------Detected objects lists
        // --------List<Detection>-------
        val results = detector.detect(image)

        // Step 4: Parse the result and return it back to Flutter app
        for ((i, obj) in results.withIndex()) {

            var tempMap: HashMap<String, String> = HashMap<String, String>()
            val box = obj.boundingBox

            tempMap.put("width", "${bitmap.width}")
            tempMap.put("height", "${bitmap.height}")
            tempMap.put("boundingBox", "${box.left},${box.top},${box.right},${box.bottom}")

            for ((j, category) in obj.categories.withIndex()) {
                tempMap.put("name", "${category.label}")
                val confidence: Int = category.score.times(100).toInt()
                tempMap.put("confidence", "${confidence}%")
            }
            finalRes.add(tempMap)
        }

        return finalRes
    }
}
