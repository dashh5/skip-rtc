import Foundation

#if !os(Android)
import WebRTC
#else
import org.webrtc.__
#endif

// MARK: - ICE Connection State

public enum SkipIceConnectionState: Int {
    case new = 0
    case checking = 1
    case connected = 2
    case completed = 3
    case failed = 4
    case disconnected = 5
    case closed = 6
    
    public static func fromOrdinal(_ ordinal: Int) -> SkipIceConnectionState {
        if let state = SkipIceConnectionState(rawValue: ordinal) {
            return state
        }
        return .new
    }
}

// MARK: - ICE Candidate & Session Description

public struct SkipIceCandidate {
    public let sdpMid: String?
    public let sdpMLineIndex: Int32
    public let sdp: String
    
    public init(sdpMid: String?, sdpMLineIndex: Int32, sdp: String) {
        self.sdpMid = sdpMid
        self.sdpMLineIndex = sdpMLineIndex
        self.sdp = sdp
    }
}

public struct SkipSessionDescription {
    public let type: String
    public let sdp: String
    
    public init(type: String, sdp: String) {
        self.type = type
        self.sdp = sdp
    }
}

// MARK: - Delegate Protocol

public protocol SkipWebRTCDelegate: AnyObject {
    func skipWebRTC(_ skipWebRTC: SkipWebRTCModule, didDiscoverLocalCandidate candidate: SkipIceCandidate)
    func skipWebRTC(_ skipWebRTC: SkipWebRTCModule, didChangeConnectionState state: SkipIceConnectionState)
}

#if os(Android)
// MARK: - Android SDP Observer classes

private class BaseSdpObserver: org.webrtc.SdpObserver {
    private let onSuccessHandler: (org.webrtc.SessionDescription?) -> Void
    
    init(onSuccess: @escaping (org.webrtc.SessionDescription?) -> Void) {
        self.onSuccessHandler = onSuccess
        super.init()
    }
    
    override func onCreateSuccess(sessionDescription: org.webrtc.SessionDescription) {
        onSuccessHandler(sessionDescription)
    }
    
    override func onSetSuccess() {
        onSuccessHandler(nil)
    }
    
    override func onCreateFailure(error: String?) {
        onSuccessHandler(nil)
    }
    
    override func onSetFailure(error: String?) {
        onSuccessHandler(nil)
    }
}
#endif

// MARK: - Main Module

public class SkipWebRTCModule {
    public weak var delegate: SkipWebRTCDelegate?
    
