import Foundation

#if !os(Android)
import WebRTC
#else
import org.webrtc.__
#endif

// MARK: - ICE Connection State

@objc public enum SkipIceConnectionState: Int {
    case new, checking, connected, completed, failed, disconnected, closed

    public static func fromOrdinal(_ ordinal: Int) -> SkipIceConnectionState {
        switch ordinal {
        case 0: return .new
        case 1: return .checking
        case 2: return .connected
        case 3: return .completed
        case 4: return .failed
        case 5: return .disconnected
        case 6: return .closed
        default: return .new
        }
    }
}

// MARK: - ICE Candidate & Session Description

public struct SkipIceCandidate {
    public let sdpMid: String?
    public let sdpMLineIndex: Int32
    public let sdp: String
}

public struct SkipSessionDescription {
    public let type: String
    public let sdp: String
}

// MARK: - Delegate Protocol

public protocol SkipWebRTCDelegate: AnyObject {
    func skipWebRTC(_ skipWebRTC: SkipWebRTCModule, didDiscoverLocalCandidate candidate: SkipIceCandidate)
    func skipWebRTC(_ skipWebRTC: SkipWebRTCModule, didChangeConnectionState state: SkipIceConnectionState)
}

// MARK: - Main Module

public class SkipWebRTCModule {
    weak public var delegate: SkipWebRTCDelegate?

    #if !os(Android)
    private let peerConnection: RTCPeerConnection
    private let delegateImpl: SkipWebRTCDelegateImpl
    #else
    private let peerConnection: org.webrtc.PeerConnection
    private let observerImpl: SkipWebRTCObserverImpl
    #endif

    private var localVideoTrack: Any?
    private var remoteVideoTrack: Any?

    #if !os(Android)
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
    }()
    #else
    private static let factory: org.webrtc.PeerConnectionFactory = {
        org.webrtc.PeerConnectionFactory.initialize(
            org.webrtc.PeerConnectionFactory.InitializationOptions.builder().createInitializationOptions()
        )
        return org.webrtc.PeerConnectionFactory.builder().createPeerConnectionFactory()
    }()
    #endif

    public init(iceServers: [String]) {
        #if !os(Android)
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: iceServers)]
        config.sdpSemantics = .unifiedPlan

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        guard let pc = Self.factory.peerConnection(with: config, constraints: constraints, delegate: nil) else {
            fatalError("Failed to create RTCPeerConnection")
        }
        self.peerConnection = pc
        self.delegateImpl = SkipWebRTCDelegateImpl(parent: nil)
        self.delegateImpl.parent = self
        self.peerConnection.delegate = self.delegateImpl
        #else
        let rtcConfig = org.webrtc.PeerConnection.RTCConfiguration()
        // Initialize an empty Java ArrayList for ICE servers.
        let iceServerList = java.util.ArrayList<org.webrtc.PeerConnection.IceServer>()
        for server in iceServers {
            // Use Collections.singletonList to force the List<String> overload.
            let serverList = java.util.Collections.singletonList(server)
            let builder: org.webrtc.PeerConnection.IceServer.Builder = org.webrtc.PeerConnection.IceServer.builder(serverList)
            // Use build() instead of createIceServer(); adjust if your version differs.
            let iceServer = builder.build()
            iceServerList.add(iceServer)
        }
        rtcConfig.iceServers = iceServerList
        rtcConfig.sdpSemantics = org.webrtc.PeerConnection.SdpSemantics.UNIFIED_PLAN

        let observer = SkipWebRTCObserverImpl(parent: nil)
        guard let pc = Self.factory.createPeerConnection(rtcConfig, observer) else {
            fatalError("Failed to create PeerConnection")
        }
        self.peerConnection = pc
        self.observerImpl = observer
        self.observerImpl.parent = self
        #endif

        createMediaSenders()
    }

    public func offer(completion: @escaping (SkipSessionDescription) -> Void) {
        #if !os(Android)
        let constraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true",
                                                                      "OfferToReceiveVideo": "true"],
                                              optionalConstraints: nil)
        self.peerConnection.offer(for: constraints) { sdp, _ in
            guard let sdp = sdp else { return }
            self.peerConnection.setLocalDescription(sdp) { _ in
                // Use Swift string interpolation to get a String value.
                let typeString = "\(sdp.type)"
                completion(SkipSessionDescription(type: typeString, sdp: sdp.sdp))
            }
        }
        #else
        let constraints = org.webrtc.MediaConstraints()
        constraints.mandatory.add(org.webrtc.MediaConstraints.KeyValuePair("OfferToReceiveAudio", "true"))
        constraints.mandatory.add(org.webrtc.MediaConstraints.KeyValuePair("OfferToReceiveVideo", "true"))
        let offerObserver = SkipSdpObserver { sdp in
            guard let sdp = sdp else { return }
            let setLocalObserver = SkipSdpObserver { _ in
                // Use Swift interpolation here as well.
                completion(SkipSessionDescription(type: "\(sdp.type)", sdp: sdp.description))
            }
            self.peerConnection.setLocalDescription(setLocalObserver, sdp)
        }
        self.peerConnection.createOffer(offerObserver, constraints)
        #endif
    }

    public func set(remoteSdp: SkipSessionDescription, completion: @escaping (Error?) -> Void) {
        #if !os(Android)
        let sdpType: RTCSdpType
        switch remoteSdp.type.lowercased() {
        case "offer": sdpType = .offer
        case "answer": sdpType = .answer
        case "pranswer": sdpType = .prAnswer
        default: sdpType = .offer
        }
        let sdp = RTCSessionDescription(type: sdpType, sdp: remoteSdp.sdp)
        self.peerConnection.setRemoteDescription(sdp, completionHandler: completion)
        #else
        let sdpType = org.webrtc.SessionDescription.Type.valueOf(remoteSdp.type.uppercased())
        let sdp = org.webrtc.SessionDescription(sdpType, remoteSdp.sdp)
        let setRemoteObserver = SkipSdpObserver { _ in
            completion(nil)
        }
        self.peerConnection.setRemoteDescription(setRemoteObserver, sdp)
        #endif
    }

    public func muteAudio() {
        #if !os(Android)
        peerConnection.transceivers
            .compactMap { $0.sender.track as? RTCAudioTrack }
            .forEach { $0.isEnabled = false }
        #else
        // Temporarily leave Android muteAudio unimplemented.
        // (If you later discover the proper API for accessing the track on Android,
        // implement it here.)
        #endif
    }

    private func createMediaSenders() {
        #if !os(Android)
        let audioTrack = Self.factory.audioTrack(with: Self.factory.audioSource(with: nil), trackId: "audio0")
        self.peerConnection.add(audioTrack, streamIds: ["stream"])

        let videoSource = Self.factory.videoSource()
        let videoTrack = Self.factory.videoTrack(with: videoSource, trackId: "video0")
        self.localVideoTrack = videoTrack
        self.peerConnection.add(videoTrack, streamIds: ["stream"])
        #else
        let audioSource = Self.factory.createAudioSource(org.webrtc.MediaConstraints())
        let audioTrack = Self.factory.createAudioTrack("audio0", audioSource)
        let streamList = java.util.ArrayList<String>()
        streamList.add("stream")
        self.peerConnection.addTrack(audioTrack, streamList)
        
        // For your Android WebRTC version, createVideoSource may expect a Boolean.
        let videoSource = Self.factory.createVideoSource(true)
        let videoTrack = Self.factory.createVideoTrack("video0", videoSource)
        self.localVideoTrack = videoTrack
        self.peerConnection.addTrack(videoTrack, streamList)
        #endif
    }
}

