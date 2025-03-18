// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
#if SKIP
import Foundation
import SkipFoundation
import org.webrtc.__
import kotlinx.coroutines.tasks.await

// Delegate protocol for WebRTC events
public protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data)
    func webRTCClient(_ client: WebRTCClient, dataChannelDidChangeState state: RTCDataChannelState)
    func webRTCClient(_ client: WebRTCClient, didFinishAudioSessionInit state: RTCDataChannelState?)
    func webRTCClient(_ client: WebRTCClient, didDetectAudioCompletion: Void)
}

// RTCIceConnectionState enum to match iOS WebRTC
public enum RTCIceConnectionState: Int {
    case new = 0
    case checking = 1
    case connected = 2
    case completed = 3
    case failed = 4
    case disconnected = 5
    case closed = 6
    case count = 7
    
    static func fromPlatformState(_ state: org.webrtc.PeerConnection.IceConnectionState) -> RTCIceConnectionState {
        switch state {
        case org.webrtc.PeerConnection.IceConnectionState.NEW: return .new
        case org.webrtc.PeerConnection.IceConnectionState.CHECKING: return .checking
        case org.webrtc.PeerConnection.IceConnectionState.CONNECTED: return .connected
        case org.webrtc.PeerConnection.IceConnectionState.COMPLETED: return .completed
        case org.webrtc.PeerConnection.IceConnectionState.FAILED: return .failed
        case org.webrtc.PeerConnection.IceConnectionState.DISCONNECTED: return .disconnected
        case org.webrtc.PeerConnection.IceConnectionState.CLOSED: return .closed
        default:
            // Log unknown state for debugging
            print("WARNING: Unknown RTCIceConnectionState encountered")
            return .new
        }
    }
}

// RTCDataChannelState enum to match iOS WebRTC
public enum RTCDataChannelState: Int {
    case connecting = 0
    case open = 1
    case closing = 2
    case closed = 3
    
    static func fromPlatformState(_ state: org.webrtc.DataChannel.State) -> RTCDataChannelState {
        switch state {
        case org.webrtc.DataChannel.State.CONNECTING: return .connecting
        case org.webrtc.DataChannel.State.OPEN: return .open
        case org.webrtc.DataChannel.State.CLOSING: return .closing
        case org.webrtc.DataChannel.State.CLOSED: return .closed
        default:
            print("WARNING: Unknown RTCDataChannelState encountered")
            return .closed
        }
    }
}

// RTCSessionDescription class bridging iOS to Android
public class RTCSessionDescription: KotlinConverting<org.webrtc.SessionDescription> {
    public let platformDescription: org.webrtc.SessionDescription
    
    public init(_ platformDescription: org.webrtc.SessionDescription) {
        self.platformDescription = platformDescription
    }
    
    public init(type: RTCSessionDescriptionType, sdp: String) {
        self.platformDescription = org.webrtc.SessionDescription(type.toPlatformType(), sdp)
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.SessionDescription {
        return platformDescription
    }
    
    public var type: RTCSessionDescriptionType {
        switch platformDescription.type {
        case org.webrtc.SessionDescription.Type.OFFER: return .offer
        case org.webrtc.SessionDescription.Type.ANSWER: return .answer
        case org.webrtc.SessionDescription.Type.PRANSWER: return .prAnswer
        default:
            print("WARNING: Unknown RTCSessionDescriptionType")
            return .offer
        }
    }
    
    public var sdp: String {
        return platformDescription.description
    }
}

// RTCSessionDescriptionType enum to match iOS WebRTC
public enum RTCSessionDescriptionType: Int {
    case offer = 0
    case prAnswer = 1
    case answer = 2
    
    func toPlatformType() -> org.webrtc.SessionDescription.Type {
        switch self {
        case .offer: return org.webrtc.SessionDescription.Type.OFFER
        case .answer: return org.webrtc.SessionDescription.Type.ANSWER
        case .prAnswer: return org.webrtc.SessionDescription.Type.PRANSWER
        }
    }
}

// RTCIceCandidate class bridging iOS to Android
public class RTCIceCandidate: KotlinConverting<org.webrtc.IceCandidate> {
    public let platformCandidate: org.webrtc.IceCandidate
    
    public init(_ platformCandidate: org.webrtc.IceCandidate) {
        self.platformCandidate = platformCandidate
    }
    
    public init(sdp: String, sdpMLineIndex: Int32, sdpMid: String) {
        self.platformCandidate = org.webrtc.IceCandidate(sdpMid, sdpMLineIndex, sdp)
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.IceCandidate {
        return platformCandidate
    }
    
    public var sdp: String {
        return platformCandidate.sdp
    }
    
    public var sdpMid: String {
        return platformCandidate.sdpMid
    }
    
    public var sdpMLineIndex: Int32 {
        return platformCandidate.sdpMLineIndex
    }
}

// RTCVideoRenderer protocol to match iOS WebRTC
public protocol RTCVideoRenderer {
    func renderFrame(_ frame: RTCVideoFrame)
}

// Class to store VideoSink reference for removing renderers
private class RTCVideoSinkWrapper: KotlinConverting<org.webrtc.VideoSink> {
    public let sink: org.webrtc.VideoSink
    public let renderer: RTCVideoRenderer
    
    init(renderer: RTCVideoRenderer) {
        self.renderer = renderer
        // SKIP INSERT:
        // self.sink = new org.webrtc.VideoSink() {
        //   @Override
        //   public void onFrame(org.webrtc.VideoFrame frame) {
        //     renderer.renderFrame(new RTCVideoFrame(frame));
        //   }
        // };
        self.sink = createVideoSink(renderer)
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.VideoSink {
        return sink
    }
}

private func createVideoSink(_ renderer: RTCVideoRenderer) -> org.webrtc.VideoSink {
    // This is just a placeholder that will be ignored by Skip
    // The actual implementation is provided by the SKIP INSERT directive above
    fatalError("This should never be called in Swift")
    #if SKIP
    return org.webrtc.VideoSink {
        override func onFrame(frame: org.webrtc.VideoFrame) {
            renderer.renderFrame(RTCVideoFrame(frame))
        }
    }
    #endif
}

// RTCVideoFrame class bridging iOS to Android
public class RTCVideoFrame: KotlinConverting<org.webrtc.VideoFrame> {
    public let platformFrame: org.webrtc.VideoFrame
    
    public init(_ platformFrame: org.webrtc.VideoFrame) {
        self.platformFrame = platformFrame
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.VideoFrame {
        return platformFrame
    }
    
    public var width: Int32 {
        return platformFrame.getRotatedWidth()
    }
    
    public var height: Int32 {
        return platformFrame.getRotatedHeight()
    }
    
    public var timestamp: Int64 {
        return platformFrame.getTimestampNs()
    }
}

// RTCDataBuffer class bridging iOS to Android
public class RTCDataBuffer: KotlinConverting<org.webrtc.DataChannel.Buffer> {
    public let platformBuffer: org.webrtc.DataChannel.Buffer
    public let data: Data
    public let isBinary: Bool
    
    public init(data: Data, isBinary: Bool) {
        let byteBuffer = java.nio.ByteBuffer.wrap(data.kotlin())
        self.platformBuffer = org.webrtc.DataChannel.Buffer(byteBuffer, isBinary)
        self.data = data
        self.isBinary = isBinary
    }
    
    public init(_ platformBuffer: org.webrtc.DataChannel.Buffer) {
        self.platformBuffer = platformBuffer
        self.isBinary = platformBuffer.binary
        
        // Convert ByteBuffer to Data
        let byteBuffer = platformBuffer.data
        let initialPosition = byteBuffer.position()
        let bytes = byteBuffer.remaining()
        var byteArray = [Byte](repeating: 0, count: bytes)
        byteBuffer.get(byteArray)
        
        // Reset ByteBuffer position to not affect other readers
        byteBuffer.position(initialPosition)
        
        self.data = Data(kotlin: byteArray.toList().toByteArray())
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.DataChannel.Buffer {
        return platformBuffer
    }
}

// RTCDataChannel class bridging iOS to Android
public class RTCDataChannel: KotlinConverting<org.webrtc.DataChannel> {
    public let platformChannel: org.webrtc.DataChannel
    weak var delegate: RTCDataChannelDelegate?
    private var observer: org.webrtc.DataChannel.Observer?
    
    public init(_ platformChannel: org.webrtc.DataChannel) {
        self.platformChannel = platformChannel
        
        // Create and store observer to avoid garbage collection issues
        let observer = createDataChannelObserver()
        self.observer = observer
        platformChannel.registerObserver(observer)
    }
    