    #if !os(Android)
    private let peerConnection: RTCPeerConnection
    private let delegateImpl: SkipWebRTCDelegateImpl
    
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)
    }()
    #else
    private let peerConnection: org.webrtc.PeerConnection
    private let observerImpl: SkipWebRTCObserverImpl
    
    private static let factory: org.webrtc.PeerConnectionFactory = {
        let initOptions = org.webrtc.PeerConnectionFactory.InitializationOptions.builder(ProcessInfo.processInfo.androidContext)
            .createInitializationOptions()
        org.webrtc.PeerConnectionFactory.initialize(initOptions)
        return org.webrtc.PeerConnectionFactory.builder()
            .createPeerConnectionFactory()
    }()
    #endif
    
    #if !os(Android)
    private var localVideoTrack: RTCVideoTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    #else
    private var localVideoTrack: org.webrtc.VideoTrack?
    private var remoteVideoTrack: org.webrtc.VideoTrack?
    #endif
    
    // MARK: - Initialization
    
    public init(iceServers: [String]) {
        #if !os(Android)
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: iceServers)]
        config.sdpSemantics = .unifiedPlan
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let delegateImpl = SkipWebRTCDelegateImpl()
        
        guard let pc = Self.factory.peerConnection(with: config, constraints: constraints, delegate: delegateImpl) else {
            fatalError("Failed to create RTCPeerConnection")
        }
        
        self.peerConnection = pc
        self.delegateImpl = delegateImpl
        self.delegateImpl.parent = self
        #else
        let iceServerList = java.util.ArrayList<org.webrtc.PeerConnection.IceServer>()
        let rtcConfig = org.webrtc.PeerConnection.RTCConfiguration(iceServerList)
        
        
        for serverUrl in iceServers {
            let urlsList = java.util.ArrayList<String>()
            urlsList.add(serverUrl)
            let iceServer = org.webrtc.PeerConnection.IceServer.builder(urlsList).createIceServer()
            iceServerList.add(iceServer)
        }
        
        rtcConfig.iceServers = iceServerList
        rtcConfig.sdpSemantics = org.webrtc.PeerConnection.SdpSemantics.UNIFIED_PLAN
        
        let observer = SkipWebRTCObserverImpl()
        guard let pc = Self.factory.createPeerConnection(rtcConfig, observer) else {
            fatalError("Failed to create PeerConnection")
        }
        
        self.peerConnection = pc
        self.observerImpl = observer
        self.observerImpl.parent = self
        #endif
        
        createMediaSenders()
    }
    
    // MARK: - Public API
    
    public func offer(completion: @escaping (SkipSessionDescription) -> Void) {
        #if !os(Android)
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"],
            optionalConstraints: nil
        )
        
        self.peerConnection.offer(for: constraints) { [weak self] sdp, error in
            guard let self = self, let sdp = sdp else { return }
            self.peerConnection.setLocalDescription(sdp) { error in
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
        
        let offerObserver = BaseSdpObserver { [weak self] sdp in
            guard let self = self, let sdp = sdp else { return }
            let setLocalObserver = BaseSdpObserver { _ in
                let sessionDescription = SkipSessionDescription(
                    type: sdp.type.toString(),
                    sdp: sdp.description
                )
                completion(sessionDescription)
            }
            self.peerConnection.setLocalDescription(setLocalObserver, sdp)
        }
        
        self.peerConnection.createOffer(offerObserver, constraints)
        #endif
    }
    
    public func answer(completion: @escaping (SkipSessionDescription) -> Void) {
        #if !os(Android)
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"],
            optionalConstraints: nil
        )
        
        self.peerConnection.answer(for: constraints) { [weak self] sdp, error in
            guard let self = self, let sdp = sdp else { return }
            self.peerConnection.setLocalDescription(sdp) { error in
                let typeString: String
                switch sdp.type {
                case .offer: typeString = "offer"
                case .answer: typeString = "answer"
                case .prAnswer: typeString = "pranswer"
                case .rollback: typeString = "rollback"
                @unknown default: typeString = "answer"
                }
                completion(SkipSessionDescription(type: typeString, sdp: sdp.sdp))
            }
        }
        #else
        let constraints = org.webrtc.MediaConstraints()
        constraints.mandatory.add(org.webrtc.MediaConstraints.KeyValuePair("OfferToReceiveAudio", "true"))
        constraints.mandatory.add(org.webrtc.MediaConstraints.KeyValuePair("OfferToReceiveVideo", "true"))
        
        let answerObserver = BaseSdpObserver { [weak self] sdp in
            guard let self = self, let sdp = sdp else { return }
            let setLocalObserver = BaseSdpObserver { _ in
                let sessionDescription = SkipSessionDescription(
                    type: sdp.type.toString(),
                    sdp: sdp.description
                )
                completion(sessionDescription)
            }
            self.peerConnection.setLocalDescription(setLocalObserver, sdp)
        }
        
        self.peerConnection.createAnswer(answerObserver, constraints)
        #endif
    }
    
    public func set(remoteSdp: SkipSessionDescription, completion: @escaping (Error?) -> Void) {
        #if !os(Android)
        let sdpType: RTCSdpType
        switch remoteSdp.type.lowercased() {
        case "offer": sdpType = .offer
        case "answer": sdpType = .answer
        case "pranswer": sdpType = .prAnswer
        case "rollback": sdpType = .rollback
        default: sdpType = .offer
        }
        
        let sdp = RTCSessionDescription(type: sdpType, sdp: remoteSdp.sdp)
        self.peerConnection.setRemoteDescription(sdp, completionHandler: completion)
        #else
        let sdpType = org.webrtc.SessionDescription.Type.valueOf(remoteSdp.type.uppercased())
        let sdp = org.webrtc.SessionDescription(sdpType, remoteSdp.sdp)
        
        let setRemoteObserver = BaseSdpObserver { _ in
            completion(nil)
        }
        
        self.peerConnection.setRemoteDescription(setRemoteObserver, sdp)
        #endif
    }
    
    public func add(iceCandidate: SkipIceCandidate) {
        #if !os(Android)
        let candidate = RTCIceCandidate(
            sdp: iceCandidate.sdp,
            sdpMLineIndex: iceCandidate.sdpMLineIndex,
            sdpMid: iceCandidate.sdpMid
        )
        self.peerConnection.add(candidate)
        #else
        let candidate = org.webrtc.IceCandidate(
            iceCandidate.sdpMid,
            iceCandidate.sdpMLineIndex,
            iceCandidate.sdp
        )
        self.peerConnection.addIceCandidate(candidate)
        #endif
    }
    
    public func muteAudio(_ muted: Bool) {
        #if !os(Android)
        peerConnection.transceivers
            .compactMap { $0.sender.track as? RTCAudioTrack }
            .forEach { $0.isEnabled = !muted }
        #else
        let transceivers = peerConnection.transceivers
        for transceiver in transceivers {
            let sender = transceiver.sender
            if sender != nil && sender.track() != nil && sender.track() is org.webrtc.AudioTrack {
                let audioTrack = sender.track() as! org.webrtc.AudioTrack
                audioTrack.setEnabled(!muted)
            }
        }
        #endif
    }
    
    public func muteVideo(_ muted: Bool) {
        #if !os(Android)
        peerConnection.transceivers
            .compactMap { $0.sender.track as? RTCVideoTrack }
            .forEach { $0.isEnabled = !muted }
        #else
        let transceivers = peerConnection.transceivers
        for transceiver in transceivers {
            let sender = transceiver.sender
            if sender != nil && sender.track() != nil && sender.track() is org.webrtc.VideoTrack {
                let videoTrack = sender.track() as! org.webrtc.VideoTrack
                videoTrack.setEnabled(!muted)
            }
        }
        #endif
    }
    
    public func close() {
        #if !os(Android)
        peerConnection.close()
        #else
        peerConnection.close()
        #endif
    }
    
    // MARK: - Private Helper Methods
    
    private func createMediaSenders() {
        #if !os(Android)
        let audioTrack = Self.factory.audioTrack(with: Self.factory.audioSource(with: nil), trackId: "audio0")
        self.peerConnection.add(audioTrack, streamIds: ["stream"])
        
        let videoSource = Self.factory.videoSource()
        let videoTrack = Self.factory.videoTrack(with: videoSource, trackId: "video0")
        self.localVideoTrack = videoTrack
        self.peerConnection.add(videoTrack, streamIds: ["stream"])
        #else
        let audioConstraints = org.webrtc.MediaConstraints()
        let audioSource = Self.factory.createAudioSource(audioConstraints)
        let audioTrack = Self.factory.createAudioTrack("audio0", audioSource)
        
        let videoSource = Self.factory.createVideoSource(true)
        let videoTrack = Self.factory.createVideoTrack("video0", videoSource)
        self.localVideoTrack = videoTrack
        
        let streamIdList = java.util.ArrayList<String>()
        streamIdList.add("stream")
        
        self.peerConnection.addTrack(audioTrack, streamIdList)
        self.peerConnection.addTrack(videoTrack, streamIdList)
        #endif
    }
}

