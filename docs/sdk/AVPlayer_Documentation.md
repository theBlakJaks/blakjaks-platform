* [AVFoundation](https://developer.apple.com/documentation/avfoundation)  
* AVPlayer

Class

# **AVPlayer**

An object that provides the interface to control the player’s transport behavior.  
iOS 4.0+iPadOS 4.0+Mac Catalyst 13.1+macOS 10.7+tvOS 9.0+visionOS 1.0+watchOS 1.0+

```

@MainActor
class AVPlayer
```

## [**Mentioned in**](https://developer.apple.com/documentation/avfoundation/avplayer#mentions)

[Controlling the transport behavior of a player](https://developer.apple.com/documentation/avfoundation/controlling-the-transport-behavior-of-a-player)

[Observing playback state in SwiftUI](https://developer.apple.com/documentation/avfoundation/observing-playback-state-in-swiftui)

[Supporting AirPlay in your app](https://developer.apple.com/documentation/avfoundation/supporting-airplay-in-your-app)

[Implementing simple enhanced buffering for your content](https://developer.apple.com/documentation/avfoundation/implementing-simple-enhanced-buffering-for-your-content)

[Monitoring playback progress in your app](https://developer.apple.com/documentation/avfoundation/monitoring-playback-progress-in-your-app)

## [**Overview**](https://developer.apple.com/documentation/avfoundation/avplayer#overview)

A player is a controller object that manages the playback and timing of a media asset. Use an instance of [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer) to play local and remote file-based media, such as QuickTime movies and MP3 audio files, as well as audiovisual media served using HTTP Live Streaming.

Use a player object to play a single media asset. You can reuse the player instance to play additional media assets using its [replaceCurrentItem(with:)](https://developer.apple.com/documentation/avfoundation/avplayer/replacecurrentitem\(with:\)) method, but it manages the playback of only a single media asset at a time. The framework also provides a subclass called [AVQueuePlayer](https://developer.apple.com/documentation/avfoundation/avqueueplayer) that you can use to manage the playback of a queue of media assets.

You use an [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer) to play media assets, which AVFoundation represents using the [AVAsset](https://developer.apple.com/documentation/avfoundation/avasset) class. [AVAsset](https://developer.apple.com/documentation/avfoundation/avasset) only models the *static* aspects of the media, such as its duration or creation date, and on its own, isn’t suitable for playback with an [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer). To play an asset, you create an instance of its *dynamic* counterpart found in [AVPlayerItem](https://developer.apple.com/documentation/avfoundation/avplayeritem). This object models the timing and presentation state of an asset played by an instance of [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer). See the [AVPlayerItem](https://developer.apple.com/documentation/avfoundation/avplayeritem) reference for more details.

[AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer) is a dynamic object whose state continuously changes. There are two approaches you can use to observe a player’s state:

* General State Observations: You can use key-value observing (KVO) to observe state changes to many of the player’s dynamic properties, such as its [currentItem](https://developer.apple.com/documentation/avfoundation/avplayer/currentitem) or its playback [rate](https://developer.apple.com/documentation/avfoundation/avplayer/rate).  
* Timed State Observations: KVO works well for general state observations, but isn’t intended for observing continuously changing state like the player’s time. [AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer) provides two methods to observe time changes:  
* [addPeriodicTimeObserver(forInterval:queue:using:)](https://developer.apple.com/documentation/avfoundation/avplayer/addperiodictimeobserver\(forinterval:queue:using:\))  
* [addBoundaryTimeObserver(forTimes:queue:using:)](https://developer.apple.com/documentation/avfoundation/avplayer/addboundarytimeobserver\(fortimes:queue:using:\))

These methods let you observe time changes either periodically or by boundary, respectively. As changes occur, invoke the callback block or closure you supply to these methods to give you the opportunity to take some action such as updating the state of your player’s user interface.

[AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer) and [AVPlayerItem](https://developer.apple.com/documentation/avfoundation/avplayeritem) are nonvisual objects, meaning that on their own they’re unable to present an asset’s video onscreen. There are two primary approaches you use to present your video content onscreen:

* AVKit: The best way to present your video content is with the AVKit framework’s [AVPlayerViewController](https://developer.apple.com/documentation/AVKit/AVPlayerViewController) class in iOS and tvOS, or the [AVPlayerView](https://developer.apple.com/documentation/AVKit/AVPlayerView) class in macOS. These classes present the video content, along with playback controls and other media features giving you a full-featured playback experience.  
* AVPlayerLayer: When building a custom interface for your player, use [AVPlayerLayer](https://developer.apple.com/documentation/avfoundation/avplayerlayer). You can set this layer a view’s backing layer or add it directly to the layer hierarchy. Unlike [AVPlayerView](https://developer.apple.com/documentation/AVKit/AVPlayerView) and [AVPlayerViewController](https://developer.apple.com/documentation/AVKit/AVPlayerViewController), a player layer doesn’t present any playback controls—it only presents the visual content onscreen. It’s up to you to build the playback transport controls to play, pause, and seek through the media.

Alongside the visual content presented with AVKit or [AVPlayerLayer](https://developer.apple.com/documentation/avfoundation/avplayerlayer), you can also present animated content synchronized with the player’s timing using [AVSynchronizedLayer](https://developer.apple.com/documentation/avfoundation/avsynchronizedlayer). Use a synchronized layer pass along player timing to its layer subtree. You can use [AVSynchronizedLayer](https://developer.apple.com/documentation/avfoundation/avsynchronizedlayer) to build custom effects in Core Animation, such as animated lower thirds or video transitions, and have them play in sync with the timing of the player’s current [AVPlayerItem](https://developer.apple.com/documentation/avfoundation/avplayeritem).

## [**Topics**](https://developer.apple.com/documentation/avfoundation/avplayer#topics)

### [**Creating a player**](https://developer.apple.com/documentation/avfoundation/avplayer#Creating-a-player)

[init(url: URL)](https://developer.apple.com/documentation/avfoundation/avplayer/init\(url:\))

Creates a new player to play a single audiovisual resource referenced by a given URL.

[init(playerItem: AVPlayerItem?)](https://developer.apple.com/documentation/avfoundation/avplayer/init\(playeritem:\))

Creates a new player to play the specified player item.

[init()](https://developer.apple.com/documentation/avfoundation/avplayer/init\(\))

Creates a player object.

### [**Managing the player item**](https://developer.apple.com/documentation/avfoundation/avplayer#Managing-the-player-item)

[var currentItem: AVPlayerItem?](https://developer.apple.com/documentation/avfoundation/avplayer/currentitem)

The item for which the player is currently controlling playback.

[func replaceCurrentItem(with: AVPlayerItem?)](https://developer.apple.com/documentation/avfoundation/avplayer/replacecurrentitem\(with:\))

Replaces the current item with a new item.

### [**Determining player readiness**](https://developer.apple.com/documentation/avfoundation/avplayer#Determining-player-readiness)

[var status: AVPlayer.Status](https://developer.apple.com/documentation/avfoundation/avplayer/status-swift.property)

A value that indicates the readiness of a player object for playback.

[enum Status](https://developer.apple.com/documentation/avfoundation/avplayer/status-swift.enum)

Status values that indicate whether a player can successfully play media.

[var error: (any Error)?](https://developer.apple.com/documentation/avfoundation/avplayer/error)

An error that caused a failure.

### [**Controlling playback**](https://developer.apple.com/documentation/avfoundation/avplayer#Controlling-playback)

[var defaultRate: Float](https://developer.apple.com/documentation/avfoundation/avplayer/defaultrate)

A default rate at which to begin playback.

[func play()](https://developer.apple.com/documentation/avfoundation/avplayer/play\(\))

Begins playback of the current item.

[func pause()](https://developer.apple.com/documentation/avfoundation/avplayer/pause\(\))

Pauses playback of the current item.

[var rate: Float](https://developer.apple.com/documentation/avfoundation/avplayer/rate)

The current playback rate.

[class let rateDidChangeNotification: NSNotification.Name](https://developer.apple.com/documentation/avfoundation/avplayer/ratedidchangenotification)

A notification that a player posts when its rate changes.

### [**Observing playback time**](https://developer.apple.com/documentation/avfoundation/avplayer#Observing-playback-time)

[func currentTime() \-\> CMTime](https://developer.apple.com/documentation/avfoundation/avplayer/currenttime\(\))

Returns the current time of the current player item.

[func addPeriodicTimeObserver(forInterval: CMTime, queue: dispatch\_queue\_t?, using: (CMTime) \-\> Void) \-\> Any](https://developer.apple.com/documentation/avfoundation/avplayer/addperiodictimeobserver\(forinterval:queue:using:\))

Requests the periodic invocation of a given block during playback to report changing time.

[func addBoundaryTimeObserver(forTimes: \[NSValue\], queue: dispatch\_queue\_t?, using: () \-\> Void) \-\> Any](https://developer.apple.com/documentation/avfoundation/avplayer/addboundarytimeobserver\(fortimes:queue:using:\))

Requests the invocation of a block when specified times are traversed during normal playback.

[func removeTimeObserver(Any)](https://developer.apple.com/documentation/avfoundation/avplayer/removetimeobserver\(_:\))

Cancels a previously registered periodic or boundary time observer.

### [**Seeking through media**](https://developer.apple.com/documentation/avfoundation/avplayer#Seeking-through-media)

[func seek(to: CMTime)](https://developer.apple.com/documentation/avfoundation/avplayer/seek\(to:\)-87h2r)

Requests that the player seek to a specified time.

[func seek(to: CMTime, completionHandler: (Bool) \-\> Void)](https://developer.apple.com/documentation/avfoundation/avplayer/seek\(to:completionhandler:\)-75bls)

Requests that the player seek to a specified time, and to notify you when the seek is complete.

[func seek(to: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime)](https://developer.apple.com/documentation/avfoundation/avplayer/seek\(to:tolerancebefore:toleranceafter:\))

Requests that the player seek to a specified time with the amount of accuracy specified by the time tolerance values.

[func seek(to: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: (Bool) \-\> Void)](https://developer.apple.com/documentation/avfoundation/avplayer/seek\(to:tolerancebefore:toleranceafter:completionhandler:\))

Requests that the player seek to a specified time with the amount of accuracy specified by the time tolerance values, and to notify you when the seek is complete.

[func seek(to: Date)](https://developer.apple.com/documentation/avfoundation/avplayer/seek\(to:\)-9h9qr)

Requests that the player seek to a specified date.

[func seek(to: Date, completionHandler: (Bool) \-\> Void)](https://developer.apple.com/documentation/avfoundation/avplayer/seek\(to:completionhandler:\)-wr1l)

Requests that the player seek to a specified date, and to notify you when the seek is complete.

### [**Configuring waiting behavior**](https://developer.apple.com/documentation/avfoundation/avplayer#Configuring-waiting-behavior)

[var automaticallyWaitsToMinimizeStalling: Bool](https://developer.apple.com/documentation/avfoundation/avplayer/automaticallywaitstominimizestalling)

A Boolean value that indicates whether the player should automatically delay playback in order to minimize stalling.

[var reasonForWaitingToPlay: AVPlayer.WaitingReason?](https://developer.apple.com/documentation/avfoundation/avplayer/reasonforwaitingtoplay)

The reason the player is currently waiting for playback to begin or resume.

[struct WaitingReason](https://developer.apple.com/documentation/avfoundation/avplayer/waitingreason)

The reasons a player is waiting to begin or resume playback.

[var timeControlStatus: AVPlayer.TimeControlStatus](https://developer.apple.com/documentation/avfoundation/avplayer/timecontrolstatus-swift.property)

A value that indicates whether playback is in progress, paused indefinitely, or waiting for network conditions to improve.

[enum TimeControlStatus](https://developer.apple.com/documentation/avfoundation/avplayer/timecontrolstatus-swift.enum)

Constants that indicate the state of playback control.

[func playImmediately(atRate: Float)](https://developer.apple.com/documentation/avfoundation/avplayer/playimmediately\(atrate:\))

Plays the available media data immediately, at the specified rate.

### [**Responding when playback ends**](https://developer.apple.com/documentation/avfoundation/avplayer#Responding-when-playback-ends)

[var actionAtItemEnd: AVPlayer.ActionAtItemEnd](https://developer.apple.com/documentation/avfoundation/avplayer/actionatitemend-swift.property)

The action to perform when the current player item has finished playing.

[enum ActionAtItemEnd](https://developer.apple.com/documentation/avfoundation/avplayer/actionatitemend-swift.enum)

The actions a player can take when it finishes playing.

### [**Configuring media selection criteria**](https://developer.apple.com/documentation/avfoundation/avplayer#Configuring-media-selection-criteria)

[var appliesMediaSelectionCriteriaAutomatically: Bool](https://developer.apple.com/documentation/avfoundation/avplayer/appliesmediaselectioncriteriaautomatically)

A Boolean value that indicates whether the receiver should apply the current selection criteria automatically to player items.

[func mediaSelectionCriteria(forMediaCharacteristic: AVMediaCharacteristic) \-\> AVPlayerMediaSelectionCriteria?](https://developer.apple.com/documentation/avfoundation/avplayer/mediaselectioncriteria\(formediacharacteristic:\))

Returns the automatic selection criteria for media items with the specified media characteristic.

[func setMediaSelectionCriteria(AVPlayerMediaSelectionCriteria?, forMediaCharacteristic: AVMediaCharacteristic)](https://developer.apple.com/documentation/avfoundation/avplayer/setmediaselectioncriteria\(_:formediacharacteristic:\))

Applies automatic selection criteria for media that has the specified media characteristic.

### [**Accessing player output**](https://developer.apple.com/documentation/avfoundation/avplayer#Accessing-player-output)

[var videoOutput: AVPlayerVideoOutput?](https://developer.apple.com/documentation/avfoundation/avplayer/videooutput)

The video output for this player.

### [**Configuring audio behavior**](https://developer.apple.com/documentation/avfoundation/avplayer#Configuring-audio-behavior)

[var volume: Float](https://developer.apple.com/documentation/avfoundation/avplayer/volume)

The audio playback volume for the player.

[var isMuted: Bool](https://developer.apple.com/documentation/avfoundation/avplayer/ismuted)

A Boolean value that indicates whether the audio output of the player is muted.

[var allowedAudioSpatializationFormats: AVAudioSpatializationFormats](https://developer.apple.com/documentation/avfoundation/avplayeritem/allowedaudiospatializationformats)

The source audio channel layouts the player item supports for spatialization.

[~~var isAudioSpatializationAllowed: Bool~~](https://developer.apple.com/documentation/avfoundation/avplayeritem/isaudiospatializationallowed)

A Boolean value that indicates whether the player item allows spatialized audio playback.

Deprecated

[var audioOutputSuppressedDueToNonMixableAudioRoute: Bool](https://developer.apple.com/documentation/avfoundation/avplayer/audiooutputsuppressedduetononmixableaudioroute)

Whether the player’s audio output is suppressed due to being on a non-mixable audio route.

[var intendedSpatialAudioExperience: any SpatialAudioExperience](https://developer.apple.com/documentation/avfoundation/avplayer/intendedspatialaudioexperience-1bd87)

The player’s intended Spatial Audio experience.

### [**Configuring background playback**](https://developer.apple.com/documentation/avfoundation/avplayer#Configuring-background-playback)

[var audiovisualBackgroundPlaybackPolicy: AVPlayerAudiovisualBackgroundPlaybackPolicy](https://developer.apple.com/documentation/avfoundation/avplayer/audiovisualbackgroundplaybackpolicy)

A policy that determines how playback of audiovisual media continues when the app transitions to the background.

[enum AVPlayerAudiovisualBackgroundPlaybackPolicy](https://developer.apple.com/documentation/avfoundation/avplayeraudiovisualbackgroundplaybackpolicy)

Policies that describe playback behavior when an app transitions to the background while playing video.

### [**Managing external playback**](https://developer.apple.com/documentation/avfoundation/avplayer#Managing-external-playback)

[var allowsExternalPlayback: Bool](https://developer.apple.com/documentation/avfoundation/avplayer/allowsexternalplayback)

A Boolean value that indicates whether the player allows switching to external playback mode.

[var isExternalPlaybackActive: Bool](https://developer.apple.com/documentation/avfoundation/avplayer/isexternalplaybackactive)

A Boolean value that indicates whether the player is currently playing video in external playback mode.

[var usesExternalPlaybackWhileExternalScreenIsActive: Bool](https://developer.apple.com/documentation/avfoundation/avplayer/usesexternalplaybackwhileexternalscreenisactive)

A Boolean value that indicates whether the player should automatically switch to external playback mode while the external screen mode is active.

[var externalPlaybackVideoGravity: AVLayerVideoGravity](https://developer.apple.com/documentation/avfoundation/avplayer/externalplaybackvideogravity)

The video gravity of the player for external playback mode only.

### [**Determining HDR playback eligibility**](https://developer.apple.com/documentation/avfoundation/avplayer#Determining-HDR-playback-eligibility)

[class var eligibleForHDRPlayback: Bool](https://developer.apple.com/documentation/avfoundation/avplayer/eligibleforhdrplayback)

A Boolean value that indicates whether the current device can present content to an HDR display.

[~~class var availableHDRModes: AVPlayer.HDRMode~~](https://developer.apple.com/documentation/avfoundation/avplayer/availablehdrmodes)

The HDR modes that are available for playback.

Deprecated

[~~struct HDRMode~~](https://developer.apple.com/documentation/avfoundation/avplayer/hdrmode)

A bitfield type that specifies an HDR mode.

Deprecated

[class let eligibleForHDRPlaybackDidChangeNotification: NSNotification.Name](https://developer.apple.com/documentation/avfoundation/avplayer/eligibleforhdrplaybackdidchangenotification)

A notification that’s posted whenever HDR playback eligibility changes.

### [**Coordinating playback**](https://developer.apple.com/documentation/avfoundation/avplayer#Coordinating-playback)

[var playbackCoordinator: AVPlayerPlaybackCoordinator](https://developer.apple.com/documentation/avfoundation/avplayer/playbackcoordinator)

The playback coordinator for the player.

### [**Synchronizing multiple players**](https://developer.apple.com/documentation/avfoundation/avplayer#Synchronizing-multiple-players)

[func setRate(Float, time: CMTime, atHostTime: CMTime)](https://developer.apple.com/documentation/avfoundation/avplayer/setrate\(_:time:athosttime:\))

Synchronizes the playback rate and time of the current item with an external source.

[func preroll(atRate: Float, completionHandler: ((Bool) \-\> Void)?)](https://developer.apple.com/documentation/avfoundation/avplayer/preroll\(atrate:completionhandler:\))

Begins loading media data to prime the media pipelines for playback.

[func cancelPendingPrerolls()](https://developer.apple.com/documentation/avfoundation/avplayer/cancelpendingprerolls\(\))

Cancels any pending preroll requests and invokes the corresponding completion handlers, if present.

[var sourceClock: CMClock?](https://developer.apple.com/documentation/avfoundation/avplayer/sourceclock)

A clock the player uses for item time bases.

[~~var masterClock: CMClock?~~](https://developer.apple.com/documentation/avfoundation/avplayer/masterclock)

The host clock for item time bases.

Deprecated

### [**Preventing sleep and backgrounding**](https://developer.apple.com/documentation/avfoundation/avplayer#Preventing-sleep-and-backgrounding)

[var preventsDisplaySleepDuringVideoPlayback: Bool](https://developer.apple.com/documentation/avfoundation/avplayer/preventsdisplaysleepduringvideoplayback)

A Boolean value that indicates whether video playback prevents display and device sleep.

[var preventsAutomaticBackgroundingDuringVideoPlayback: Bool](https://developer.apple.com/documentation/avfoundation/avplayer/preventsautomaticbackgroundingduringvideoplayback)

A Boolean value that indicates whether video playback prevents the system from automatically backgrounding the app.

### [**Determining content protections**](https://developer.apple.com/documentation/avfoundation/avplayer#Determining-content-protections)

[var isOutputObscuredDueToInsufficientExternalProtection: Bool](https://developer.apple.com/documentation/avfoundation/avplayer/isoutputobscuredduetoinsufficientexternalprotection)

A Boolean value that indicates whether output is being obscured because of insufficient external protection.

### [**Configuring audio and video devices**](https://developer.apple.com/documentation/avfoundation/avplayer#Configuring-audio-and-video-devices)

[var audioOutputDeviceUniqueID: String?](https://developer.apple.com/documentation/avfoundation/avplayer/audiooutputdeviceuniqueid)

Specifies the unique ID of the Core Audio output device used to play audio.

[var preferredVideoDecoderGPURegistryID: UInt64](https://developer.apple.com/documentation/avfoundation/avplayer/preferredvideodecodergpuregistryid)

The registry identifier for the GPU used for video decoding.

### [**Configuring the network resource priority**](https://developer.apple.com/documentation/avfoundation/avplayer#Configuring-the-network-resource-priority)

[var networkResourcePriority: AVPlayer.NetworkResourcePriority](https://developer.apple.com/documentation/avfoundation/avplayer/networkresourcepriority-swift.property)

Indicates the priority of this player for network bandwidth resource distribution.

[enum NetworkResourcePriority](https://developer.apple.com/documentation/avfoundation/avplayer/networkresourcepriority-swift.enum)

This defines the network resource priority for a player.

### [**Configuring observation**](https://developer.apple.com/documentation/avfoundation/avplayer#Configuring-observation)

[class var isObservationEnabled: Bool](https://developer.apple.com/documentation/avfoundation/avplayer/isobservationenabled)

AVPlayer and other AVFoundation types can optionally be observed using Swift Observation.

### [**Configuring AirPlay behavior**](https://developer.apple.com/documentation/avfoundation/avplayer#Configuring-AirPlay-behavior)

[~~var allowsAirPlayVideo: Bool~~](https://developer.apple.com/documentation/avfoundation/avplayer/allowsairplayvideo)

A Boolean value that indicates whether the player allows AirPlay video playback.

Deprecated

[~~var isAirPlayVideoActive: Bool~~](https://developer.apple.com/documentation/avfoundation/avplayer/isairplayvideoactive)

A Boolean value that indicates whether the player is playing video through AirPlay.

Deprecated

[~~var usesAirPlayVideoWhileAirPlayScreenIsActive: Bool~~](https://developer.apple.com/documentation/avfoundation/avplayer/usesairplayvideowhileairplayscreenisactive)

A Boolean value that indicates whether the player automatically switches to AirPlay Video while AirPlay Screen is active.

Deprecated

### [**Displaying closed captions**](https://developer.apple.com/documentation/avfoundation/avplayer#Displaying-closed-captions)

[~~var isClosedCaptionDisplayEnabled: Bool~~](https://developer.apple.com/documentation/avfoundation/avplayer/isclosedcaptiondisplayenabled)

A Boolean value that indicates whether the player uses closed captioning.

Deprecated

### [**Instance Properties**](https://developer.apple.com/documentation/avfoundation/avplayer#Instance-Properties)

[var allowsCaptureOfClearKeyVideo: Bool](https://developer.apple.com/documentation/avfoundation/avplayer/allowscaptureofclearkeyvideo)

Indicates whether the video output of ClearKey Encrypted Video can be captured

Beta

## [**Relationships**](https://developer.apple.com/documentation/avfoundation/avplayer#relationships)

### [**Inherits From**](https://developer.apple.com/documentation/avfoundation/avplayer#inherits-from)

* [NSObject](https://developer.apple.com/documentation/ObjectiveC/NSObject-swift.class)

### [**Inherited By**](https://developer.apple.com/documentation/avfoundation/avplayer#inherited-by)

* [AVQueuePlayer](https://developer.apple.com/documentation/avfoundation/avqueueplayer)

### [**Conforms To**](https://developer.apple.com/documentation/avfoundation/avplayer#conforms-to)

* [AVRoutingPlaybackParticipant](https://developer.apple.com/documentation/AVRouting/AVRoutingPlaybackParticipant)  
* [CVarArg](https://developer.apple.com/documentation/Swift/CVarArg)  
* [Copyable](https://developer.apple.com/documentation/Swift/Copyable)  
* [CustomDebugStringConvertible](https://developer.apple.com/documentation/Swift/CustomDebugStringConvertible)  
* [CustomStringConvertible](https://developer.apple.com/documentation/Swift/CustomStringConvertible)  
* [Equatable](https://developer.apple.com/documentation/Swift/Equatable)  
* [Escapable](https://developer.apple.com/documentation/Swift/Escapable)  
* [Hashable](https://developer.apple.com/documentation/Swift/Hashable)  
* [NSObjectProtocol](https://developer.apple.com/documentation/ObjectiveC/NSObjectProtocol)  
* [Observable](https://developer.apple.com/documentation/Observation/Observable)  
* [Sendable](https://developer.apple.com/documentation/Swift/Sendable)

## [**See Also**](https://developer.apple.com/documentation/avfoundation/avplayer#see-also)

### [**Playback control**](https://developer.apple.com/documentation/avfoundation/avplayer#Playback-control)

[Observing playback state in SwiftUI](https://developer.apple.com/documentation/avfoundation/observing-playback-state-in-swiftui)

Keep your user interface in sync with state changes from playback objects.

[Controlling the transport behavior of a player](https://developer.apple.com/documentation/avfoundation/controlling-the-transport-behavior-of-a-player)

Play, pause, and seek through a media presentation.

[Creating a seamless multiview playback experience](https://developer.apple.com/documentation/avfoundation/creating-a-seamless-multiview-playback-experience)

Build advanced multiview playback experiences with the AVFoundation and AVRouting frameworks.

[class AVPlayerItem](https://developer.apple.com/documentation/avfoundation/avplayeritem)

An object that models the timing and presentation state of an asset during playback.

[class AVPlayerItemTrack](https://developer.apple.com/documentation/avfoundation/avplayeritemtrack)

An object that represents the presentation state of an asset track during playback.

[class AVQueuePlayer](https://developer.apple.com/documentation/avfoundation/avqueueplayer)

An object that plays a sequence of player items.

[class AVPlayerLooper](https://developer.apple.com/documentation/avfoundation/avplayerlooper)

An object that loops media content using a queue player.  
https://developer.apple.com/documentation/avfoundation/avplayer