    deinit {
        platformChannel.unregisterObserver()
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.DataChannel {
        return platformChannel
    }
    
    public var readyState: RTCDataChannelState {
        return RTCDataChannelState.fromPlatformState(platformChannel.state())
    }
    
    public var label: String {
        return platformChannel.label()
    }
    
    public var bufferedAmount: Int64 {
        return platformChannel.bufferedAmount()
    }
    
    public func close() {
        platformChannel.close()
    }
    
    public func sendData(_ buffer: RTCDataBuffer) -> Bool {
        return platformChannel.send(buffer.platformBuffer)
    }
}

private func createDataChannelObserver() -> org.webrtc.DataChannel.Observer {
    // This Swift implementation is just a placeholder
    // The actual implementation is provided by the SKIP INSERT directive
    #if !SKIP
    fatalError("This should never be called in native Swift")
    #else
    return createObserver()
    #endif
}


// SKIP INSERT: private fun createObserver(): org.webrtc.DataChannel.Observer {
// SKIP INSERT:   return object : org.webrtc.DataChannel.Observer {
// SKIP INSERT:     override fun onBufferedAmountChange(previousAmount: Long) {
// SKIP INSERT:       // Not used in the current implementation
// SKIP INSERT:     }
// SKIP INSERT:
// SKIP INSERT:     override fun onStateChange() {
// SKIP INSERT:       delegate?.dataChannelDidChangeState(RTCDataChannel(platformChannel))
// SKIP INSERT:     }
// SKIP INSERT:
// SKIP INSERT:     override fun onMessage(buffer: org.webrtc.DataChannel.Buffer) {
// SKIP INSERT:       delegate?.dataChannel(RTCDataChannel(platformChannel), didReceiveMessageWith: RTCDataBuffer(buffer))
// SKIP INSERT:     }
// SKIP INSERT:   }
// SKIP INSERT: }

// RTCDataChannelDelegate protocol to match iOS WebRTC
public protocol RTCDataChannelDelegate: AnyObject {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel)
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer)
}

// RTCAudioTrack class bridging iOS to Android
public class RTCAudioTrack: KotlinConverting<org.webrtc.AudioTrack> {
    public let platformTrack: org.webrtc.AudioTrack
    
    public init(_ platformTrack: org.webrtc.AudioTrack) {
        self.platformTrack = platformTrack
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.AudioTrack {
        return platformTrack
    }
    
    public var isEnabled: Bool {
        get {
            return platformTrack.enabled()
        }
        set {
            platformTrack.setEnabled(newValue)
        }
    }
    
    public var trackId: String {
        return platformTrack.id()
    }
}

// RTCVideoTrack class bridging iOS to Android
public class RTCVideoTrack: KotlinConverting<org.webrtc.VideoTrack> {
    public let platformTrack: org.webrtc.VideoTrack
    private var sinkMap = [ObjectIdentifier: RTCVideoSinkWrapper]()
    
    public init(_ platformTrack: org.webrtc.VideoTrack) {
        self.platformTrack = platformTrack
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.VideoTrack {
        return platformTrack
    }
    
    public var isEnabled: Bool {
        get {
            return platformTrack.enabled()
        }
        set {
            platformTrack.setEnabled(newValue)
        }
    }
    
    public var trackId: String {
        return platformTrack.id()
    }
    
    public func add(_ renderer: RTCVideoRenderer) {
        let key = ObjectIdentifier(renderer as AnyObject)
        let wrapper = RTCVideoSinkWrapper(renderer: renderer)
        sinkMap[key] = wrapper
        platformTrack.addSink(wrapper.sink)
    }
    
    public func remove(_ renderer: RTCVideoRenderer) {
        let key = ObjectIdentifier(renderer as AnyObject)
        if let wrapper = sinkMap[key] {
            platformTrack.removeSink(wrapper.sink)
            sinkMap.removeValue(forKey: key)
        }
    }
}

// RTCVideoCapturer protocol
public protocol RTCVideoCapturer {
    func stopCapture() async
    func startCapture(with device: CaptureDevice, format: CaptureFormat, fps: Int)
}

// RTCCameraVideoCapturer class bridging iOS to Android
public class RTCCameraVideoCapturer: RTCVideoCapturer, KotlinConverting<org.webrtc.Camera2Capturer> {
    public let platformCapturer: org.webrtc.Camera2Capturer
    private var surfaceTextureHelper: org.webrtc.SurfaceTextureHelper?
    private var videoSource: RTCVideoSource?
    
    public init(delegate: RTCVideoSource) {
        self.videoSource = delegate
        let context = ProcessInfo.processInfo.androidContext
        
        // Find a camera
        let cameraManager = context.getSystemService(android.content.Context.CAMERA_SERVICE) as! android.hardware.camera2.CameraManager
        var cameraId = ""
        
        // Try to find front camera first
        for id in cameraManager.cameraIdList {
            let characteristics = cameraManager.getCameraCharacteristics(id)
            let facing = characteristics.get(android.hardware.camera2.CameraCharacteristics.LENS_FACING) as! Int
            if facing == android.hardware.camera2.CameraCharacteristics.LENS_FACING_FRONT {
                cameraId = id
                break
            }
        }
        
        // If no front camera, use any available camera
        if cameraId.isEmpty && cameraManager.cameraIdList.isNotEmpty() {
            cameraId = cameraManager.cameraIdList[0]
        }
        
        // Create event handler
        let eventsHandler = org.webrtc.CameraVideoCapturer.CameraEventsHandler {
            override func onCameraError(error: String) {
                print("Camera error: \(error)")
            }
            
            override func onCameraDisconnected() {
                print("Camera disconnected")
            }
            
            override func onCameraFreezed(error: String) {
                print("Camera freezed: \(error)")
            }
            
            override func onCameraOpening(cameraName: String) {
                print("Camera opening: \(cameraName)")
            }
            
            override func onFirstFrameAvailable() {
                print("First camera frame available")
            }
            
            override func onCameraClosed() {
                print("Camera closed")
            }
        }
        
        if cameraId.isEmpty {
            // No camera available, create a dummy capturer
            print("ERROR: No camera available on this device")
            // This would cause an error but we need to initialize the variable
            self.platformCapturer = org.webrtc.Camera2Capturer(
                context,
                "0", // This is invalid and would fail
                eventsHandler
            )
        } else {
            self.platformCapturer = org.webrtc.Camera2Capturer(
                context,
                cameraId,
                eventsHandler
            )
        }
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.Camera2Capturer {
        return platformCapturer
    }
    
    public static func captureDevices() -> [CaptureDevice] {
        let context = ProcessInfo.processInfo.androidContext
        let cameraManager = context.getSystemService(android.content.Context.CAMERA_SERVICE) as! android.hardware.camera2.CameraManager
        var devices = [CaptureDevice]()
        
        for cameraId in cameraManager.cameraIdList {
            let characteristics = cameraManager.getCameraCharacteristics(cameraId)
            let facing = characteristics.get(android.hardware.camera2.CameraCharacteristics.LENS_FACING) as! Int
            let position: CaptureDevicePosition = facing == android.hardware.camera2.CameraCharacteristics.LENS_FACING_FRONT ? .front : .back
            devices.append(CaptureDevice(deviceId: cameraId, position: position))
        }
        
        return devices
    }
    
    public static func supportedFormats(for device: CaptureDevice) -> [CaptureFormat] {
        let context = ProcessInfo.processInfo.androidContext
        let cameraManager = context.getSystemService(android.content.Context.CAMERA_SERVICE) as! android.hardware.camera2.CameraManager
        var formats = [CaptureFormat]()
        
        do {
            let characteristics = cameraManager.getCameraCharacteristics(device.deviceId)
            if let streamMap = characteristics.get(android.hardware.camera2.CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP) {
                let outputSizes = streamMap.getOutputSizes(android.graphics.ImageFormat.YUV_420_888)
                
                for size in outputSizes {
                    // Create frame rate ranges based on camera capabilities
                    var frameRateRanges = [FrameRateRange]()
                    
                    // Try to get actual supported frame rates if available
                    if let fpsRanges = characteristics.get(android.hardware.camera2.CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES) {
                        for i in 0..<fpsRanges.size {
                            let range = fpsRanges.get(i)
                            frameRateRanges.append(
                                FrameRateRange(
                                    minFrameRate: Double(range.lower),
                                    maxFrameRate: Double(range.upper)
                                )
                            )
                        }
                    } else {
                        // Default frame rate range if not available
                        frameRateRanges.append(FrameRateRange(minFrameRate: 15.0, maxFrameRate: 30.0))
                    }
                    
                    let format = CaptureFormat(
                        width: size.width,
                        height: size.height,
                        frameRateRanges: frameRateRanges
                    )
                    formats.append(format)
                }
            }
        } catch {
            print("Error getting camera formats: \(error)")
        }
        
        return formats
    }
    
    public func startCapture(with device: CaptureDevice, format: CaptureFormat, fps: Int) {
        let threadName = "WebRTCCameraCaptureThread"
        
        // Clean up any previous resources
        if let helper = surfaceTextureHelper {
            helper.dispose()
        }
        
        // Create new surface texture helper
        self.surfaceTextureHelper = org.webrtc.SurfaceTextureHelper.create(
            threadName,
            ProcessInfo.processInfo.androidContext.mainLooper.thread.contextClassLoader
        )
        
        guard let textureHelper = self.surfaceTextureHelper else {
            print("ERROR: Failed to create SurfaceTextureHelper")
            return
        }
        
        guard let source = self.videoSource?.platformSource else {
            print("ERROR: Missing video source for camera capturer")
            return
        }
        
        platformCapturer.initialize(textureHelper, ProcessInfo.processInfo.androidContext, source) {
            platformCapturer.startCapture(format.width, format.height, fps)
        }
    }
    
    public func stopCapture() async {
        // Use an async call to match the iOS API
        // but the Android API is synchronous
        platformCapturer.stopCapture()
        
        // Dispose of the texture helper
        if let helper = surfaceTextureHelper {
            helper.dispose()
            surfaceTextureHelper = nil
        }
    }
}

// Helper classes for camera capture
public class CaptureDevice {
    public let deviceId: String
    public let position: CaptureDevicePosition
    