// MARK: - Platform-Specific Implementations

#if !os(Android)
private class SkipWebRTCDelegateImpl: NSObject, RTCPeerConnectionDelegate {
    weak var parent: SkipWebRTCModule?
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        let state = SkipIceConnectionState(rawValue: newState.rawValue) ?? .new
        parent?.delegate?.skipWebRTC(parent!, didChangeConnectionState: state)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        let skipCandidate = SkipIceCandidate(
            sdpMid: candidate.sdpMid,
            sdpMLineIndex: candidate.sdpMLineIndex,
            sdp: candidate.sdp
        )
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
    
    override func onIceConnectionChange(newState: org.webrtc.PeerConnection.IceConnectionState) {
        let state = SkipIceConnectionState.fromOrdinal(newState.ordinal)
        if let parent = parent {
            parent.delegate?.skipWebRTC(parent, didChangeConnectionState: state)
        }
    }
    
    override func onIceCandidate(candidate: org.webrtc.IceCandidate) {
        let skipCandidate = SkipIceCandidate(
            sdpMid: candidate.sdpMid,
            sdpMLineIndex: candidate.sdpMLineIndex,
            sdp: candidate.sdp
        )
        if let parent = parent {
            parent.delegate?.skipWebRTC(parent, didDiscoverLocalCandidate: skipCandidate)
        }
    }
    
    override func onIceCandidatesRemoved(candidates: java.util.ArrayList<org.webrtc.IceCandidate>) {}
    override func onIceConnectionReceivingChange(recieving: Bool) {}
    override func onSignalingChange(newState: org.webrtc.PeerConnection.SignalingState) {}
    override func onIceGatheringChange(newState: org.webrtc.PeerConnection.IceGatheringState) {}
    override func onAddStream(stream: org.webrtc.MediaStream) {}
    override func onRemoveStream(stream: org.webrtc.MediaStream) {}
    override func onDataChannel(dataChannel: org.webrtc.DataChannel) {}
    override func onRenegotiationNeeded() {}
}
#endif
