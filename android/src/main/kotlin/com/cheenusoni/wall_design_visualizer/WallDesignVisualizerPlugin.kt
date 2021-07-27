package com.cheenusoni.wall_design_visualizer

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Environment
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.opencv.android.Utils
import org.opencv.core.*
import org.opencv.imgproc.Imgproc
import java.io.File
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*
import kotlin.collections.ArrayList
import kotlin.math.roundToInt

/** WallDesignVisualizerPlugin */
class WallDesignVisualizerPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "wall_design_visualizer")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
        "getPlatformVersion" -> {
          result.success("Android ${android.os.Build.VERSION.RELEASE}")
        }
        "paintWallDesign" -> {
          val plane0bytes: ByteArray? = call.argument("Uint8List bytes for plane 0")
          val plane1bytes: ByteArray? = call.argument("Uint8List bytes for plane 1")
          val plane2bytes: ByteArray? = call.argument("Uint8List bytes for plane 2")
          val wallDesignImagePath: String? = call.argument("wallDesignImagePath")
          val viewportHeight: Double? = call.argument("viewportHeight")
          val viewportWidth: Double? = call.argument("viewportWidth")
          val xTap: Double? = call.argument("xTap")
          val yTap: Double? = call.argument("yTap")

          val processImage = ProcessImage(viewportHeight ?: 0.0,viewportWidth?: 0.0,wallDesignImagePath ?: "")
          val outputImagePath = processImage.applyTexture(yuvToBitmap(plane0bytes!!+ plane1bytes!!+plane2bytes!!, viewportWidth!!.toInt(),viewportHeight!!.toInt())!!,Point(xTap?:0.0,yTap?:0.0))

          result.success(outputImagePath)
        }
        else -> {
          result.notImplemented()
        }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun yuvToBitmap(data: ByteArray, width: Int, height: Int): Bitmap? {
    val frameSize = width * height
    val rgba = IntArray(frameSize)
    for (i in 0 until height) for (j in 0 until width) {
      var y = 0xff and data[i * width + j].toInt()
      val u = 0xff and data[frameSize + (i shr 1) * width + (j and 1.inv()) + 0].toInt()
      val v = 0xff and data[frameSize + (i shr 1) * width + (j and 1.inv()) + 1].toInt()
      y = if (y < 16) 16 else y
      var r = (1.164f * (y - 16) + 1.596f * (v - 128)).roundToInt()
      var g = (1.164f * (y - 16) - 0.813f * (v - 128) - 0.391f * (u - 128)).roundToInt()
      var b = (1.164f * (y - 16) + 2.018f * (u - 128)).roundToInt()
      r = if (r < 0) 0 else if (r > 255) 255 else r
      g = if (g < 0) 0 else if (g > 255) 255 else g
      b = if (b < 0) 0 else if (b > 255) 255 else b
      rgba[i * width + j] = -0x1000000 + (b shl 16) + (g shl 8) + r
    }
    val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    bmp.setPixels(rgba, 0, width, 0, 0, width, height)
    return bmp
  }

  inner class ProcessImage(private var heightOfViewPort: Double,
                           private var widthOfViewPort: Double,
                           private var wallDesignImagePath: String) {

    private val TAG = "ProcessImage"
    private lateinit var imageFilePath: String

    fun applyTexture(bitmap: Bitmap, p: Point) : String? {
      val cannyMinThres = 30.0
      val ratio = 2.5

      // show intermediate step results
      // grid created here to do that
      //showResultLayouts()

      val mRgbMat = Mat()
      Utils.bitmapToMat(bitmap, mRgbMat)

      showImage(mRgbMat)

      Imgproc.cvtColor(mRgbMat,mRgbMat, Imgproc.COLOR_RGBA2RGB)

      val mask = Mat(Size(mRgbMat.width()/8.0, mRgbMat.height()/8.0), CvType.CV_8UC1, Scalar(0.0))
//        Imgproc.dilate(mRgbMat, mRgbMat,mask, Point(0.0,0.0), 5)

      val img = Mat()
      mRgbMat.copyTo(img)

      // grayscale
      val mGreyScaleMat = Mat()
      Imgproc.cvtColor(mRgbMat, mGreyScaleMat, Imgproc.COLOR_RGB2GRAY, 3)
      Imgproc.medianBlur(mGreyScaleMat,mGreyScaleMat,3)


      val cannyGreyMat = Mat()
      Imgproc.Canny(mGreyScaleMat, cannyGreyMat, cannyMinThres, cannyMinThres*ratio, 3)

      showImage(cannyGreyMat)

      //hsv
      val hsvImage = Mat()
      Imgproc.cvtColor(img,hsvImage, Imgproc.COLOR_RGB2HSV)

      //got the hsv values
      val list = ArrayList<Mat>(3)
      Core.split(hsvImage, list)

      val sChannelMat = Mat()
      Core.merge(listOf(list[1]), sChannelMat)
      Imgproc.medianBlur(sChannelMat,sChannelMat,3)
      showImage(sChannelMat)

      // canny
      val cannyMat = Mat()
      Imgproc.Canny(sChannelMat, cannyMat, cannyMinThres, cannyMinThres*ratio, 3)
      showImage(cannyMat)

      Core.addWeighted(cannyMat,0.5, cannyGreyMat,0.5 ,0.0,cannyMat)
      Imgproc.dilate(cannyMat, cannyMat,mask, Point(0.0,0.0), 5)

      val height = heightOfViewPort
      val width = widthOfViewPort

      val seedPoint = Point(p.x*(mRgbMat.width()/width.toDouble()), p.y*(mRgbMat.height()/height.toDouble()))

      Imgproc.resize(cannyMat, cannyMat, Size(cannyMat.width() + 2.0, cannyMat.height() + 2.0))
      val cannyMat1 = Mat()
      cannyMat.copyTo(cannyMat1)

//        Imgproc.medianBlur(mRgbMat,mRgbMat,15)

      val wallMask = Mat(mRgbMat.size(),mRgbMat.type())

      val floodFillFlag = 8
      Imgproc.floodFill(
              wallMask,
              cannyMat,
              seedPoint,
              Scalar(255.0,255.0,255.0/*chosenColor.toDouble(),chosenColor.toDouble(),chosenColor.toDouble()*/),
              Rect(),
              Scalar(5.0, 5.0, 5.0),
              Scalar(5.0, 5.0, 5.0),
              floodFillFlag
      )
      showImage(wallMask)

      showImage(cannyMat)

      //second floodfill is not working 5
      Imgproc.floodFill(
              mRgbMat,
              cannyMat1,
              seedPoint,
              Scalar(0.0,0.0,0.0/*chosenColor.toDouble(),chosenColor.toDouble(),chosenColor.toDouble()*/),
              Rect(),
              Scalar(5.0, 5.0, 5.0),
              Scalar(5.0, 5.0, 5.0),
              floodFillFlag
      )
      showImage(mRgbMat)

      val texture = getTextureImage(wallDesignImagePath)

      val textureImgMat = Mat()
      Core.bitwise_and(wallMask ,texture,textureImgMat)

      showImage(textureImgMat)

      val resultImage = Mat()
      Core.bitwise_or(textureImgMat,mRgbMat,resultImage)

      showImage(resultImage)

      ////alpha blending

      //got the hsv of the mask image
      val rgbHsvImage = Mat()
      Imgproc.cvtColor(resultImage,rgbHsvImage, Imgproc.COLOR_RGB2HSV)

      val list1 = ArrayList<Mat>(3)
      Core.split(rgbHsvImage, list1)

      //merged the "v" of original image with mRgb mat
      val result = Mat()
      Core.merge(listOf(list1.get(0),list1.get(1),list.get(2)), result)

      // converted to rgb
      Imgproc.cvtColor(result, result, Imgproc.COLOR_HSV2RGB)

      Core.addWeighted(result,0.8, img,0.2 ,0.0,result )

      //showImage(result)
      val mBitmap = Bitmap.createBitmap(result.cols(), result.rows(), Bitmap.Config.ARGB_8888);
      Utils.matToBitmap(result, mBitmap)
      val pictureFile = createImageFile()
      try {
        val fos = FileOutputStream(pictureFile);
        mBitmap.compress(Bitmap.CompressFormat.PNG, 90, fos)
        fos.close()
        Log.i(TAG, "Path of the output image: ${pictureFile.path}")
        return pictureFile.path
      } catch (e: FileNotFoundException) {
        Log.e(TAG, "File not found: " + e.message)
      } catch (e: IOException) {
        Log.e(TAG, "Error accessing file: " + e.message)
      }
      return null
    }

    private fun showImage(image: Mat) {
      val mBitmap = Bitmap.createBitmap(image.cols(), image.rows(), Bitmap.Config.ARGB_8888);
      Utils.matToBitmap(image, mBitmap)
      // view.setImageBitmap(mBitmap)

      saveImage(mBitmap)
    }

    private fun saveImage(image: Bitmap) {
      val pictureFile = createImageFile()
      try {
        val fos = FileOutputStream(pictureFile);
        image.compress(Bitmap.CompressFormat.PNG, 90, fos)
        fos.close()
      } catch (e: FileNotFoundException) {
        Log.e(TAG, "File not found: " + e.message)
      } catch (e: IOException) {
        Log.e(TAG, "Error accessing file: " + e.message)
      }
    }

    private fun createImageFile(): File {
      val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format( Date())
      val imageFileName = "IMG_" + timeStamp + "_"
      val storageDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)  // Warning: This way of getting directory might throw exception
      val image = File.createTempFile(
              imageFileName,   //prefix
              ".jpg",          //suffix
              storageDir      // directory
      )

      imageFilePath = image.absolutePath
      return image;
    }

    private fun getTextureImage(imagePath: String): Mat {
      val image: File = File(imagePath)
      val bmOptions = BitmapFactory.Options()
      var textureImage = BitmapFactory.decodeFile(image.absolutePath, bmOptions)   // Warning: This way of giving the path might throw exception
      textureImage = Bitmap.createScaledBitmap(textureImage,widthOfViewPort.toInt(),heightOfViewPort.toInt(),true)
      val texture = Mat()
      Utils.bitmapToMat(textureImage,texture)
      Imgproc.cvtColor(texture,texture,Imgproc.COLOR_RGBA2RGB)
      return texture
    }
  }
}