    public init(deviceId: String, position: CaptureDevicePosition) {
        self.deviceId = deviceId
        self.position = position
    }
}

public enum CaptureDevicePosition {
    case front
    case back
}

public class CaptureFormat {
    public let width: Int
    public let height: Int
    public let videoSupportedFrameRateRanges: [FrameRateRange]
    
    public init(width: Int, height: Int, frameRateRanges: [FrameRateRange]? = nil) {
        self.width = width
        self.height = height
        
        if let ranges = frameRateRanges, !ranges.isEmpty {
            self.videoSupportedFrameRateRanges = ranges
        } else {
            // Default to common frame rates
            self.videoSupportedFrameRateRanges = [FrameRateRange(minFrameRate: 15.0, maxFrameRate: 30.0)]
        }
    }
    
    public var formatDescription: CMFormatDescription {
        return CMFormatDescription(width: width, height: height)
    }
}

public class FrameRateRange {
    public let minFrameRate: Double
    public let maxFrameRate: Double
    
    public init(minFrameRate: Double, maxFrameRate: Double) {
        self.minFrameRate = minFrameRate
        self.maxFrameRate = maxFrameRate
    }
}

// Simplified CMFormatDescription for cross-platform compatibility
public class CMFormatDescription {
    private let width: Int
    private let height: Int
    
    public init(width: Int = 0, height: Int = 0) {
        self.width = width
        self.height = height
    }
    
    public static func getDimensions(_ desc: CMFormatDescription) -> CaptureFormatDimensions {
        return CaptureFormatDimensions(width: desc.width, height: desc.height)
    }
}

public struct CaptureFormatDimensions {
    public let width: Int
    public let height: Int
}

// RTCVideoSource class bridging iOS to Android
public class RTCVideoSource: KotlinConverting<org.webrtc.VideoSource> {
    public let platformSource: org.webrtc.VideoSource
    
    public init(_ platformSource: org.webrtc.VideoSource) {
        self.platformSource = platformSource
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.VideoSource {
        return platformSource
    }
    
    public var state: RTCVideoSourceState {
        let state = platformSource.state()
        switch state {
        case org.webrtc.MediaSource.State.LIVE:
            return .live
        case org.webrtc.MediaSource.State.ENDED:
            return .ended
        case org.webrtc.MediaSource.State.MUTED:
            return .muted
        default:
            print("WARNING: Unknown video source state")
            return .ended
        }
    }
}

// RTCVideoSourceState enum to match iOS API
public enum RTCVideoSourceState {
    case initializing
    case live
    case ended
    case muted
}

// RTCAudioSource class bridging iOS to Android
public class RTCAudioSource: KotlinConverting<org.webrtc.AudioSource> {
    public let platformSource: org.webrtc.AudioSource
    
    public init(_ platformSource: org.webrtc.AudioSource) {
        self.platformSource = platformSource
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.AudioSource {
        return platformSource
    }
    
    public var state: RTCAudioSourceState {
        let state = platformSource.state()
        switch state {
        case org.webrtc.MediaSource.State.LIVE:
            return .live
        case org.webrtc.MediaSource.State.ENDED:
            return .ended
        case org.webrtc.MediaSource.State.MUTED:
            return .muted
        default:
            print("WARNING: Unknown audio source state")
            return .ended
        }
    }
}

// RTCAudioSourceState enum to match iOS API
public enum RTCAudioSourceState {
    case initializing
    case live
    case ended
    case muted
}

// RTCAudioSession class for audio management
public class RTCAudioSession {
    private let audioManager: android.media.AudioManager
    private var audioFocusRequest: android.media.AudioFocusRequest?
    
    private init() {
        self.audioManager = ProcessInfo.processInfo.androidContext.getSystemService(android.content.Context.AUDIO_SERVICE) as! android.media.AudioManager
    }
    
    public static let sharedInstance = RTCAudioSession()
    
    public func lockForConfiguration() {
        // No direct equivalent on Android, but we'll use this as a marker
    }
    
    public func unlockForConfiguration() {
        // No direct equivalent on Android
    }
    
    public func setCategory(_ category: RTCAudioSessionCategory, mode: RTCAudioSessionMode? = nil, options: RTCAudioSessionCategoryOptions = []) throws {
        // Map iOS audio session categories to Android audio modes
        switch category {
        case .playAndRecord:
            audioManager.mode = android.media.AudioManager.MODE_IN_COMMUNICATION
            
            // Handle options
            if options.contains(.defaultToSpeaker) {
                audioManager.isSpeakerphoneOn = true
            }
            
            // Set audio routing if needed based on mode
            if let mode = mode {
                switch mode {
                case .voiceChat:
                    audioManager.mode = android.media.AudioManager.MODE_IN_COMMUNICATION
                case .videoChat:
                    audioManager.mode = android.media.AudioManager.MODE_IN_COMMUNICATION
                    audioManager.isSpeakerphoneOn = true
                }
            }
        case .playback:
            audioManager.mode = android.media.AudioManager.MODE_NORMAL
        }
    }
    
    public func setActive(_ active: Bool) throws {
        // Android doesn't have a direct equivalent, but we can request audio focus
        if active {
            // Create AudioAttributes for the focus request
            let audioAttrs = android.media.AudioAttributes.Builder()
                .setUsage(android.media.AudioAttributes.USAGE_VOICE_COMMUNICATION)
                .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            
            // Create the focus request
            let focusRequest = android.media.AudioFocusRequest.Builder(android.media.AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(audioAttrs)
                .setAcceptsDelayedFocusGain(true)
                .setOnAudioFocusChangeListener { focusChange in
                    // Handle focus changes here if needed
                }
                .build()
            
            // Store the request for later abandoning
            self.audioFocusRequest = focusRequest
            
            // Request audio focus
            let result = audioManager.requestAudioFocus(focusRequest)
            if result != android.media.AudioManager.AUDIOFOCUS_REQUEST_GRANTED {
                throw NSError(domain: "RTCAudioSession", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to request audio focus"])
            }
        } else {
            // Abandon audio focus if we have a stored request
            if let request = audioFocusRequest {
                audioManager.abandonAudioFocusRequest(request)
                audioFocusRequest = nil
            }
        }
    }
    
    public func setPreferredSampleRate(_ sampleRate: Double) throws {
        // Android doesn't expose this level of control
        // Log that this is ignored on Android
        print("setPreferredSampleRate not supported on Android")
    }
    
    public func setPreferredIOBufferDuration(_ duration: Double) throws {
        // Android doesn't expose this level of control
        // Log that this is ignored on Android
        print("setPreferredIOBufferDuration not supported on Android")
    }
    
    public func overrideOutputAudioPort(_ port: RTCAudioSessionPortOverride) throws {
        switch port {
        case .none:
            audioManager.isSpeakerphoneOn = false
            audioManager.mode = android.media.AudioManager.MODE_IN_COMMUNICATION
        case .speaker:
            audioManager.isSpeakerphoneOn = true
        }
    }
    
    public var currentRoute: RTCAudioSessionRouteDescription {
        return RTCAudioSessionRouteDescription(audioManager: audioManager)
    }
}

// Supporting enum types for RTCAudioSession
public enum RTCAudioSessionCategory {
    case playAndRecord
    case playback
}

public enum RTCAudioSessionMode {
    case voiceChat
    case videoChat
}

public struct RTCAudioSessionCategoryOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let defaultToSpeaker = RTCAudioSessionCategoryOptions(rawValue: 1 << 0)
    public static let allowBluetooth = RTCAudioSessionCategoryOptions(rawValue: 1 << 1)
}

public enum RTCAudioSessionPortOverride: Int {
    case none = 0
    case speaker = 1
}

public class RTCAudioSessionRouteDescription {
    public let outputs: [RTCAudioSessionPortDescription]
    
    public init(audioManager: android.media.AudioManager) {
        var outputs = [RTCAudioSessionPortDescription]()
        
        // Get current audio devices in priority order
        if audioManager.isBluetoothScoOn {
            outputs.append(RTCAudioSessionPortDescription(portType: "BluetoothSCO", portName: "Bluetooth"))
        } else if audioManager.isWiredHeadsetOn {
            outputs.append(RTCAudioSessionPortDescription(portType: "Headphones", portName: "Wired Headset"))
        } else if audioManager.isSpeakerphoneOn {
            outputs.append(RTCAudioSessionPortDescription(portType: "Speaker", portName: "Speaker"))
        } else {
            outputs.append(RTCAudioSessionPortDescription(portType: "Receiver", portName: "Earpiece"))
        }
        
        self.outputs = outputs
    }
}

public class RTCAudioSessionPortDescription {
    public let portType: String
    public let portName: String
    
    public init(portType: String, portName: String) {
        self.portType = portType
        self.portName = portName
    }
}

// RTCPeerConnection class bridging iOS to Android
public class RTCPeerConnection: KotlinConverting<org.webrtc.PeerConnection> {
    public let platformConnection: org.webrtc.PeerConnection
    private var observer: org.webrtc.PeerConnection.Observer?
    public weak var delegate: RTCPeerConnectionDelegate?
    
