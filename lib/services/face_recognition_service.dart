import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../vars.dart' as vars;

class FaceRecognitionService {
  static const _enrolledFaceKeyBase = 'enrolled_face_path';

  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isInitializingCamera = false;
  bool _cameraOpInProgress = false;
  Completer<void>? _opCompleter;
  String? _enrolledFaceImagePath;
  FaceDetector? _faceDetector;

  /// Load enrolled face path from persistent storage
  /// Load enrolled face path for given employee id (or current logged in id)
  Future<void> loadEnrolledFace([int? empId]) async {
    try {
      final id = empId ?? vars.empId;
      if (id == 0) return;
      final prefs = await SharedPreferences.getInstance();
      final key = '$_enrolledFaceKeyBase\_$id';
      _enrolledFaceImagePath = prefs.getString(key);
      if (_enrolledFaceImagePath != null) {
        print('Loaded enrolled face for emp $id: $_enrolledFaceImagePath');
      }
    } catch (e) {
      print('Error loading enrolled face: $e');
    }
  }

  /// Initialize ML Kit face detector lazily
  void _ensureFaceDetectorInitialized() {
    if (_faceDetector != null) return;
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: false,
      enableContours: false,
      enableClassification: false,
    );
    _faceDetector = FaceDetector(options: options);
  }

  /// Save enrolled face path to persistent storage
  Future<void> _saveEnrolledFace(String path, [int? empId]) async {
    try {
      final id = empId ?? vars.empId;
      if (id == 0) return;
      final prefs = await SharedPreferences.getInstance();
      final key = '$_enrolledFaceKeyBase\_$id';
      await prefs.setString(key, path);
      print('Saved enrolled face for emp $id to storage: $path');
    } catch (e) {
      print('Error saving enrolled face: $e');
    }
  }

  /// Clear enrolled face from persistent storage
  Future<void> _clearEnrolledFaceFromStorage([int? empId]) async {
    try {
      final id = empId ?? vars.empId;
      if (id == 0) return;
      final prefs = await SharedPreferences.getInstance();
      final key = '$_enrolledFaceKeyBase\_$id';
      await prefs.remove(key);
      print('Cleared enrolled face from storage for emp $id');
    } catch (e) {
      print('Error clearing enrolled face from storage: $e');
    }
  }

  /// Detect whether an image file contains at least one face using ML Kit.
  /// Returns list of detected faces (may be empty).
  Future<List<Face>> _detectFacesInImagePath(String path) async {
    try {
      _ensureFaceDetectorInitialized();
      if (_faceDetector == null) return <Face>[];
      final inputImage = InputImage.fromFilePath(path);
      final faces = await _faceDetector!.processImage(inputImage);
      return faces;
    } catch (e) {
      print('Face detection error for $path: $e');
      return <Face>[];
    }
  }

  /// Public wrapper for face detection on a file path.
  Future<List<Face>> detectFacesInImagePath(String path) async {
    return await _detectFacesInImagePath(path);
  }

  /// Initialize camera
  Future<bool> initializeCamera() async {
    try {
      // Prevent multiple concurrent initializations
      if (_isCameraInitialized) return true;
      if (_isInitializingCamera) {
        // Wait briefly for any ongoing initialization to finish
        var tries = 0;
        while (_isInitializingCamera && tries++ < 20) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        return _isCameraInitialized;
      }
      _isInitializingCamera = true;

      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;

      // Use front camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
      );

      await _cameraController?.initialize();
      _isCameraInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing camera: $e');
      return false;
    } finally {
      _isInitializingCamera = false;
    }
  }

  /// Get camera controller for live preview
  CameraController? get cameraController => _cameraController;

  /// Check if camera is initialized
  bool get isCameraInitialized => _isCameraInitialized;

  /// Enroll a face by capturing from camera
  Future<bool> enrollFace() async {
    try {
      // Initialize camera if not already done
      if (!_isCameraInitialized) {
        final initialized = await initializeCamera();
        if (!initialized) {
          print('Failed to initialize camera');
          return false;
        }
      }

      if (_cameraController == null || !_isCameraInitialized) {
        print('Camera not initialized');
        return false;
      }

      // Capture image (serialized)
      if (_cameraOpInProgress) {
        print('Camera operation in progress, enrollFace aborted');
        return false;
      }
      _cameraOpInProgress = true;
      _opCompleter = Completer<void>();

      final XFile image = await _cameraController!.takePicture();

      if (image.path.isEmpty) {
        print('Failed to capture image');
        return false;
      }

      // Store the enrolled face image path (in-memory)
      _enrolledFaceImagePath = image.path;
      // Persist for current employee id
      await _saveEnrolledFace(image.path);
      print('Face enrolled from: ${image.path}');
      return true;
    } catch (e) {
      print('Error enrolling face: $e');
      return false;
    } finally {
      _cameraOpInProgress = false;
      try {
        _opCompleter?.complete();
      } catch (_) {}
      _opCompleter = null;
    }
  }

  /// Authenticate by capturing a new face image and comparing with enrolled face.
  /// Returns the captured image path on success (if similarity >= 0.7), or null on failure.
  Future<String?> authenticateFace() async {
    try {
      if (_enrolledFaceImagePath == null) {
        print('No enrolled face found');
        return null;
      }

      // Initialize camera if not already done
      if (!_isCameraInitialized) {
        final initialized = await initializeCamera();
        if (!initialized) {
          print('Failed to initialize camera');
          return null;
        }
      }

      if (_cameraController == null || !_isCameraInitialized) {
        print('Camera not initialized');
        return null;
      }

      // Capture image for authentication (serialized)
      if (_cameraOpInProgress) {
        print('Camera operation already in progress, authenticate aborted');
        return null;
      }
      _cameraOpInProgress = true;
      _opCompleter = Completer<void>();

      final XFile image = await _cameraController!.takePicture();

      if (image.path.isEmpty) {
        print('Failed to capture authentication image');
        return null;
      }

      print('Face captured for authentication from: ${image.path}');

      // Compare with enrolled face
      final similarity =
          await compareFaces(_enrolledFaceImagePath!, image.path);
      print('Face match similarity: $similarity');

      // Accept match if similarity >= threshold. Raised threshold to reduce false positives.
      const matchThreshold = 0.65;
      if (similarity >= matchThreshold) {
        print('Face authentication successful (similarity: $similarity)');
        return image.path;
      } else {
        print(
            'Face does not match enrolled face (similarity: $similarity, threshold: $matchThreshold)');
        return null;
      }
    } catch (e) {
      print('Error authenticating face: $e');
      return null;
    } finally {
      _cameraOpInProgress = false;
      try {
        _opCompleter?.complete();
      } catch (_) {}
      _opCompleter = null;
    }
  }

  /// Check if a face is enrolled
  bool isFaceEnrolled() => _enrolledFaceImagePath != null;

  /// Get enrolled face image path
  String? getEnrolledFacePath() => _enrolledFaceImagePath;

  /// Clear enrolled face
  Future<void> clearEnrolledFace() async {
    _enrolledFaceImagePath = null;
    // Also clear from storage for current employee
    await _clearEnrolledFaceFromStorage();
  }

  /// Save enrolled face from an XFile captured by UI
  Future<bool> saveEnrolledFaceFromXFile(XFile file, [int? empId]) async {
    try {
      if (file.path.isEmpty) return false;
      _enrolledFaceImagePath = file.path;
      print('Face enrolled from UI: ${file.path}');
      // Persist to storage
      await _saveEnrolledFace(file.path, empId);
      return true;
    } catch (e) {
      print('Error saving enrolled face from file: $e');
      return false;
    }
  }

  /// Compare two face images and return similarity score (0.0 to 1.0)
  /// Higher score = more similar. Threshold of 0.7+ is considered a match.
  Future<double> compareFaces(String enrolledPath, String authPath) async {
    try {
      final enrolledFile = File(enrolledPath);
      final authFile = File(authPath);

      if (!enrolledFile.existsSync() || !authFile.existsSync()) {
        print('One or both face images do not exist');
        return 0.0;
      }

      // Decode images
      final enrolledImage = img.decodeImage(enrolledFile.readAsBytesSync());
      final authImage = img.decodeImage(authFile.readAsBytesSync());

      if (enrolledImage == null || authImage == null) {
        print('Failed to decode one or both images');
        return 0.0;
      }

      // Use ML Kit to detect faces and crop to face bounding boxes if possible
      // Fallback to full image if no face detected.
      img.Image faceEnrolled = enrolledImage;
      img.Image faceAuth = authImage;

      try {
        final enrolledFaces = await _detectFacesInImagePath(enrolledPath);
        final authFaces = await _detectFacesInImagePath(authPath);

        if (enrolledFaces.isNotEmpty) {
          final r = enrolledFaces.first.boundingBox;
          faceEnrolled = _cropToBoundsWithRotationAndPadding(enrolledImage, r);
        }
        if (authFaces.isNotEmpty) {
          final r = authFaces.first.boundingBox;
          faceAuth = _cropToBoundsWithRotationAndPadding(authImage, r);
        }
      } catch (e) {
        print('Error during face detection/cropping: $e');
        // continue with full images
      }

      // Resize both images to the same size for comparison
      final targetSize = 128;
      final resizedEnrolled =
          img.copyResize(faceEnrolled, width: targetSize, height: targetSize);
      final resizedAuth =
          img.copyResize(faceAuth, width: targetSize, height: targetSize);

      // Calculate histogram for each image
      final enrolledHist = _calculateHistogram(resizedEnrolled);
      final authHist = _calculateHistogram(resizedAuth);

      // Compare histograms using chi-square distance
      final similarity = _compareHistograms(enrolledHist, authHist);

      print('Face similarity score: $similarity');
      return similarity;
    } catch (e) {
      print('Error comparing faces: $e');
      return 0.0;
    }
  }

  /// Calculate normalized histogram of image (simplified grayscale histogram)
  /// Returns a list of 256 doubles summing approximately to 1.0
  List<double> _calculateHistogram(img.Image image) {
    final histogram = List<int>.filled(256, 0);
    final totalPixels = image.width * image.height;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixelSafe(x, y);
        // Convert to grayscale
        final gray =
            (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b).toInt();
        histogram[gray.clamp(0, 255)]++;
      }
    }

    // Normalize to probabilities
    final normalized = List<double>.filled(256, 0.0);
    if (totalPixels > 0) {
      for (var i = 0; i < 256; i++) {
        normalized[i] = histogram[i] / totalPixels;
      }
    }
    return normalized;
  }

  /// Compare two histograms using normalized chi-square distance
  /// Returns similarity score from 0.0 to 1.0
  double _compareHistograms(List<double> hist1, List<double> hist2) {
    double chiSquare = 0.0;
    double bhattacharyya = 0.0;

    for (int i = 0; i < hist1.length; i++) {
      final diff = hist1[i] - hist2[i];
      final sum = hist1[i] + hist2[i];
      if (sum > 0) {
        chiSquare += (diff * diff) / sum;
      }

      // Bhattacharyya coefficient contribution
      bhattacharyya +=
          (hist1[i] > 0 && hist2[i] > 0) ? math.sqrt(hist1[i] * hist2[i]) : 0.0;
    }

    // Chi-square similarity (lower chi-square => higher similarity)
    final chiSim = 1.0 / (1.0 + chiSquare * 10.0);

    // Bhattacharyya coefficient is already in [0,1], higher means more similar
    final bhatt = bhattacharyya.clamp(0.0, 1.0);

    // Combine both metrics for robustness (average)
    final similarity = (chiSim + bhatt) / 2.0;

    print('chiSim: $chiSim, bhatt: $bhatt, combined similarity: $similarity');
    return similarity.clamp(0.0, 1.0);
  }

  /// Dispose resources
  Future<void> dispose() async {
    // If a camera operation is in progress, wait briefly for it to finish
    if (_cameraOpInProgress && _opCompleter != null) {
      try {
        // Wait up to 2 seconds for the operation to complete
        await Future.any(
            [_opCompleter!.future, Future.delayed(const Duration(seconds: 2))]);
      } catch (_) {}
    }

    try {
      await _cameraController?.dispose();
    } catch (e) {
      print('Error disposing camera controller: $e');
    }
    _cameraController = null;
    _isCameraInitialized = false;
    try {
      await _faceDetector?.close();
    } catch (e) {
      print('Error disposing face detector: $e');
    }
    _faceDetector = null;
  }

  /// Crop an image to the provided ML Kit [ui.Rect] bounding box.
  /// If the rect is out of bounds, it will be clamped to the image.
  img.Image _cropToBounds(img.Image src, ui.Rect rect) {
    // Deprecated: use _cropToBoundsWithRotationAndPadding for robust cropping
    final int left = rect.left.round().clamp(0, src.width - 1);
    final int top = rect.top.round().clamp(0, src.height - 1);
    final int right = rect.right.round().clamp(0, src.width);
    final int bottom = rect.bottom.round().clamp(0, src.height);
    final int w = (right - left).clamp(1, src.width - left);
    final int h = (bottom - top).clamp(1, src.height - top);
    try {
      return img.copyCrop(src, x: left, y: top, width: w, height: h);
    } catch (e) {
      print('Error cropping image to bounds: $e');
      return src;
    }
  }

  /// Try cropping the image to [rect], attempting common rotations and
  /// adding a small padding around the bounding box. This helps when the
  /// decoded image orientation does not match the coordinates returned by
  /// ML Kit (EXIF/rotation differences).
  img.Image _cropToBoundsWithRotationAndPadding(img.Image src, ui.Rect rect) {
    const double paddingFactor = 0.2; // 20% padding around face box

    // Helper to apply padding and clamp
    img.Image _tryCrop(img.Image candidate) {
      final int left = (rect.left - rect.width * paddingFactor)
          .round()
          .clamp(0, candidate.width - 1);
      final int top = (rect.top - rect.height * paddingFactor)
          .round()
          .clamp(0, candidate.height - 1);
      final int right = (rect.right + rect.width * paddingFactor)
          .round()
          .clamp(0, candidate.width);
      final int bottom = (rect.bottom + rect.height * paddingFactor)
          .round()
          .clamp(0, candidate.height);
      final int w = (right - left).clamp(1, candidate.width - left);
      final int h = (bottom - top).clamp(1, candidate.height - top);
      try {
        return img.copyCrop(candidate, x: left, y: top, width: w, height: h);
      } catch (e) {
        // return original candidate if crop fails
        return candidate;
      }
    }

    // Perform a padded crop on the original source image. Rotation heuristics
    // were removed because rotation helpers vary between image package
    // versions; this still adds padding to capture full face region.
    final cropped = _tryCrop(src);
    if (kDebugMode) {
      try {
        final tmpDir = Directory.systemTemp.path;
        final fname = 'face_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final out = File('${tmpDir}${Platform.pathSeparator}$fname');
        out.writeAsBytesSync(img.encodeJpg(cropped));
        print('Saved debug face crop: ${out.path}');
      } catch (_) {}
    }
    return cropped;
  }

  /// Capture a still image (front camera) for attendance logging.
  /// Returns the file path of the captured image, or null on failure.
  Future<String?> captureAttendanceImage() async {
    // Delegate to serialized safe capture implementation
    return await safeCaptureAttendanceImage();
  }

  /// A safe wrapper to capture attendance image that serializes access.
  Future<String?> safeCaptureAttendanceImage() async {
    try {
      if (!_isCameraInitialized) {
        final initialized = await initializeCamera();
        if (!initialized) {
          print('Failed to initialize camera for attendance capture');
          return null;
        }
      }

      if (_cameraController == null || !_isCameraInitialized) {
        print('Camera not initialized for attendance capture');
        return null;
      }

      if (_cameraOpInProgress) {
        print('Camera operation in progress, attendance capture aborted');
        return null;
      }

      _cameraOpInProgress = true;
      _opCompleter = Completer<void>();

      final XFile image = await _cameraController!.takePicture();
      if (image.path.isEmpty) {
        print('Attendance capture failed: empty path');
        return null;
      }

      print('Attendance image captured: ${image.path}');
      return image.path;
    } catch (e) {
      print('Error capturing attendance image: $e');
      return null;
    } finally {
      _cameraOpInProgress = false;
      try {
        _opCompleter?.complete();
      } catch (_) {}
      _opCompleter = null;
      // Do NOT dispose here; let caller decide when to dispose.
    }
  }
}
