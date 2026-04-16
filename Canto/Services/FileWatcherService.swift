import Foundation

@Observable
class FileWatcherService {
    private var stream: FSEventStreamRef?
    private var watchedPath: String?
    var onChange: ((String, FSEventStreamEventFlags) -> Void)?

    func startWatching(path: String) {
        stopWatching()
        watchedPath = path

        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        let paths = [path] as CFArray
        stream = FSEventStreamCreate(
            nil,
            { _, info, numEvents, eventPaths, eventFlags, _ in
                guard let info else { return }
                let watcher = Unmanaged<FileWatcherService>.fromOpaque(info).takeUnretainedValue()
                let paths = Unmanaged<CFArray>.fromOpaque(eventPaths).takeUnretainedValue() as! [String]
                for i in 0..<numEvents {
                    watcher.onChange?(paths[i], eventFlags[i])
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
    }

    deinit {
        stopWatching()
    }
}