    public init(platformConnection: org.webrtc.PeerConnection, observer: org.webrtc.PeerConnection.Observer) {
        self.platformConnection = platformConnection
        self.observer = observer
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.PeerConnection {
        return platformConnection
    }
    
    public func setLocalDescription(_ sdp: RTCSessionDescription, completionHandler: @escaping (Error?) -> Void) {
        let observer = createSdpObserver(completionHandler)
        platformConnection.setLocalDescription(observer, sdp.platformDescription)
    }
    
    public func setRemoteDescription(_ sdp: RTCSessionDescription, completionHandler: @escaping (Error?) -> Void) {
        let observer = createSdpObserver(completionHandler)
        platformConnection.setRemoteDescription(observer, sdp.platformDescription)
    }
    
    public func setLocalDescription(_ sdp: RTCSessionDescription) async throws {
        #if !SKIP
        fatalError("This is a Skip-only implementation")
        #endif
    }

    // SKIP INSERT: public suspend fun setLocalDescription(sdp: RTCSessionDescription) {
    // SKIP INSERT:   return kotlinx.coroutines.suspendCancellableCoroutine { continuation ->
    // SKIP INSERT:     val observer = object : org.webrtc.SdpObserver {
    // SKIP INSERT:       override fun onCreateSuccess(sdp: org.webrtc.SessionDescription?) {
    // SKIP INSERT:         // Not used for setLocalDescription
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onSetSuccess() {
    // SKIP INSERT:         continuation.resume(Unit)
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onCreateFailure(error: String?) {
    // SKIP INSERT:         // Not used for setLocalDescription
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onSetFailure(error: String?) {
    // SKIP INSERT:         val errorMessage = error ?: "Unknown error"
    // SKIP INSERT:         continuation.resumeWithException(Exception(errorMessage))
    // SKIP INSERT:       }
    // SKIP INSERT:     }
    // SKIP INSERT:
    // SKIP INSERT:     platformConnection.setLocalDescription(observer, sdp.platformDescription)
    // SKIP INSERT:   }
    // SKIP INSERT: }
    
    public func setRemoteDescription(_ sdp: RTCSessionDescription) async throws {
        #if !SKIP
        fatalError("This is a Skip-only implementation")
        #endif
    }

    // SKIP INSERT: public suspend fun setRemoteDescription(sdp: RTCSessionDescription) {
    // SKIP INSERT:   return kotlinx.coroutines.suspendCancellableCoroutine { continuation ->
    // SKIP INSERT:     val observer = object : org.webrtc.SdpObserver {
    // SKIP INSERT:       override fun onCreateSuccess(sdp: org.webrtc.SessionDescription?) {
    // SKIP INSERT:         // Not used for setRemoteDescription
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onSetSuccess() {
    // SKIP INSERT:         continuation.resume(Unit)
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onCreateFailure(error: String?) {
    // SKIP INSERT:         // Not used for setRemoteDescription
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onSetFailure(error: String?) {
    // SKIP INSERT:         val errorMessage = error ?: "Unknown error"
    // SKIP INSERT:         continuation.resumeWithException(Exception(errorMessage))
    // SKIP INSERT:       }
    // SKIP INSERT:     }
    // SKIP INSERT:
    // SKIP INSERT:     platformConnection.setRemoteDescription(observer, sdp.platformDescription)
    // SKIP INSERT:   }
    // SKIP INSERT: }
    
    public func offer(for constraints: RTCMediaConstraints) async throws -> RTCSessionDescription {
        #if !SKIP
        fatalError("This is a Skip-only implementation")
        #endif
    }

    // SKIP INSERT: public suspend fun offer(constraints: RTCMediaConstraints): RTCSessionDescription {
    // SKIP INSERT:   return kotlinx.coroutines.suspendCancellableCoroutine { continuation ->
    // SKIP INSERT:     val platformConstraints = constraints.platformConstraints
    // SKIP INSERT:     val observer = object : org.webrtc.SdpObserver {
    // SKIP INSERT:       override fun onCreateSuccess(sdp: org.webrtc.SessionDescription?) {
    // SKIP INSERT:         if (sdp != null) {
    // SKIP INSERT:           continuation.resume(RTCSessionDescription(sdp))
    // SKIP INSERT:         } else {
    // SKIP INSERT:           continuation.resumeWithException(Exception("SDP is null"))
    // SKIP INSERT:         }
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onSetSuccess() {
    // SKIP INSERT:         // Not used for createOffer
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onCreateFailure(error: String?) {
    // SKIP INSERT:         val errorMessage = error ?: "Unknown error"
    // SKIP INSERT:         continuation.resumeWithException(Exception(errorMessage))
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onSetFailure(error: String?) {
    // SKIP INSERT:         // Not used for createOffer
    // SKIP INSERT:       }
    // SKIP INSERT:     }
    // SKIP INSERT:
    // SKIP INSERT:     platformConnection.createOffer(observer, platformConstraints)
    // SKIP INSERT:   }
    // SKIP INSERT: }
    
    public func answer(for constraints: RTCMediaConstraints) async throws -> RTCSessionDescription {
        #if !SKIP
        fatalError("This is a Skip-only implementation")
        #endif
    }

    // SKIP INSERT: public suspend fun answer(constraints: RTCMediaConstraints): RTCSessionDescription {
    // SKIP INSERT:   return kotlinx.coroutines.suspendCancellableCoroutine { continuation ->
    // SKIP INSERT:     val platformConstraints = constraints.platformConstraints
    // SKIP INSERT:     val observer = object : org.webrtc.SdpObserver {
    // SKIP INSERT:       override fun onCreateSuccess(sdp: org.webrtc.SessionDescription?) {
    // SKIP INSERT:         if (sdp != null) {
    // SKIP INSERT:           continuation.resume(RTCSessionDescription(sdp))
    // SKIP INSERT:         } else {
    // SKIP INSERT:           continuation.resumeWithException(Exception("SDP is null"))
    // SKIP INSERT:         }
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onSetSuccess() {
    // SKIP INSERT:         // Not used for createAnswer
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onCreateFailure(error: String?) {
    // SKIP INSERT:         val errorMessage = error ?: "Unknown error"
    // SKIP INSERT:         continuation.resumeWithException(Exception(errorMessage))
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onSetFailure(error: String?) {
    // SKIP INSERT:         // Not used for createAnswer
    // SKIP INSERT:       }
    // SKIP INSERT:     }
    // SKIP INSERT:
    // SKIP INSERT:     platformConnection.createAnswer(observer, platformConstraints)
    // SKIP INSERT:   }
    // SKIP INSERT: }
    
    public func offer(for constraints: RTCMediaConstraints) async throws -> RTCSessionDescription {
        #if !SKIP
        fatalError("This is a Skip-only implementation")
        #endif
    }

    // SKIP INSERT: public suspend fun offer(constraints: RTCMediaConstraints): RTCSessionDescription {
    // SKIP INSERT:   return kotlinx.coroutines.suspendCancellableCoroutine { continuation ->
    // SKIP INSERT:     val platformConstraints = constraints.platformConstraints
    // SKIP INSERT:     val observer = object : org.webrtc.SdpObserver {
    // SKIP INSERT:       override fun onCreateSuccess(sdp: org.webrtc.SessionDescription?) {
    // SKIP INSERT:         if (sdp != null) {
    // SKIP INSERT:           continuation.resume(RTCSessionDescription(sdp))
    // SKIP INSERT:         } else {
    // SKIP INSERT:           continuation.resumeWithException(Exception("SDP is null"))
    // SKIP INSERT:         }
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onSetSuccess() {
    // SKIP INSERT:         // Not used for createOffer
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onCreateFailure(error: String?) {
    // SKIP INSERT:         val errorMessage = error ?: "Unknown error"
    // SKIP INSERT:         continuation.resumeWithException(Exception(errorMessage))
    // SKIP INSERT:       }
    // SKIP INSERT:
    // SKIP INSERT:       override fun onSetFailure(error: String?) {
    // SKIP INSERT:         // Not used for createOffer
    // SKIP INSERT:       }
    // SKIP INSERT:     }
    // SKIP INSERT:
    // SKIP INSERT:     platformConnection.createOffer(observer, platformConstraints)
    // SKIP INSERT:   }
    // SKIP INSERT: }
    
    public func answer(for constraints: RTCMediaConstraints, completionHandler: @escaping (_ sdp: RTCSessionDescription?, _ error: Error?) -> Void) {
        let platformConstraints = constraints.platformConstraints
        let observer = org.webrtc.SdpObserver {
            override func onCreateSuccess(sdp: org.webrtc.SessionDescription?) {
                DispatchQueue.main.async {
                    if sdp != null {
                        completionHandler(RTCSessionDescription(sdp), nil)
                    } else {
                        completionHandler(nil, NSError(domain: WebRTCErrorDomain, code: WebRTCErrorCode.sdpCreateFailed.rawValue, userInfo: [NSLocalizedDescriptionKey: "SDP is null"]))
                    }
                }
            }
            
            override func onSetSuccess() {
                // Not used for createAnswer
            }
            
            override func onCreateFailure(error: String?) {
                DispatchQueue.main.async {
                    completionHandler(nil, NSError(domain: WebRTCErrorDomain, code: WebRTCErrorCode.sdpCreateFailed.rawValue, userInfo: [NSLocalizedDescriptionKey: error ?? "Unknown error"]))
                }
            }
            
            override func onSetFailure(error: String?) {
                // Not used for createAnswer
            }
        }
        
        platformConnection.createAnswer(observer, platformConstraints)
    }
    
    public func add(_ candidate: RTCIceCandidate, completionHandler: @escaping (Error?) -> Void) {
        platformConnection.addIceCandidate(candidate.platformCandidate) { success in
            DispatchQueue.main.async {
                if success {
                    completionHandler(nil)
                } else {
                    completionHandler(NSError(domain: WebRTCErrorDomain, code: WebRTCErrorCode.iceCandidateError.rawValue, userInfo: [NSLocalizedDescriptionKey: "Failed to add ICE candidate"]))
                }
            }
        }
    }
    
    public func add(_ candidate: RTCIceCandidate) async throws {
        #if !SKIP
        fatalError("This is a Skip-only implementation")
        #endif
    }

    // SKIP INSERT: public suspend fun add(candidate: RTCIceCandidate) {
    // SKIP INSERT:   val success = kotlinx.coroutines.suspendCancellableCoroutine<Boolean> { continuation ->
    // SKIP INSERT:     platformConnection.addIceCandidate(candidate.platformCandidate) { success ->
    // SKIP INSERT:       continuation.resume(success)
    // SKIP INSERT:     }
    // SKIP INSERT:   }
    // SKIP INSERT:
    // SKIP INSERT:   if (!success) {
    // SKIP INSERT:     throw Exception("Failed to add ICE candidate")
    // SKIP INSERT:   }
    // SKIP INSERT: }
    
    public func removeTrack(_ sender: RTCRtpSender) {
        platformConnection.removeTrack(sender.kotlin())
    }
    
    public func close() {
        platformConnection.close()
    }
    
    public func dataChannel(forLabel label: String, configuration: RTCDataChannelConfiguration) -> RTCDataChannel? {
        let dataChannelInit = org.webrtc.DataChannel.Init()
        dataChannelInit.ordered = configuration.isOrdered
        dataChannelInit.maxRetransmitTimeMs = configuration.maxRetransmitTimeMs
        dataChannelInit.maxRetransmits = configuration.maxRetransmits
        dataChannelInit.protocol = configuration.protocol
        dataChannelInit.negotiated = configuration.isNegotiated
        dataChannelInit.id = configuration.channelId
        
        let platformChannel = platformConnection.createDataChannel(label, dataChannelInit)
        if platformChannel != null {
            return RTCDataChannel(platformChannel)
        }
        return nil
    }
    
    private func createSdpObserver(_ completionHandler: @escaping (Error?) -> Void) -> org.webrtc.SdpObserver {
        return org.webrtc.SdpObserver {
            override func onCreateSuccess(sdp: org.webrtc.SessionDescription?) {
                // Not used for setLocalDescription
            }
            
            override func onSetSuccess() {
                DispatchQueue.main.async {
                    completionHandler(nil)
                }
            }
            
            override func onCreateFailure(error: String?) {
                // Not used for setLocalDescription
            }
            
            override func onSetFailure(error: String?) {
                DispatchQueue.main.async {
                    completionHandler(NSError(domain: WebRTCErrorDomain, code: WebRTCErrorCode.sdpSetFailed.rawValue, userInfo: [NSLocalizedDescriptionKey: error ?? "Unknown error"]))
                }
            }
        }
    }
    
    // Track management methods
    public var transceivers: [RTCRtpTransceiver] {
        return platformConnection.transceivers.map { RTCRtpTransceiver($0) }
    }
    
    public func add(_ track: RTCAudioTrack, streamIds: [String]) -> RTCRtpSender {
        let mediaStreamLabels = streamIds.toList()
        let sender = platformConnection.addTrack(track.platformTrack, mediaStreamLabels)
        return RTCRtpSender(sender)
    }
    
    public func add(_ track: RTCVideoTrack, streamIds: [String]) -> RTCRtpSender {
        let mediaStreamLabels = streamIds.toList()
        let sender = platformConnection.addTrack(track.platformTrack, mediaStreamLabels)
        return RTCRtpSender(sender)
    }
    
    // Statistics
    public func statistics(_ completionHandler: @escaping (RTCStatisticsReport) -> Void) {
        platformConnection.getStats { statsReport in
            // Convert Android stats report to iOS-like structure
            let convertedReport = RTCStatisticsReport(nativeReport: statsReport)
            
            DispatchQueue.main.async {
                completionHandler(convertedReport)
            }
        }
    }
    
    public func statistics() async -> RTCStatisticsReport {
        #if !SKIP
        fatalError("This is a Skip-only implementation")
        #endif
    }

    // SKIP INSERT: public suspend fun statistics(): RTCStatisticsReport {
    // SKIP INSERT:   return kotlinx.coroutines.suspendCancellableCoroutine { continuation ->
    // SKIP INSERT:     platformConnection.getStats { statsReport ->
    // SKIP INSERT:       val convertedReport = RTCStatisticsReport(statsReport)
    // SKIP INSERT:       continuation.resume(convertedReport)
    // SKIP INSERT:     }
    // SKIP INSERT:   }
    // SKIP INSERT: }
}

// RTCDataChannelConfiguration class for data channel configuration
public class RTCDataChannelConfiguration {
    public var isOrdered: Bool = true
    public var maxRetransmitTimeMs: Int = -1
    public var maxRetransmits: Int = -1
    public var `protocol`: String = ""
    public var isNegotiated: Bool = false
    public var channelId: Int = 0
    
    public init() {}
}

// RTCRtpTransceiver class bridging iOS to Android
public class RTCRtpTransceiver: KotlinConverting<org.webrtc.RtpTransceiver> {
    public let platformTransceiver: org.webrtc.RtpTransceiver
    
    public init(_ platformTransceiver: org.webrtc.RtpTransceiver) {
        self.platformTransceiver = platformTransceiver
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.RtpTransceiver {
        return platformTransceiver
    }
    
    public var mediaType: RTCRtpMediaType {
        let mediaType = platformTransceiver.mediaType
        switch mediaType {
        case org.webrtc.MediaStreamTrack.MediaType.MEDIA_TYPE_AUDIO:
            return .audio
        case org.webrtc.MediaStreamTrack.MediaType.MEDIA_TYPE_VIDEO:
            return .video
        default:
            print("WARNING: Unknown media type")
            return .unsupported
        }
    }
    
    public var sender: RTCRtpSender {
        return RTCRtpSender(platformTransceiver.sender)
    }
    
    public var receiver: RTCRtpReceiver {
        return RTCRtpReceiver(platformTransceiver.receiver)
    }
    
    public var direction: RTCRtpTransceiverDirection {
        let nativeDirection = platformTransceiver.direction
        switch nativeDirection {
        case org.webrtc.RtpTransceiver.RtpTransceiverDirection.SEND_RECV:
            return .sendRecv
        case org.webrtc.RtpTransceiver.RtpTransceiverDirection.SEND_ONLY:
            return .sendOnly
        case org.webrtc.RtpTransceiver.RtpTransceiverDirection.RECV_ONLY:
            return .recvOnly
        case org.webrtc.RtpTransceiver.RtpTransceiverDirection.INACTIVE:
            return .inactive
        default:
            print("WARNING: Unknown RTP transceiver direction")
            return .inactive
        }
    }
    
    public func setDirection(_ direction: RTCRtpTransceiverDirection) {
        var nativeDirection: org.webrtc.RtpTransceiver.RtpTransceiverDirection
        
        switch direction {
        case .sendRecv:
            nativeDirection = org.webrtc.RtpTransceiver.RtpTransceiverDirection.SEND_RECV
        case .sendOnly:
            nativeDirection = org.webrtc.RtpTransceiver.RtpTransceiverDirection.SEND_ONLY
        case .recvOnly:
            nativeDirection = org.webrtc.RtpTransceiver.RtpTransceiverDirection.RECV_ONLY
        case .inactive:
            nativeDirection = org.webrtc.RtpTransceiver.RtpTransceiverDirection.INACTIVE
        case .stopped:
            nativeDirection = org.webrtc.RtpTransceiver.RtpTransceiverDirection.INACTIVE
            // For .stopped, also try to stop the transceiver
            platformTransceiver.stop()
            return
        }
        
        platformTransceiver.setDirection(nativeDirection)
    }
    
    public func stop() {
        platformTransceiver.stop()
    }
}

// RTCRtpTransceiverDirection enum
public enum RTCRtpTransceiverDirection {
    case sendRecv
    case sendOnly
    case recvOnly
    case inactive
    case stopped
}

// RTCRtpMediaType enum
public enum RTCRtpMediaType: Int {
    case audio = 0
    case video = 1
    case data = 2
    case unsupported = 3
}

// RTCRtpSender class bridging iOS to Android
public class RTCRtpSender: KotlinConverting<org.webrtc.RtpSender> {
    public let platformSender: org.webrtc.RtpSender
    
    public init(_ platformSender: org.webrtc.RtpSender) {
        self.platformSender = platformSender
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.RtpSender {
        return platformSender
    }
    
    public var track: RTCMediaStreamTrack? {
        get {
            let track = platformSender.track()
            if track == null {
                return nil
            }
            
            if track is org.webrtc.AudioTrack {
                return RTCAudioTrack(track as! org.webrtc.AudioTrack)
            } else if track is org.webrtc.VideoTrack {
                return RTCVideoTrack(track as! org.webrtc.VideoTrack)
            }
            
            return nil
        }
        set {
            if newValue == nil {
                platformSender.setTrack(null, false)
            } else if let audioTrack = newValue as? RTCAudioTrack {
                platformSender.setTrack(audioTrack.platformTrack, false)
            } else if let videoTrack = newValue as? RTCVideoTrack {
                platformSender.setTrack(videoTrack.platformTrack, false)
            }
        }
    }
    
    public var senderId: String {
        return platformSender.id()
    }
    
    public func setTrack(_ track: RTCMediaStreamTrack?, streamIds: [String]? = nil) -> Bool {
        let mediaStreamLabels = streamIds?.toList() ?? listOf<String>()
        
        if let audioTrack = track as? RTCAudioTrack {
            return platformSender.setTrack(audioTrack.platformTrack, mediaStreamLabels.isNotEmpty())
        } else if let videoTrack = track as? RTCVideoTrack {
            return platformSender.setTrack(videoTrack.platformTrack, mediaStreamLabels.isNotEmpty())
        } else {
            return platformSender.setTrack(null, false)
        }
    }
}

// RTCRtpReceiver class bridging iOS to Android
public class RTCRtpReceiver: KotlinConverting<org.webrtc.RtpReceiver> {
    public let platformReceiver: org.webrtc.RtpReceiver
    
    public init(_ platformReceiver: org.webrtc.RtpReceiver) {
        self.platformReceiver = platformReceiver
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.RtpReceiver {
        return platformReceiver
    }
    
    public var track: RTCMediaStreamTrack? {
        let track = platformReceiver.track()
        if track == null {
            return nil
        }
        
        if track is org.webrtc.AudioTrack {
            return RTCAudioTrack(track as! org.webrtc.AudioTrack)
        } else if track is org.webrtc.VideoTrack {
            return RTCVideoTrack(track as! org.webrtc.VideoTrack)
        }
        
        return nil
    }
    
    public var receiverId: String {
        return platformReceiver.id()
    }
}

// RTCMediaStreamTrack base class
public class RTCMediaStreamTrack {
    public var trackId: String { return "" }
    public var isEnabled: Bool {
        get { return false }
        set { }
    }
}

// Make RTCAudioTrack and RTCVideoTrack inherit from RTCMediaStreamTrack
extension RTCAudioTrack: RTCMediaStreamTrack {}
extension RTCVideoTrack: RTCMediaStreamTrack {}

// RTCPeerConnectionDelegate protocol
public protocol RTCPeerConnectionDelegate: AnyObject {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState)
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream)
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream)
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection)
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState)
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState)
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate)
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate])
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel)
}

// RTCSignalingState enum
public enum RTCSignalingState: Int {
    case stable = 0
    case haveLocalOffer = 1
    case haveLocalPrAnswer = 2
    case haveRemoteOffer = 3
    case haveRemotePrAnswer = 4
    case closed = 5
    
    static func fromPlatformState(_ state: org.webrtc.PeerConnection.SignalingState) -> RTCSignalingState {
        switch state {
        case org.webrtc.PeerConnection.SignalingState.STABLE: return .stable
        case org.webrtc.PeerConnection.SignalingState.HAVE_LOCAL_OFFER: return .haveLocalOffer
        case org.webrtc.PeerConnection.SignalingState.HAVE_LOCAL_PRANSWER: return .haveLocalPrAnswer
        case org.webrtc.PeerConnection.SignalingState.HAVE_REMOTE_OFFER: return .haveRemoteOffer
        case org.webrtc.PeerConnection.SignalingState.HAVE_REMOTE_PRANSWER: return .haveRemotePrAnswer
        case org.webrtc.PeerConnection.SignalingState.CLOSED: return .closed
        default:
            print("WARNING: Unknown signaling state")
            return .stable
        }
    }
}

// RTCIceGatheringState enum
public enum RTCIceGatheringState: Int {
    case new = 0
    case gathering = 1
    case complete = 2
    
    static func fromPlatformState(_ state: org.webrtc.PeerConnection.IceGatheringState) -> RTCIceGatheringState {
        switch state {
        case org.webrtc.PeerConnection.IceGatheringState.NEW: return .new
        case org.webrtc.PeerConnection.IceGatheringState.GATHERING: return .gathering
        case org.webrtc.PeerConnection.IceGatheringState.COMPLETE: return .complete
        default:
            print("WARNING: Unknown ICE gathering state")
            return .new
        }
    }
}

// RTCMediaStream class bridging iOS to Android
public class RTCMediaStream: KotlinConverting<org.webrtc.MediaStream> {
    public let platformStream: org.webrtc.MediaStream
    
    public init(_ platformStream: org.webrtc.MediaStream) {
        self.platformStream = platformStream
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.MediaStream {
        return platformStream
    }
    
    public var streamId: String {
        return platformStream.id
    }
    
    public var audioTracks: [RTCAudioTrack] {
        return platformStream.audioTracks.map { RTCAudioTrack($0) }
    }
    
    public var videoTracks: [RTCVideoTrack] {
        return platformStream.videoTracks.map { RTCVideoTrack($0) }
    }
    
    public func addAudioTrack(_ track: RTCAudioTrack) {
        platformStream.addTrack(track.platformTrack)
    }
    
    public func addVideoTrack(_ track: RTCVideoTrack) {
        platformStream.addTrack(track.platformTrack)
    }
    
    public func removeAudioTrack(_ track: RTCAudioTrack) {
        platformStream.removeTrack(track.platformTrack)
    }
    
    public func removeVideoTrack(_ track: RTCVideoTrack) {
        platformStream.removeTrack(track.platformTrack)
    }
}

// RTCStatisticsReport class
public class RTCStatisticsReport {
    private let nativeReport: org.webrtc.RTCStatsReport
    private var statsMap: [String: RTCStatistics] = [:]
    
    internal init(nativeReport: org.webrtc.RTCStatsReport) {
        self.nativeReport = nativeReport
        
        // Convert native stats to Swift stats
        for statsReport in nativeReport.statsMap.values() {
            let stats = RTCStatistics(nativeStats: statsReport)
            statsMap[stats.id] = stats
        }
    }
    
    public var timestamp: TimeInterval {
        return TimeInterval(nativeReport.timestamp / 1000) // Convert from microseconds to seconds
    }
    
    public var statistics: [String: RTCStatistics] {
        return statsMap
    }
}

// RTCStatistics class for individual statistics
public class RTCStatistics {
    private let nativeStats: org.webrtc.RTCStats
    private var valueMap: [String: Any] = [:]
    
    internal init(nativeStats: org.webrtc.RTCStats) {
        self.nativeStats = nativeStats
        
        // Convert Java map to Swift dictionary
        for member in nativeStats.members {
            if member.value != null {
                valueMap[member.key] = deepSwift(value: member.value)
            }
        }
    }
    
    public var id: String {
        return nativeStats.id
    }
    
    public var timestamp: TimeInterval {
        return TimeInterval(nativeStats.timestamp / 1000) // Convert from microseconds to seconds
    }
    
    public var type: String {
        return nativeStats.type
    }
    
    public var values: [String: Any] {
        return valueMap
    }
}

// RTCMediaConstraints class bridging iOS to Android
public class RTCMediaConstraints: KotlinConverting<org.webrtc.MediaConstraints> {
    public let platformConstraints: org.webrtc.MediaConstraints
    
    public init(mandatoryConstraints: [String: String]?, optionalConstraints: [String: String]?) {
        let constraints = org.webrtc.MediaConstraints()
        
        if let mandatory = mandatoryConstraints {
            for (key, value) in mandatory {
                constraints.mandatory.add(org.webrtc.MediaConstraints.KeyValuePair(key, value))
            }
        }
        
        if let optional = optionalConstraints {
            for (key, value) in optional {
                constraints.optional.add(org.webrtc.MediaConstraints.KeyValuePair(key, value))
            }
        }
        
        self.platformConstraints = constraints
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.MediaConstraints {
        return platformConstraints
    }
}

// Constants for MediaConstraints
public let kRTCMediaConstraintsOfferToReceiveAudio = "OfferToReceiveAudio"
public let kRTCMediaConstraintsOfferToReceiveVideo = "OfferToReceiveVideo"
public let kRTCMediaConstraintsValueTrue = "true"
public let kRTCMediaConstraintsValueFalse = "false"

// Error handling
public let WebRTCErrorDomain = "WebRTCErrorDomain"

public enum WebRTCErrorCode: Int {
    case unknown = 0
    case sdpParseFailed = 1
    case sdpCreateFailed = 2
    case sdpSetFailed = 3
    case iceCandidateError = 4
}

// WebRTCClient class - the main class
public final class WebRTCClient: NSObject, Sendable, KotlinConverting<org.webrtc.PeerConnectionFactory> {
    public weak var delegate: WebRTCClientDelegate?
    
    private let peerConnection: RTCPeerConnection
    private let rtcAudioSession = RTCAudioSession.sharedInstance
    private let audioQueue = DispatchQueue(label: "audio")
    
    private var silenceDetectionTimer: java.util.Timer?
    private var silenceStartTime: Date?
    
    // Offering to receive both audio and video
    private let mediaConstraints = [
        kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
        kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue
    ]
    
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    private var localDataChannel: RTCDataChannel?
    private var remoteDataChannel: RTCDataChannel?
    
    // The factory for creating WebRTC components
    private let factory: org.webrtc.PeerConnectionFactory
    
    // EGL context
    private var eglBase: org.webrtc.EglBase?
    
    // Initialize WebRTC on Android
    private static func initializeWebRTC() {
        // Initialize WebRTC context if needed
        org.webrtc.PeerConnectionFactory.initialize(
            org.webrtc.PeerConnectionFactory.InitializationOptions.builder(ProcessInfo.processInfo.androidContext)
                .setEnableInternalTracer(true)
                .createInitializationOptions()
        )
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.PeerConnectionFactory {
        return factory
    }
    
    public init(iceServers: [String]) {
        WebRTCClient.initializeWebRTC()
        
        // Create shared EGL context
        self.eglBase = org.webrtc.EglBase.create()
        let eglBaseContext = eglBase?.eglBaseContext
        
        // Create factory with video encoder/decoder
        let encoderFactory = org.webrtc.DefaultVideoEncoderFactory(
            eglBaseContext,
            true,  // enable Intel VP8 encoder
            true   // enable H.264 encoder
        )
        
        let decoderFactory = org.webrtc.DefaultVideoDecoderFactory(
            eglBaseContext
        )
        
        factory = org.webrtc.PeerConnectionFactory.builder()
            .setOptions(org.webrtc.PeerConnectionFactory.Options())
            .setVideoEncoderFactory(encoderFactory)
            .setVideoDecoderFactory(decoderFactory)
            .createPeerConnectionFactory()
        
        // Create peer connection configuration
        let rtcConfig = org.webrtc.PeerConnection.RTCConfiguration(
            iceServers.map { serverUrl in
                org.webrtc.PeerConnection.IceServer.builder(serverUrl)
                    .createIceServer()
            }.toList()
        )
        
        rtcConfig.sdpSemantics = org.webrtc.PeerConnection.SdpSemantics.UNIFIED_PLAN
        rtcConfig.continualGatheringPolicy = org.webrtc.PeerConnection.ContinualGatheringPolicy.GATHER_CONTINUALLY
        rtcConfig.enableDtlsSrtp = true
        rtcConfig.enableRtpDataChannel = true
        
        // Create peer connection constraints
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue]
        )
        
        // Create peer connection observer
        let observer = org.webrtc.PeerConnection.Observer {
            override func onSignalingChange(state: org.webrtc.PeerConnection.SignalingState) {
                let swiftState = RTCSignalingState.fromPlatformState(state)
                DispatchQueue.main.async {
                    delegate?.peerConnection(peerConnection, didChange: swiftState)
                }
            }
            
            override func onIceConnectionChange(state: org.webrtc.PeerConnection.IceConnectionState) {
                let swiftState = RTCIceConnectionState.fromPlatformState(state)
                DispatchQueue.main.async {
                    delegate?.peerConnection(peerConnection, didChange: swiftState)
                    delegate?.webRTCClient(self, didChangeConnectionState: swiftState)
                }
            }
            
            override func onIceConnectionReceivingChange(receiving: Boolean) {
                // Not used in the original implementation
            }
            
            override func onIceGatheringChange(state: org.webrtc.PeerConnection.IceGatheringState) {
                let swiftState = RTCIceGatheringState.fromPlatformState(state)
                DispatchQueue.main.async {
                    delegate?.peerConnection(peerConnection, didChange: swiftState)
                }
            }
            
            override func onIceCandidate(candidate: org.webrtc.IceCandidate) {
                let swiftCandidate = RTCIceCandidate(candidate)
                DispatchQueue.main.async {
                    delegate?.peerConnection(peerConnection, didGenerate: swiftCandidate)
                    delegate?.webRTCClient(self, didDiscoverLocalCandidate: swiftCandidate)
                }
            }
            
            override func onIceCandidatesRemoved(candidates: Array<org.webrtc.IceCandidate>) {
                let swiftCandidates = candidates.map { RTCIceCandidate($0) }
                DispatchQueue.main.async {
                    delegate?.peerConnection(peerConnection, didRemove: swiftCandidates)
                }
            }
            
            override func onAddStream(stream: org.webrtc.MediaStream) {
                DispatchQueue.main.async {
                    delegate?.peerConnection(peerConnection, didAdd: RTCMediaStream(stream))
                }
            }
            
            override func onRemoveStream(stream: org.webrtc.MediaStream) {
                DispatchQueue.main.async {
                    delegate?.peerConnection(peerConnection, didRemove: RTCMediaStream(stream))
                }
            }
            
            override func onDataChannel(dataChannel: org.webrtc.DataChannel) {
                let swiftDataChannel = RTCDataChannel(dataChannel)
                
                // Store remote data channel
                remoteDataChannel = swiftDataChannel
                
                // Set delegate
                swiftDataChannel.delegate = self
                
                DispatchQueue.main.async {
                    delegate?.peerConnection(peerConnection, didOpen: swiftDataChannel)
                }
            }
            
            override func onRenegotiationNeeded() {
                DispatchQueue.main.async {
                    delegate?.peerConnectionShouldNegotiate(peerConnection)
                }
            }
            
            override func onAddTrack(receiver: org.webrtc.RtpReceiver, streams: Array<org.webrtc.MediaStream>) {
                if receiver.track() is org.webrtc.VideoTrack {
                    let videoTrack = receiver.track() as! org.webrtc.VideoTrack
                    remoteVideoTrack = RTCVideoTrack(videoTrack)
                }
                
                if receiver.track() is org.webrtc.AudioTrack {
                    // Handle audio track reception if needed
                }
            }
        }
        
        // Create the peer connection
        let platformConnection = factory.createPeerConnection(rtcConfig, constraints.platformConstraints, observer)!
        peerConnection = RTCPeerConnection(platformConnection: platformConnection, observer: observer)
        
        super.init()
        
        // Set up the WebRTC client
        createMediaSenders()
        setAudioSession()
    }
    
    deinit {
        // Clean up resources
        silenceDetectionTimer?.cancel()
        silenceDetectionTimer = nil
        
        // Clean up EGL context
        eglBase?.release()
        eglBase = nil
    }
    
    // MARK: - Signaling
    
    public func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: self.mediaConstraints,
                                             optionalConstraints: nil)
        self.peerConnection.offer(for: constraints) { (sdp, error) in
            guard let sdp = sdp else {
                print("ERROR: Failed to create offer SDP: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            self.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                if let error = error {
                    print("ERROR: Failed to set local description: \(error.localizedDescription)")
                    return
                }
                completion(sdp)
            })
        }
    }
    
    public func offer() async throws -> RTCSessionDescription {
        let constraints = RTCMediaConstraints(mandatoryConstraints: self.mediaConstraints,
                                             optionalConstraints: nil)
        let sdp = try await self.peerConnection.offer(for: constraints)
        try await self.peerConnection.setLocalDescription(sdp)
        return sdp
    }
    
    public func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: self.mediaConstraints,
                                             optionalConstraints: nil)
        self.peerConnection.answer(for: constraints) { (sdp, error) in
            guard let sdp = sdp else {
                print("ERROR: Failed to create answer SDP: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                if let error = error {
                    print("ERROR: Failed to set local description: \(error.localizedDescription)")
                    return
                }
                completion(sdp)
            })
        }
    }
    
    public func answer() async throws -> RTCSessionDescription {
        let constraints = RTCMediaConstraints(mandatoryConstraints: self.mediaConstraints,
                                             optionalConstraints: nil)
        let sdp = try await self.peerConnection.answer(for: constraints)
        try await self.peerConnection.setLocalDescription(sdp)
        return sdp
    }
    
    public func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> ()) {
        self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }
    
    public func set(remoteSdp: RTCSessionDescription) async throws {
        try await self.peerConnection.setRemoteDescription(remoteSdp)
    }
    
    public func set(remoteCandidate: RTCIceCandidate, completion: @escaping (Error?) -> ()) {
        self.peerConnection.add(remoteCandidate, completionHandler: completion)
    }
    
    public func set(remoteCandidate: RTCIceCandidate) async throws {
        try await self.peerConnection.add(remoteCandidate)
    }
    
    // MARK: - Media
    
    public func startCaptureLocalVideo(renderer: RTCVideoRenderer) {
        guard let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
            print("ERROR: Video capturer not available or not the correct type")
            return
        }
        
        let devices = RTCCameraVideoCapturer.captureDevices()
        guard !devices.isEmpty else {
            print("ERROR: No camera devices found")
            return
        }
        
        // Prefer front camera if available
        let frontCamera = devices.first { $0.position == .front } ?? devices.first
        
        guard let camera = frontCamera else {
            print("ERROR: No camera available")
            return
        }
        
        let formats = RTCCameraVideoCapturer.supportedFormats(for: camera)
        guard !formats.isEmpty else {
            print("ERROR: No supported formats for camera")
            return
        }
        
        // Choose a format - prefer higher resolution but not too high
        // Sort by resolution (width x height)
        let sortedFormats = formats.sorted {
            $0.width * $0.height < $1.width * $1.height
        }
        
        // Try to find a good compromise format (720p or closest)
        let targetResolution = 1280 * 720
        let format = sortedFormats.min {
            abs($0.width * $0.height - targetResolution) < abs($1.width * $1.height - targetResolution)
        } ?? sortedFormats.last!
        
        // Find a good framerate
        let fps = format.videoSupportedFrameRateRanges
            .sorted { $0.maxFrameRate > $1.maxFrameRate }
            .first?.maxFrameRate ?? 30.0
        
        print("Starting camera capture with format: \(format.width)x\(format.height) @ \(fps) fps")
        
        capturer.startCapture(with: camera,
                              format: format,
                              fps: Int(fps))
        
        self.localVideoTrack?.add(renderer)
    }
    
    public func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        self.remoteVideoTrack?.add(renderer)
    }
    
