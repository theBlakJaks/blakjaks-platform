* [AVFoundation](https://developer.apple.com/documentation/avfoundation)  
* AVCaptureMetadataOutput

Class

# **AVCaptureMetadataOutput**

A capture output for processing timed metadata produced by a capture session.  
iOS 6.0+iPadOS 6.0+Mac Catalyst 14.0+macOS 13.0+tvOS 17.0+

```

class AVCaptureMetadataOutput
```

## [**Overview**](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput#overview)

An AVCaptureMetadataOutput object intercepts metadata objects emitted by its associated capture connection and forwards them to a delegate object for processing. You can use instances of this class to process specific types of metadata included with the input data. You use this class the way you do other output objects, typically by adding it as an output to an [AVCaptureSession](https://developer.apple.com/documentation/avfoundation/avcapturesession) object.

## [**Topics**](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput#topics)

### [**Creating metadata output**](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput#Creating-metadata-output)

[init()](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput/init\(\))

Creates a new capture metadata output.

### [**Configuring metadata capture**](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput#Configuring-metadata-capture)

[var availableMetadataObjectTypes: \[AVMetadataObject.ObjectType\]](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput/availablemetadataobjecttypes)

An array of strings identifying the types of metadata objects that can be captured.

[var metadataObjectTypes: \[AVMetadataObject.ObjectType\]\!](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput/metadataobjecttypes)

An array of strings identifying the types of metadata objects to process.

[var rectOfInterest: CGRect](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput/rectofinterest)

A rectangle of interest for limiting the search area for visual metadata.

[var requiredMetadataObjectTypesForCinematicVideoCapture: \[AVMetadataObject.ObjectType\]](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput/requiredmetadataobjecttypesforcinematicvideocapture)

The required metadata object types when Cinematic Video capture is enabled.

### [**Receiving captured metadata objects**](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput#Receiving-captured-metadata-objects)

[func setMetadataObjectsDelegate((any AVCaptureMetadataOutputObjectsDelegate)?, queue: dispatch\_queue\_t?)](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput/setmetadataobjectsdelegate\(_:queue:\))

Sets the delegate and dispatch queue to use handle callbacks.

[var metadataObjectsDelegate: (any AVCaptureMetadataOutputObjectsDelegate)?](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput/metadataobjectsdelegate)

The delegate of the capture metadata output object.

[var metadataObjectsCallbackQueue: dispatch\_queue\_t?](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput/metadataobjectscallbackqueue)

The dispatch queue on which to execute the delegate’s methods.

[protocol AVCaptureMetadataOutputObjectsDelegate](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutputobjectsdelegate)

Methods for receiving metadata produced by a metadata capture output.

## [**Relationships**](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput#relationships)

### [**Inherits From**](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput#inherits-from)

* [AVCaptureOutput](https://developer.apple.com/documentation/avfoundation/avcaptureoutput)

### [**Conforms To**](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput#conforms-to)

* [CVarArg](https://developer.apple.com/documentation/Swift/CVarArg)  
* [CustomDebugStringConvertible](https://developer.apple.com/documentation/Swift/CustomDebugStringConvertible)  
* [CustomStringConvertible](https://developer.apple.com/documentation/Swift/CustomStringConvertible)  
* [Equatable](https://developer.apple.com/documentation/Swift/Equatable)  
* [Hashable](https://developer.apple.com/documentation/Swift/Hashable)  
* [NSObjectProtocol](https://developer.apple.com/documentation/ObjectiveC/NSObjectProtocol)

## [**See Also**](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput#see-also)

### [**Metadata capture**](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput#Metadata-capture)

[class AVCaptureMetadataInput](https://developer.apple.com/documentation/avfoundation/avcapturemetadatainput)

A capture input for providing timed metadata to a capture session.

[class AVMetadataObject](https://developer.apple.com/documentation/avfoundation/avmetadataobject)

The abstract superclass for objects provided by a metadata capture output.

[Metadata types](https://developer.apple.com/documentation/avfoundation/metadata-types)

Inspect the supported metadata object types that the framework supports.

* [AVFoundation](https://developer.apple.com/documentation/avfoundation)  
* AVMetadataMachineReadableCodeObject

Class

# **AVMetadataMachineReadableCodeObject**

Barcode information detected by a metadata capture output.  
iOS 7.0+iPadOS 7.0+Mac Catalyst 14.0+macOS 10.15+tvOS 9.0+

```

class AVMetadataMachineReadableCodeObject
```

## [**Overview**](https://developer.apple.com/documentation/avfoundation/avmetadatamachinereadablecodeobject#overview)

The AVMetadataMachineReadableCodeObject class is a concrete subclass of [AVMetadataObject](https://developer.apple.com/documentation/avfoundation/avmetadataobject) defining the features of a detected one-dimensional or two-dimensional barcode.

An AVMetadataMachineReadableCodeObject instance represents a single detected machine readable code in an image.  It’s an immutable object describing the features and payload of a barcode.

On supported platforms, the [AVCaptureMetadataOutput](https://developer.apple.com/documentation/avfoundation/avcapturemetadataoutput) class outputs arrays of detected machine readable code objects.

## [**Topics**](https://developer.apple.com/documentation/avfoundation/avmetadatamachinereadablecodeobject#topics)

### [**Getting machine-readable code values**](https://developer.apple.com/documentation/avfoundation/avmetadatamachinereadablecodeobject#Getting-machine-readable-code-values)

[var corners: \[CGPoint\]](https://developer.apple.com/documentation/avfoundation/avmetadatamachinereadablecodeobject/corners-58qbe)

A Swift array of corner points.

[var descriptor: CIBarcodeDescriptor?](https://developer.apple.com/documentation/avfoundation/avmetadatamachinereadablecodeobject/descriptor)

A barcode description for use in Core Image.

[var stringValue: String?](https://developer.apple.com/documentation/avfoundation/avmetadatamachinereadablecodeobject/stringvalue)

Returns the error-corrected data decoded into a human-readable string.

### [**Constants**](https://developer.apple.com/documentation/avfoundation/avmetadatamachinereadablecodeobject#Constants)

[Machine-readable object types](https://developer.apple.com/documentation/avfoundation/machine-readable-object-types)

Constants used to specify the type of barcode to scan.

## [**Relationships**](https://developer.apple.com/documentation/avfoundation/avmetadatamachinereadablecodeobject#relationships)

### [**Inherits From**](https://developer.apple.com/documentation/avfoundation/avmetadatamachinereadablecodeobject#inherits-from)

* [AVMetadataObject](https://developer.apple.com/documentation/avfoundation/avmetadataobject)

### [**Conforms To**](https://developer.apple.com/documentation/avfoundation/avmetadatamachinereadablecodeobject#conforms-to)

* [CVarArg](https://developer.apple.com/documentation/Swift/CVarArg)  
* [CustomDebugStringConvertible](https://developer.apple.com/documentation/Swift/CustomDebugStringConvertible)  
* [CustomStringConvertible](https://developer.apple.com/documentation/Swift/CustomStringConvertible)  
* [Equatable](https://developer.apple.com/documentation/Swift/Equatable)  
* [Hashable](https://developer.apple.com/documentation/Swift/Hashable)  
* [NSObjectProtocol](https://developer.apple.com/documentation/ObjectiveC/NSObjectProtocol)

Sample Code

# **AVCamBarcode: detecting barcodes and faces**

Identify machine readable codes or faces by using the camera.

[Download](https://docs-assets.developer.apple.com/published/306f40997d58/AVCamBarcodeDetectingBarcodesAndFaces.zip)  
iOS 15.0+iPadOS 15.0+Mac Catalyst 15.0+Xcode 16.0+

## [**Overview**](https://developer.apple.com/documentation/avfoundation/avcambarcode-detecting-barcodes-and-faces#Overview)

Note

This sample code project is associated with WWDC21 session [10047: What’s New in Camera Capture](https://developer.apple.com/videos/play/wwdc21/10047/).

## [**See Also**](https://developer.apple.com/documentation/avfoundation/avcambarcode-detecting-barcodes-and-faces#see-also)

### [**Capture sessions**](https://developer.apple.com/documentation/avfoundation/avcambarcode-detecting-barcodes-and-faces#Capture-sessions)

[Setting up a capture session](https://developer.apple.com/documentation/avfoundation/setting-up-a-capture-session)

Configure input devices, output media, preview views, and basic settings before capturing photos or video.

[Accessing the camera while multitasking on iPad](https://developer.apple.com/documentation/AVKit/accessing-the-camera-while-multitasking-on-ipad)

Operate the camera in Split View, Slide Over, Picture in Picture, and Stage Manager modes.

[AVCam: Building a camera app](https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app)

Capture photos and record video using the front and rear iPhone and iPad cameras.

[Capturing Cinematic video](https://developer.apple.com/documentation/avfoundation/capturing-cinematic-video)

Capture video with an adjustable depth of field and focus points.

[AVMultiCamPiP: Capturing from Multiple Cameras](https://developer.apple.com/documentation/avfoundation/avmulticampip-capturing-from-multiple-cameras)

Simultaneously record the output from the front and back cameras into a single movie file by using a multi-camera capture session.

[class AVCaptureSession](https://developer.apple.com/documentation/avfoundation/avcapturesession)

An object that configures capture behavior and coordinates the flow of data from input devices to capture outputs.

[class AVCaptureMultiCamSession](https://developer.apple.com/documentation/avfoundation/avcapturemulticamsession)

A capture session that supports simultaneous capture from multiple inputs of the same media type.

[class AVCaptureInput](https://developer.apple.com/documentation/avfoundation/avcaptureinput)

An abstract superclass for objects that provide input data to a capture session.

[class AVCaptureOutput](https://developer.apple.com/documentation/avfoundation/avcaptureoutput)

An abstract superclass for objects that provide media output destinations for a capture session.

[class AVCaptureConnection](https://developer.apple.com/documentation/avfoundation/avcaptureconnection)

An object that represents a connection from a capture input to a capture output.  
[https://developer.apple.com/documentation/avfoundation/avcambarcode-detecting-barcodes-and-faces](https://developer.apple.com/documentation/avfoundation/avcambarcode-detecting-barcodes-and-faces) 