// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if !SKIP_BRIDGE
#if SKIP
import Foundation
import SkipFoundation
import SkipFuse
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
        default: return .new
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
        default: return .closed
        }
    }
}

// RTCSessionDescription class bridging iOS to Android
public class RTCSessionDescription: KotlinConverting<org.webrtc.SessionDescription> {
    public let platformDescription: org.webrtc.SessionDescription
    
    public init(_ platformDescription: org.webrtc.SessionDescription) {
        self.platformDescription = platformDescription
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.SessionDescription {
        return platformDescription
    }
    
    public var type: RTCSessionDescriptionType {
        switch platformDescription.type {
        case org.webrtc.SessionDescription.Type.OFFER: return .offer
        case org.webrtc.SessionDescription.Type.ANSWER: return .answer
        case org.webrtc.SessionDescription.Type.PRANSWER: return .prAnswer
        default: return .offer
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

// RTCVideoFrame class bridging iOS to Android
public class RTCVideoFrame: KotlinConverting<org.webrtc.VideoFrame> {
    public let platformFrame: org.webrtc.VideoFrame
    
    public init(_ platformFrame: org.webrtc.VideoFrame) {
        self.platformFrame = platformFrame
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.VideoFrame {
        return platformFrame
    }
}

// RTCDataBuffer class bridging iOS to Android
public class RTCDataBuffer: KotlinConverting<org.webrtc.DataChannel.Buffer> {
    public let platformBuffer: org.webrtc.DataChannel.Buffer
    public let data: Data
    
    public init(data: Data, isBinary: Bool) {
        let byteBuffer = java.nio.ByteBuffer.wrap(data.kotlin())
        self.platformBuffer = org.webrtc.DataChannel.Buffer(byteBuffer, isBinary)
        self.data = data
    }
    
    public init(_ platformBuffer: org.webrtc.DataChannel.Buffer) {
        self.platformBuffer = platformBuffer
        
        // Convert ByteBuffer to Data
        let byteBuffer = platformBuffer.data
        let bytes = byteBuffer.remaining()
        var byteArray = [Byte](repeating: 0, count: bytes)
        byteBuffer.get(byteArray)
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
    
    public init(_ platformChannel: org.webrtc.DataChannel) {
        self.platformChannel = platformChannel
        
        // Set up observer
        platformChannel.registerObserver(object : org.webrtc.DataChannel.Observer {
            override func onBufferedAmountChange(previousAmount: Long) {
                // Not used in your implementation
            }
            
            override func onStateChange() {
                delegate?.dataChannelDidChangeState(RTCDataChannel(platformChannel))
            }
            
            override func onMessage(buffer: org.webrtc.DataChannel.Buffer) {
                delegate?.dataChannel(RTCDataChannel(platformChannel), didReceiveMessageWith: RTCDataBuffer(buffer))
            }
        })
    }
    
    public override func kotlin(nocopy: Bool = false) -> org.webrtc.DataChannel {
        return platformChannel
    }
    
    public var readyState: RTCDataChannelState {
        return RTCDataChannelState.fromPlatformState(platformChannel.state())
    }
    
    public func close() {
        platformChannel.close()
    }
    
    public func sendData(_ buffer: RTCDataBuffer) -> Bool {
        return platformChannel.send(buffer.platformBuffer)
    }
}

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
        // We need to adapt RTCVideoRenderer to org.webrtc.VideoSink
        let sink = org.webrtc.VideoSink {
            override func onFrame(frame: org.webrtc.VideoFrame) {
                renderer.renderFrame(RTCVideoFrame(frame))
            }
        }
        platformTrack.addSink(sink)
    }
    
    public func remove(_ renderer: RTCVideoRenderer) {
        // This is approximate as we don't have direct sink reference
        // In a full implementation, we'd maintain a map of renderers to sinks
        // For now we'll assume removal isn't used or will be handled differently
    }
}

// RTCVideoCapturer protocol
public protocol RTCVideoCapturer {
    func stopCapture() async
}

// RTCCameraVideoCapturer class bridging iOS to Android
public class RTCCameraVideoCapturer: RTCVideoCapturer, KotlinConverting<org.webrtc.Camera2Capturer> {
    public let platformCapturer: org.webrtc.Camera2Capturer
    
    public init(delegate: RTCVideoSource) {
        let context = ProcessInfo.processInfo.androidContext
        // Default to front camera
        let cameraManager = context.getSystemService(android.content.Context.CAMERA_SERVICE) as! android.hardware.camera2.CameraManager
        var frontCameraId = ""
        
        for cameraId in cameraManager.cameraIdList {
            let characteristics = cameraManager.getCameraCharacteristics(cameraId)
            let facing = characteristics.get(android.hardware.camera2.CameraCharacteristics.LENS_FACING) as! Int
            if facing == android.hardware.camera2.CameraCharacteristics.LENS_FACING_FRONT {
                frontCameraId = cameraId
                break
            }
        }
        
        self.platformCapturer = org.webrtc.Camera2Capturer(
            context,
            frontCameraId,
            object : org.webrtc.CameraVideoCapturer.CameraEventsHandler {
                override func onCameraError(error: String) {
                    // Log error
                }
                
                override func onCameraDisconnected() {
                    // Handle disconnection
                }
                
                override func onCameraFreezed(error: String) {
                    // Handle freeze
                }
                
                override func onCameraOpening(cameraName: String) {
                    // Camera is opening
                }
                
                override func onFirstFrameAvailable() {
                    // First frame is available
                }
                
                override func onCameraClosed() {
                    // Camera closed
                }
            }
        )
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
        
        let characteristics = cameraManager.getCameraCharacteristics(device.deviceId)
        let streamMap = characteristics.get(android.hardware.camera2.CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
        
        let outputSizes = streamMap.getOutputSizes(android.graphics.ImageFormat.YUV_420_888)
        for size in outputSizes {
            let format = CaptureFormat(width: size.width, height: size.height)
            formats.append(format)
        }
        
        return formats
    }
    
    public func startCapture(with device: CaptureDevice, format: CaptureFormat, fps: Int) {
        let videoSource = org.webrtc.SurfaceTextureHelper.create("WebRTCCameraCaptureThread", null)
        platformCapturer.initialize(videoSource, ProcessInfo.processInfo.androidContext) {
            platformCapturer.startCapture(format.width, format.height, fps)
        }
    }
    
    public func stopCapture() async {
        platformCapturer.stopCapture()
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
    
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        // Default to common frame rates
        self.videoSupportedFrameRateRanges = [FrameRateRange(minFrameRate: 15.0, maxFrameRate: 30.0)]
    }
    
    public var formatDescription: CMFormatDescription {
        return CMFormatDescription() // Stub - would need more implementation
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

// Stub for CMFormatDescription - would need more implementation
public class CMFormatDescription {
    public init() {}
    
    public static func getDimensions(_ desc: CMFormatDescription) -> CaptureFormatDimensions {
        return CaptureFormatDimensions(width: 0, height: 0) // Stub
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
}

// RTCAudioSession class for audio management
public class RTCAudioSession {
    private let audioManager: android.media.AudioManager
    
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
        case .playback:
            audioManager.mode = android.media.AudioManager.MODE_NORMAL
        }
    }
    
    public func setActive(_ active: Bool) throws {
        // Android doesn't have a direct equivalent, but we can request audio focus
        if active {
            let audioFocusRequest = android.media.AudioFocusRequest.Builder(android.media.AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(android.media.AudioAttributes.Builder()
                    .setUsage(android.media.AudioAttributes.USAGE_VOICE_COMMUNICATION)
                    .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build())
                .setAcceptsDelayedFocusGain(true)
                .build()
            audioManager.requestAudioFocus(audioFocusRequest)
        } else {
            audioManager.abandonAudioFocus(null)
        }
    }
    
    public func setPreferredSampleRate(_ sampleRate: Double) throws {
        // Android doesn't expose this level of control
    }
    
    public func setPreferredIOBufferDuration(_ duration: Double) throws {
        // Android doesn't expose this level of control
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
}

public enum RTCAudioSessionPortOverride: Int {
    case none = 0
    case speaker = 1
}

public class RTCAudioSessionRouteDescription {
    public let outputs: [RTCAudioSessionPortDescription]
    
    public init(audioManager: android.media.AudioManager) {
        var outputs = [RTCAudioSessionPortDescription]()
        
        // Get current audio devices
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
    private var observer: org.webrtc.PeerConnection.Observer? = nil
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
        try kotlinx.coroutines.suspendCancellableCoroutine<Void> { continuation in
            let observer = org.webrtc.SdpObserver {
                override func onCreateSuccess(sdp: org.webrtc.SessionDescription?) {
                    // Not used for setLocalDescription
                }
                
                override func onSetSuccess() {
                    continuation.resume(Unit, null)
                }
                
                override func onCreateFailure(error: String?) {
                    // Not used for setLocalDescription
                }
                
                override func onSetFailure(error: String?) {
                    continuation.resumeWithException(Exception(error ? "Unknown error" : ""))
                }
            }
            
            platformConnection.setLocalDescription(observer, sdp.platformDescription)
        }
    }
    
    public func offer(for constraints: RTCMediaConstraints) async throws -> RTCSessionDescription {
        return try kotlinx.coroutines.suspendCancellableCoroutine { continuation in
            let platformConstraints = constraints.platformConstraints
            let observer = org.webrtc.SdpObserver {
                override func onCreateSuccess(sdp: org.webrtc.SessionDescription?) {
                    if (sdp != null) {
                        continuation.resume(RTCSessionDescription(sdp), null)
                    } else {
                        continuation.resumeWithException(Exception("SDP is null"))
                    }
                }
                
                override func onSetSuccess() {
                    // Not used for createOffer
                }
                
                override func onCreateFailure(error: String?) {
                    continuation.resumeWithException(Exception(error ? "Unknown error" : ""))
                }
                
                override func onSetFailure(error: String?) {
                    // Not used for createOffer
                }
            }
            
            platformConnection.createOffer(observer, platformConstraints)
        }
    }
    
    public func answer(for constraints: RTCMediaConstraints) async throws -> RTCSessionDescription {
        return try kotlinx.coroutines.suspendCancellableCoroutine { continuation in
            let platformConstraints = constraints.platformConstraints
            let observer = org.webrtc.SdpObserver {
                override func onCreateSuccess(sdp: org.webrtc.SessionDescription?) {
                    if (sdp != null) {
                        continuation.resume(RTCSessionDescription(sdp), null)
                    } else {
                        continuation.resumeWithException(Exception("SDP is null"))
                    }
                }
                
                override func onSetSuccess() {
                    // Not used for createAnswer
                }
                
                override func onCreateFailure(error: String?) {
                    continuation.resumeWithException(Exception(error ? "Unknown error" : ""))
                }
                
                override func onSetFailure(error: String?) {
                    // Not used for createAnswer
                }
            }
            
            platformConnection.createAnswer(observer, platformConstraints)
        }
    }
    
    public func offer(for constraints: RTCMediaConstraints, completionHandler: @escaping (_ sdp: RTCSessionDescription?, _ error: Error?) -> Void) {
        let platformConstraints = constraints.platformConstraints
        let observer =  org.webrtc.SdpObserver {
            override func onCreateSuccess(sdp: org.webrtc.SessionDescription?) {
                DispatchQueue.main.async {
                    if (sdp != null) {
                        completionHandler(RTCSessionDescription(sdp), nil)
                    } else {
                        completionHandler(nil, NSError(domain: "WebRTC", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDP is null"]))
                    }
                }
            }
            
            override func onSetSuccess() {
                // Not used for createOffer
            }
            
            override func onCreateFailure(error: String?) {
                DispatchQueue.main.async {
                    completionHandler(nil, NSError(domain: "WebRTC", code: -1, userInfo: [NSLocalizedDescriptionKey: error ?? "Unknown error"]))
                }
            }
            
            override func onSetFailure(error: String?) {
                // Not used for createOffer
            }
        }
        
        platformConnection.createOffer(observer, platformConstraints)
    }
    
    public func answer(for constraints: RTCMediaConstraints, completionHandler: @escaping (_ sdp: RTCSessionDescription?, _ error: Error?) -> Void) {
        let platformConstraints = constraints.platformConstraints
        let observer = org.webrtc.SdpObserver {
            override func onCreateSuccess(sdp: org.webrtc.SessionDescription?) {
                DispatchQueue.main.async {
                    if (sdp != null) {
                        completionHandler(RTCSessionDescription(sdp), nil)
                    } else {
                        completionHandler(nil, NSError(domain: "WebRTC", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDP is null"]))
                    }
                }
            }
            
            override func onSetSuccess() {
                // Not used for createAnswer
            }
            
            override func onCreateFailure(error: String?) {
                DispatchQueue.main.async {
                    completionHandler(nil, NSError(domain: "WebRTC", code: -1, userInfo: [NSLocalizedDescriptionKey: error ?? "Unknown error"]))
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
                if (success) {
                    completionHandler(nil)
                } else {
                    completionHandler(NSError(domain: "WebRTC", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to add ICE candidate"]))
                }
            }
        }
    }
    
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
        if (platformChannel != null) {
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
                    completionHandler(NSError(domain: "WebRTC", code: -1, userInfo: [NSLocalizedDescriptionKey: error ?? "Unknown error"]))
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
    public func statistics(_ completionHandler: @escaping ([String: RTCStatisticsReport]) -> Void) {
        platformConnection.getStats { statsReport in
            // Convert Android stats report to iOS-like structure
            let statsMap = [String: RTCStatisticsReport]()
            // Implementation would need to convert between report formats
            // This is a simplified placeholder
            DispatchQueue.main.async {
                completionHandler(statsMap)
            }
        }
    }
}

// RTCDataChannelConfiguration class for data channel configuration
public class RTCDataChannelConfiguration {
    public var isOrdered: Boolean = true
    public var maxRetransmitTimeMs: Int = -1
    public var maxRetransmits: Int = -1
    public var protocolName: String = ""
    public var isNegotiated: Boolean = false
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
            return .audio // Default fallback
        }
    }
    
    public var sender: RTCRtpSender {
        return RTCRtpSender(platformTransceiver.sender)
    }
    
    public var receiver: RTCRtpReceiver {
        return RTCRtpReceiver(platformTransceiver.receiver)
    }
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
            if (track == null) {
                return nil
            }
            
            if (track is org.webrtc.AudioTrack) {
                return RTCAudioTrack(track as! org.webrtc.AudioTrack)
            } else if (track is org.webrtc.VideoTrack) {
                return RTCVideoTrack(track as! org.webrtc.VideoTrack)
            }
            
            return nil
        }
        set {
            if (newValue == nil) {
                platformSender.setTrack(null, false)
            } else if let audioTrack = newValue as? RTCAudioTrack {
                platformSender.setTrack(audioTrack.platformTrack, false)
            } else if let videoTrack = newValue as? RTCVideoTrack {
                platformSender.setTrack(videoTrack.platformTrack, false)
            }
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
        if (track == null) {
            return nil
        }
        
        if (track is org.webrtc.AudioTrack) {
            return RTCAudioTrack(track as! org.webrtc.AudioTrack)
        } else if (track is org.webrtc.VideoTrack) {
            return RTCVideoTrack(track as! org.webrtc.VideoTrack)
        }
        
        return nil
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
        default: return .stable
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
        default: return .new
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
}

// RTCStatisticsReport class - simplified placeholder
public class RTCStatisticsReport {
    // This would need a more complete implementation to match the iOS API
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

// WebRTCClient class - the main class from your original implementation
public final class WebRTCClient: NSObject, Sendable, KotlinConverting<org.webrtc.PeerConnectionFactory> {
    public weak var delegate: WebRTCClientDelegate?
    
    private let peerConnection: RTCPeerConnection
    private let rtcAudioSession = RTCAudioSession.sharedInstance
    private let audioQueue = DispatchQueue(label: "audio")
    
    private var silenceDetectionTimer: Timer?
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
        
        // Create factory
        let encoderFactory = org.webrtc.DefaultVideoEncoderFactory(
            org.webrtc.EglBase.create().eglBaseContext,
            true,
            true
        )
        
        let decoderFactory = org.webrtc.DefaultVideoDecoderFactory(
            org.webrtc.EglBase.create().eglBaseContext
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
        
        // Create peer connection constraints
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue]
        )
        
        // Create peer connection observer
        let observer = org.webrtc.PeerConnection.Observer {
            override func onSignalingChange(state: org.webrtc.PeerConnection.SignalingState) {
                let swiftState = RTCSignalingState.fromPlatformState(state)
                delegate?.peerConnection(peerConnection, didChange: swiftState)
            }
            
            override func onIceConnectionChange(state: org.webrtc.PeerConnection.IceConnectionState) {
                let swiftState = RTCIceConnectionState.fromPlatformState(state)
                delegate?.peerConnection(peerConnection, didChange: swiftState)
                delegate?.webRTCClient(WebRTCClient.this, didChangeConnectionState: swiftState)
            }
            
            override func onIceConnectionReceivingChange(receiving: Boolean) {
                // Not used in the original implementation
            }
            
            override func onIceGatheringChange(state: org.webrtc.PeerConnection.IceGatheringState) {
                let swiftState = RTCIceGatheringState.fromPlatformState(state)
                delegate?.peerConnection(peerConnection, didChange: swiftState)
            }
            
            override func onIceCandidate(candidate: org.webrtc.IceCandidate) {
                let swiftCandidate = RTCIceCandidate(candidate)
                delegate?.peerConnection(peerConnection, didGenerate: swiftCandidate)
                delegate?.webRTCClient(WebRTCClient.this, didDiscoverLocalCandidate: swiftCandidate)
            }
            
            override func onIceCandidatesRemoved(candidates: Array<org.webrtc.IceCandidate>) {
                let swiftCandidates = candidates.map { RTCIceCandidate($0) }.toList().toTypedArray()
                delegate?.peerConnection(peerConnection, didRemove: swiftCandidates)
            }
            
            override func onAddStream(stream: org.webrtc.MediaStream) {
                delegate?.peerConnection(peerConnection, didAdd: RTCMediaStream(stream))
            }
            
            override func onRemoveStream(stream: org.webrtc.MediaStream) {
                delegate?.peerConnection(peerConnection, didRemove: RTCMediaStream(stream))
            }
            
            override func onDataChannel(dataChannel: org.webrtc.DataChannel) {
                let swiftDataChannel = RTCDataChannel(dataChannel)
                remoteDataChannel = swiftDataChannel
                delegate?.peerConnection(peerConnection, didOpen: swiftDataChannel)
            }
            
            override func onRenegotiationNeeded() {
                delegate?.peerConnectionShouldNegotiate(peerConnection)
            }
            
            override func onAddTrack(receiver: org.webrtc.RtpReceiver, streams: Array<org.webrtc.MediaStream>) {
                if (receiver.track() is org.webrtc.VideoTrack) {
                    let videoTrack = receiver.track() as! org.webrtc.VideoTrack
                    remoteVideoTrack = RTCVideoTrack(videoTrack)
                }
                
                if (receiver.track() is org.webrtc.AudioTrack) {
                    let audioTrack = receiver.track() as! org.webrtc.AudioTrack
                    // Handle audio track reception
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
    
    // MARK: - Signaling
    
    public func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: self.mediaConstraints,
                                             optionalConstraints: nil)
        self.peerConnection.offer(for: constraints) { (sdp, error) in
            guard let sdp = sdp else {
                return
            }
            self.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                completion(sdp)
            })
        }
    }
    
    public func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: self.mediaConstraints,
                                             optionalConstraints: nil)
        self.peerConnection.answer(for: constraints) { (sdp, error) in
            guard let sdp = sdp else {
                return
            }
            
            self.peerConnection.setLocalDescription(sdp, completionHandler: { (error) in
                completion(sdp)
            })
        }
    }
    
    public func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> ()) {
        self.peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }
    
    public func set(remoteCandidate: RTCIceCandidate, completion: @escaping (Error?) -> ()) {
        self.peerConnection.add(remoteCandidate, completionHandler: completion)
    }
    
    // MARK: - Media
    
    public func startCaptureLocalVideo(renderer: RTCVideoRenderer) {
        guard let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
            return
        }
        
        guard
            let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),
            let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted {
                let width1 = CMFormatDescription.getDimensions($0.formatDescription).width
                let width2 = CMFormatDescription.getDimensions($1.formatDescription).width
                return width1 < width2
            }).last,
            let fps = (format.videoSupportedFrameRateRanges.sorted { $0.maxFrameRate < $1.maxFrameRate }.last)
        else {
            return
        }
        
        capturer.startCapture(with: frontCamera,
                              format: format,
                              fps: Int(fps.maxFrameRate))
        
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
        self.remoteVideoTrack = self.peerConnection.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
        
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
        }
        
        return nil
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
        silenceDetectionTimer?.invalidate()
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
        
        // 5. Create and set an empty answer to clean up connection state
        let cleanupConstraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "false",
                "OfferToReceiveVideo": "false"
            ],
            optionalConstraints: nil
        )
        
        // 6. Remove all transceivers and tracks
        peerConnection.transceivers.forEach { transceiver in
            let sender = transceiver.sender
            sender.track = nil
            peerConnection.removeTrack(sender)
        }
        
        // 7. Finally close the connection
        peerConnection.close()
    }
    
    // MARK: - Audio Control
    
    public func muteAudio() {
        print("DEBUG: Muting audio")
        self.setAudioEnabled(false)
    }
    
    public func unmuteAudio() {
        print("DEBUG: Unmuting audio.")
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
                print("Error setting AVAudioSession category: \(error)")
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
                print("Audio output route (IN setAudioSession):", output.portType, output.portName)
            }
        } catch {
            print("Couldn't force audio to speaker: \(error.localizedDescription)")
        }
        self.rtcAudioSession.unlockForConfiguration()
    }
    
    // Force audio to speaker
    public func speakerOn() {
        print("DEBUG: Forcing audio to speaker.")
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
            // This is a simplified placeholder for audio level stats
            // Need to extract audio level from RTCStatsReport
            DispatchQueue.main.async {
                // Default placeholder value
                completion(0.5)
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

public func RTCInitializeSSL() {
    // No direct equivalent needed on Android as initialization is handled differently
}

public class RTCPeerConnectionFactory {
    public static func factory(encoderFactory: Any, decoderFactory: Any) -> WebRTCClient {
        fatalError("Use WebRTCClient init method instead")
    }
}

// MARK: - Helper methods for PeerConnection configuration

public class RTCConfiguration {
    // This would need proper implementation to match the full iOS API
}

public func deepSwift<T>(value: T) -> Any {
    return value
}

#endif
#endif