    private func createMediaSenders() {
        let streamId = "stream"
        
        // Audio
        let audioTrack = self.createAudioTrack()
        self.peerConnection.add(audioTrack, streamIds: [streamId])
        
        // Video
        let videoTrack = self.createVideoTrack()
        self.localVideoTrack = videoTrack
        self.peerConnection.add(videoTrack, streamIds: [streamId])
        
        // Find remote video track
        self.remoteVideoTrack = self.peerConnection.transceivers.first {
            $0.mediaType == .video
        }?.receiver.track as? RTCVideoTrack
        
        // Data
        if let dataChannel = createDataChannel() {
            dataChannel.delegate = self
            self.localDataChannel = dataChannel
        }
    }
    
    private func createAudioTrack() -> RTCAudioTrack {
        // Audio constraints
        let audioConstraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "echoCancellation": "true",
                "googEchoCancellation": "true",
                "googAutoGainControl": "true",
                "noiseSuppression": "true",
                "autoGainControl": "true"
            ],
            optionalConstraints: [
                "typingNoiseDetection": "false"
            ]
        )
        
        let audioSource = factory.createAudioSource(audioConstraints.platformConstraints)
        let audioTrack = factory.createAudioTrack("audio0", audioSource)
        return RTCAudioTrack(audioTrack)
    }
    
