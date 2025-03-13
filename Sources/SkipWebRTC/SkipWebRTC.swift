import Foundation

#if !os(Android)
import WebRTC
#else
import org.webrtc.__
#endif

public enum SkipIceConnectionState: Int {
    case new, checking, connected, completed, failed, disconnected, closed
}

public struct SkipIceCandidate {
    public let sdpMid: String?
    public let sdpMLineIndex: Int32
    public let sdp: String
}

public struct SkipSessionDescription {
    public let type: String
    public let sdp: String
}

public protocol SkipWebRTCDelegate: AnyObject {
    func skipWebRTC(_ skipWebRTC: SkipWebRTCModule, didDiscoverLocalCandidate candidate: SkipIceCandidate)
    func skipWebRTC(_ skipWebRTC: SkipWebRTCModule, didChangeConnectionState state: SkipIceConnectionState)
}

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
        org.webrtc.PeerConnectionFactory.initialize(org.webrtc.PeerConnectionFactory.InitializationOptions.builder().createInitializationOptions())
        return org.webrtc.PeerConnectionFactory.builder().createPeerConnectionFactory()
    }()
    #endif

    public init(iceServers: [String]) {
        #if !os(Android)
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: iceServers)]
        config.sdpSemantics = .unifiedPlan

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        guard let peerConnection = Self.factory.peerConnection(with: config, constraints: constraints, delegate: nil) else {
            fatalError("Failed to create RTCPeerConnection")
        }
        self.peerConnection = peerConnection
        self.delegateImpl = SkipWebRTCDelegateImpl(parent: nil) // Temporarily nil
        self.delegateImpl.parent = self                         // Set parent after initialization
        self.peerConnection.delegate = self.delegateImpl        // Assign delegate
        #else
        let rtcConfig = org.webrtc.PeerConnection.RTCConfiguration()
        rtcConfig.iceServers = iceServers.map { org.webrtc.PeerConnection.IceServer.builder($0).createIceServer() }
        rtcConfig.sdpSemantics = org.webrtc.PeerConnection.SdpSemantics.UNIFIED_PLAN

        guard let peerConnection = Self.factory.createPeerConnection(rtcConfig, nil) else {
            fatalError("Failed to create PeerConnection")
        }
        self.peerConnection = peerConnection
        self.observerImpl = SkipWebRTCObserverImpl(parent: nil) // Temporarily nil
        self.observerImpl.parent = self                         // Set parent after initialization
        self.peerConnection.setObserver(self.observerImpl)      // Assign observer
        #endif

        createMediaSenders()
    }

    public func offer(completion: @escaping (SkipSessionDescription) -> Void) {
        #if !os(Android)
        let constraints = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"], optionalConstraints: nil)
        self.peerConnection.offer(for: constraints) { sdp, _ in
            guard let sdp = sdp else { return }
            self.peerConnection.setLocalDescription(sdp) { _ in
                let typeString: String
                switch sdp.type {
                case .offer: typeString = "offer"
                case .answer: typeString = "answer"
                case .prAnswer: typeString = "pranswer"
                case .rollback: typeString = "rollback"
                @unknown default: typeString = "offer"
                }
                completion(SkipSessionDescription(type: typeString, sdp: sdp.sdp))
            }
        }
        #else
        let constraints = org.webrtc.MediaConstraints()
        constraints.mandatory.add(org.webrtc.MediaConstraints.KeyValuePair("OfferToReceiveAudio", "true"))
        constraints.mandatory.add(org.webrtc.MediaConstraints.KeyValuePair("OfferToReceiveVideo", "true"))
        self.peerConnection.createOffer(constraints) { sdp in
            self.peerConnection.setLocalDescription(sdp) { _ in
                if let sdp = sdp {
                    completion(SkipSessionDescription(type: sdp.type.toString(), sdp: sdp.description))
                }
            }
        }
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
        self.peerConnection.setRemoteDescription(sdp) { error in
            completion(error)
        }
        #endif
    }

    public func muteAudio() {
        #if !os(Android)
        peerConnection.transceivers
            .compactMap { $0.sender.track as? RTCAudioTrack }
            .forEach { $0.isEnabled = false }
        #else
        peerConnection.transceivers
            .compactMap { $0.sender.track as? org.webrtc.AudioTrack }
            .forEach { $0.setEnabled(false) }
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
        let audioTrack = Self.factory.createAudioTrack("audio0", Self.factory.createAudioSource(org.webrtc.MediaConstraints()))
        self.peerConnection.addTrack(audioTrack, ["stream"])

        let videoSource = Self.factory.createVideoSource()
        let videoTrack = Self.factory.createVideoTrack("video0", videoSource)
        self.localVideoTrack = videoTrack
        self.peerConnection.addTrack(videoTrack, ["stream"])
        #endif
    }
}

// MARK: - Delegate Implementations

#if !os(Android)
private class SkipWebRTCDelegateImpl: NSObject, RTCPeerConnectionDelegate {
    weak var parent: SkipWebRTCModule?

    init(parent: SkipWebRTCModule?) { // Allow nil parent during initialization
        self.parent = parent
        super.init()
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        let state = SkipIceConnectionState(rawValue: newState.rawValue) ?? .new
        parent?.delegate?.skipWebRTC(parent!, didChangeConnectionState: state)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let skipCandidate = SkipIceCandidate(sdpMid: candidate.sdpMid, sdpMLineIndex: candidate.sdpMLineIndex, sdp: candidate.sdp)
        parent?.delegate?.skipWebRTC(parent!, didDiscoverLocalCandidate: skipCandidate)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}
#else
private class SkipWebRTCObserverImpl: org.webrtc.PeerConnection.Observer {
    weak var parent: SkipWebRTCModule?

    init(parent: SkipWebRTCModule?) { // Allow nil parent during initialization
        self.parent = parent
    }

    override func onIceConnectionChange(newState: org.webrtc.PeerConnection.IceConnectionState) {
        let state = SkipIceConnectionState(rawValue: newState.ordinal()) ?? .new
        parent?.delegate?.skipWebRTC(parent!, didChangeConnectionState: state)
    }

    override func onIceCandidate(candidate: org.webrtc.IceCandidate) {
        let skipCandidate = SkipIceCandidate(sdpMid: candidate.sdpMid, sdpMLineIndex: candidate.sdpMLineIndex, sdp: candidate.sdp)
        parent?.delegate?.skipWebRTC(parent!, didDiscoverLocalCandidate: skipCandidate)
    }

    override func onSignalingChange(newState: org.webrtc.PeerConnection.SignalingState) {}
    override func onIceGatheringChange(newState: org.webrtc.PeerConnection.IceGatheringState) {}
    override func onAddStream(stream: org.webrtc.MediaStream) {}
    override func onRemoveStream(stream: org.webrtc.MediaStream) {}
    override func onDataChannel(dataChannel: org.webrtc.DataChannel) {}
    override func onRenegotiationNeeded() {}
    override func onAddTrack(receiver: org.webrtc.RtpReceiver, mediaStreams: [org.webrtc.MediaStream]) {}
}
#endif
