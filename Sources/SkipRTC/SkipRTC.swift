// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception

import Foundation
import SwiftUI
#if SKIP
import io.livekit.android.__
import io.livekit.android.room.__
#else
import LiveKit
#endif

public class SkipRTCModule {
    func loadRoom() -> Room {
        #if SKIP
        let room: Room = LiveKit.create(ProcessInfo.processInfo.androidContext)
        #else
        class Delegate: RoomDelegate {
            // TODO…
        }
        let delegate = Delegate()
        let room: Room = Room(delegate: delegate)
        #endif

        return room
    }
}