    private func createVideoTrack() -> RTCVideoTrack {
        let videoSource = factory.createVideoSource(false)
        
        self.videoCapturer = RTCCameraVideoCapturer(delegate: RTCVideoSource(videoSource))
        
        let videoTrack = factory.createVideoTrack("video0", videoSource)
        return RTCVideoTrack(videoTrack)
    }
    
    // MARK: - Data Channel
    
    private func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        config.protocol = "oai-events"
        
        if let dataChannel = self.peerConnection.dataChannel(forLabel: "oai-events", configuration: config) {
            return dataChannel
        } else {
            print("ERROR: Failed to create data channel")
            return nil
        }
    }
    
    public func sendData(_ data: Data) {
        guard let localChannel = self.localDataChannel else {
            print("ERROR: Local data channel is nil")
            return
        }
        
        // Check if the channel is actually open
        if localChannel.readyState != .open {
            print("ERROR: Data channel not open. Current state: \(localChannel.readyState)")
            return
        }
        
        let buffer = RTCDataBuffer(data: data, isBinary: false)
        localChannel.sendData(buffer)
    }
    
    // MARK: - Session Management
    
    public func close() {
        print("DEBUG: Closing WebRTC client and cleaning up resources")
        
        // 1. Stop timers and disable media
        silenceDetectionTimer?.cancel()
        silenceDetectionTimer = nil
        silenceStartTime = nil
        
        setAudioEnabled(false)
        setVideoEnabled(false)
        
        // 2. Stop video capture
        if let cameraCapturer = videoCapturer as? RTCCameraVideoCapturer {
            Task {
                await cameraCapturer.stopCapture()
            }
        }
        videoCapturer = nil
        
        // 3. Close data channels
        localDataChannel?.close()
        localDataChannel = nil
        remoteDataChannel?.close()
        remoteDataChannel = nil
        
        // 4. Deactivate audio session
        rtcAudioSession.lockForConfiguration()
        do {
            try rtcAudioSession.setActive(false)
        } catch {
            print("ERROR: Failed to deactivate RTCAudioSession: \(error)")
        }
        rtcAudioSession.unlockForConfiguration()
        
        // 5. Remove all transceivers and tracks
        peerConnection.transceivers.forEach { transceiver in
            if let sender = transceiver.sender.track {
                sender.isEnabled = false
            }
            
            let rtpSender = transceiver.sender
            rtpSender.track = nil
            peerConnection.removeTrack(rtpSender)
            
            // Also stop the transceiver
            transceiver.stop()
        }
        
        // 6. Finally close the connection
        peerConnection.close()
    }
    