#if !os(Android)
// iOS delegate wrapper
private class SkipWebRTCDelegateImpl: NSObject, RTCPeerConnectionDelegate {
    weak var parent: SkipWebRTCModule?
    init(parent: SkipWebRTCModule?) {
        self.parent = parent
        super.init()
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        let state = SkipIceConnectionState(rawValue: newState.rawValue) ?? .new
        parent?.delegate?.skipWebRTC(parent!, didChangeConnectionState: state)
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let skipCandidate = SkipIceCandidate(sdpMid: candidate.sdpMid,
                                             sdpMLineIndex: candidate.sdpMLineIndex,
                                             sdp: candidate.sdp)
        parent?.delegate?.skipWebRTC(parent!, didDiscoverLocalCandidate: skipCandidate)
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) { }
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) { }
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) { }
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) { }
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) { }
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) { }
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) { }
}
#else
// MARK: - Android Implementations

private class SkipSdpObserver: org.webrtc.SdpObserver {
    let onSuccess: (org.webrtc.SessionDescription?) -> Void
    init(onSuccess: @escaping (org.webrtc.SessionDescription?) -> Void) {
        self.onSuccess = onSuccess
    }
    override func onCreateSuccess(sessionDescription: org.webrtc.SessionDescription) {
        onSuccess(sessionDescription)
    }
    override func onSetSuccess() { }
    override func onCreateFailure(error: String?) {
        onSuccess(nil)
    }
    override func onSetFailure(error: String?) { }
}

private class SkipWebRTCObserverImpl: org.webrtc.PeerConnection.Observer {
    weak var parent: SkipWebRTCModule?
    init(parent: SkipWebRTCModule?) {
        self.parent = parent
    }
    override func onIceConnectionChange(newState: org.webrtc.PeerConnection.IceConnectionState) {
        let state = SkipIceConnectionState.fromOrdinal(newState.ordinal())
        parent?.delegate?.skipWebRTC(parent!, didChangeConnectionState: state)
    }
    override func onIceCandidatesRemoved(candidates: [org.webrtc.IceCandidate]) {
        // No operation required.
    }
    override func onIceCandidate(candidate: org.webrtc.IceCandidate) {
        let skipCandidate = SkipIceCandidate(sdpMid: candidate.sdpMid,
                                             sdpMLineIndex: candidate.sdpMLineIndex,
                                             sdp: candidate.sdp)
        parent?.delegate?.skipWebRTC(parent!, didDiscoverLocalCandidate: skipCandidate)
    }
    override func onSignalingChange(newState: org.webrtc.PeerConnection.SignalingState) { }
    override func onIceGatheringChange(newState: org.webrtc.PeerConnection.IceGatheringState) { }
    override func onAddStream(stream: org.webrtc.MediaStream) { }
    override func onRemoveStream(stream: org.webrtc.MediaStream) { }
    override func onDataChannel(dataChannel: org.webrtc.DataChannel) { }
    override func onRenegotiationNeeded() { }
    // If your version requires onAddTrack, implement it here.
    // override func onAddTrack(receiver: org.webrtc.RtpReceiver, mediaStreams: [org.webrtc.MediaStream]) { }
}
#endif
