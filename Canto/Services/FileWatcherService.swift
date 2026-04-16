import Foundation

@Observable
class FileWatcherService: @unchecked Sendable {
    private var stream: FSEventStreamRef?
    private var watchedPath: String?
    private var retainedSelf: Unmanaged<FileWatcherService>?
    var onChange: ((String, FSEventStreamEventFlags) -> Void)?

    func startWatching(path: String) {
        stopWatching()
        watchedPath = path

        let retained = Unmanaged.passRetained(self)
        retainedSelf = retained

        var context = FSEventStreamContext()
        context.info = retained.toOpaque()

        let paths = [path] as CFArray
        stream = FSEventStreamCreate(
            nil,
            { _, info, numEvents, eventPaths, eventFlags, _ in
                guard let info else { return }
                let watcher = Unmanaged<FileWatcherService>.fromOpaque(info).takeUnretainedValue()
                let cfPaths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as! [String]
                var events: [(String, UInt32)] = []
                for i in 0..<numEvents {
                    events.append((cfPaths[i], eventFlags[i]))
                }
                let handler = watcher.onChange
                DispatchQueue.main.async {
                    for (path, flags) in events {
                        handler?(path, flags)
                    }
                }
            },
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,
            UInt32(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )

        if let stream {
            FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(stream)
        }
    }

    func stopWatching() {
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
        stream = nil
        watchedPath = nil
        retainedSelf?.release()
        retainedSelf = nil
    }

    deinit {
        stopWatching()
    }
}