    // MARK: - Audio Control
    
    public func muteAudio() {
        print("DEBUG: Muting audio")
        self.setAudioEnabled(false)
    }
    
    public func unmuteAudio() {
        print("DEBUG: Unmuting audio")
        self.setAudioEnabled(true)
    }
    
    public func muteRemoteAudio() {
        peerConnection.transceivers
            .compactMap { $0.receiver.track as? RTCAudioTrack }
            .forEach { $0.isEnabled = false }
    }

    public func unmuteRemoteAudio() {
        peerConnection.transceivers
            .compactMap { $0.receiver.track as? RTCAudioTrack }
            .forEach { $0.isEnabled = true }
    }
    
    // Use device's default route (e.g., headphones/bluetooth/ear speaker)
    public func speakerOff() {
        self.audioQueue.async { [weak self] in
            guard let self = self else { return }
            self.rtcAudioSession.lockForConfiguration()
            do {
                try self.rtcAudioSession.setCategory(.playAndRecord)
                try self.rtcAudioSession.overrideOutputAudioPort(.none)
            } catch let error {
                print("Error setting audio session category: \(error)")
            }
            self.rtcAudioSession.unlockForConfiguration()
            self.delegate?.webRTCClient(self, didFinishAudioSessionInit: nil)
        }
    }
    
    public func setAudioSession() {
        self.rtcAudioSession.lockForConfiguration()
        do {
            try self.rtcAudioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            try self.rtcAudioSession.setPreferredSampleRate(48000.0) // Higher sample rate for better quality
            try self.rtcAudioSession.setPreferredIOBufferDuration(0.005) // Lower buffer size for less latency
            try self.rtcAudioSession.setActive(true)
            try self.rtcAudioSession.overrideOutputAudioPort(.speaker)
            for output in rtcAudioSession.currentRoute.outputs {
                print("Audio output route (in setAudioSession):", output.portType, output.portName)
            }
        } catch {
            print("Couldn't force audio to speaker: \(error.localizedDescription)")
        }
        self.rtcAudioSession.unlockForConfiguration()
    }
    
    // Force audio to speaker
    public func speakerOn() {
        print("DEBUG: Forcing audio to speaker")
        do {
            try self.rtcAudioSession.overrideOutputAudioPort(.speaker)
        } catch {
            print("DEBUG: Error: Couldn't force audio to speaker: \(error.localizedDescription)")
        }
        self.audioQueue.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.webRTCClient(self, didFinishAudioSessionInit: nil)
        }
    }
    
    // MARK: - Video Control
    
    public func hideVideo() {
        self.setVideoEnabled(false)
    }
    
    public func showVideo() {
        self.setVideoEnabled(true)
    }
    
    private func setVideoEnabled(_ isEnabled: Bool) {
        setTrackEnabled(RTCVideoTrack.self, isEnabled: isEnabled)
    }
    
    private func setAudioEnabled(_ isEnabled: Bool) {
        setTrackEnabled(RTCAudioTrack.self, isEnabled: isEnabled)
    }
    
    private func setTrackEnabled<T: RTCMediaStreamTrack>(_ type: T.Type, isEnabled: Bool) {
        peerConnection.transceivers
            .compactMap { $0.sender.track as? T }
            .forEach { $0.isEnabled = isEnabled }
    }
    
    public var isAudioEnabled: Bool {
        return peerConnection.transceivers
            .compactMap { $0.sender.track as? RTCAudioTrack }
            .contains { $0.isEnabled }
    }
    
    // MARK: - Audio Stats
    
    public enum AudioTrackType {
        case input
        case output
    }
    
    // Sends normalized power levels to the completion func.
    public func getAudioStats(trackType: AudioTrackType = .input, completion: @escaping (Double?) -> Void) {
        self.peerConnection.statistics { stats in
            // Try to extract audio level from stats report
            var level: Double? = nil
            
            // Look for audio stats and find the level
            for (_, stat) in stats.statistics {
                if stat.type == "media-source" || stat.type == "track" || stat.type == "inbound-rtp" {
                    if let trackType = stat.values["kind"] as? String, trackType == "audio" {
                        // Look for audio level
                        if let audioLevel = stat.values["audioLevel"] as? Double {
                            level = self.normalizeAudioLevel(audioLevel)
                            break
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(level)
            }
        }
    }
    
    private func normalizeAudioLevel(_ audioLevel: Double) -> Double {
        // Convert to decibels
        let dbLevel = 20 * log10(audioLevel)
        // Normalize between -50dB (quiet) and -10dB (loud)
        // This range better matches typical speech levels
        let minDb = -50.0
        let maxDb = -10.0
        let normalizedLevel = (dbLevel - minDb) / (maxDb - minDb)
        return min(max(normalizedLevel, 0), 1)
    }
}

// MARK: - RTCDataChannelDelegate

extension WebRTCClient: RTCDataChannelDelegate {
    public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("dataChannel did change state: \(dataChannel.readyState)")
        self.delegate?.webRTCClient(self, dataChannelDidChangeState: dataChannel.readyState)
    }
    
    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        self.delegate?.webRTCClient(self, didReceiveData: buffer.data)
    }
}

// Factory-level functions

public func RTCInitializeSSL() -> Bool {
    // No direct equivalent needed on Android as initialization is handled differently
    // but we return true to maintain API compatibility
    return true
}

public func RTCCleanupSSL() {
    // No direct equivalent needed on Android
}

// Helper for Swift/Kotlin conversion
fileprivate func deepSwift(value: Any) -> Any {
    if value is String || value is Number || value is Boolean {
        return value // Return primitive types as-is
    } else if let map = value as? kotlin.collections.Map<AnyObject, AnyObject> {
        var dict = [String: Any]()
        for (key, val) in map {
            if let keyString = key as? String {
                dict[keyString] = deepSwift(value: val)
            }
        }
        return dict
    } else if let list = value as? kotlin.collections.List<AnyObject> {
        return list.map { deepSwift(value: $0) }
    } else {
        return value // Return other types as-is
    }
}

#endif
#endif
