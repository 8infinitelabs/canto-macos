import Foundation

@Observable
class SessionManager {
    enum State: Equatable { case idle, active }

    private(set) var state: State = .idle
    private(set) var currentSession: SessionRecord?
    private(set) var pastSessions: [SessionRecord] = []

    private let projectPath: String
    private let idleTimeout: TimeInterval
    private let groupingWindow: TimeInterval
    private var recentEvents: [(date: Date, path: String)] = []
    private var idleTimer: Timer?
    private let sessionsDirectory: URL

    init(projectPath: String, idleTimeout: TimeInterval = 300, groupingWindow: TimeInterval = 30) {
        self.projectPath = projectPath
        self.idleTimeout = idleTimeout
        self.groupingWindow = groupingWindow

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.sessionsDirectory = appSupport.appendingPathComponent("Canto/sessions", isDirectory: true)
        try? FileManager.default.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)

        loadPastSessions()
    }

    func recordFileEvent(path: String, type: SessionEvent.EventType) {
        let now = Date()
        recentEvents.append((date: now, path: path))
        recentEvents.removeAll { now.timeIntervalSince($0.date) > groupingWindow }

        if state == .idle {
            if recentEvents.count >= 3 {
                startSession()
                // Replay buffered events into the new session
                if var session = currentSession {
                    for buffered in recentEvents {
                        let event = SessionEvent(type: .fileModified, path: buffered.path)
                        session.events.append(event)
                        updateStats(&session, type: .fileModified, path: buffered.path)
                    }
                    updateSessionName(&session)
                    currentSession = session
                }
                resetIdleTimer()
                return
            }
        }

        if state == .active, var session = currentSession {
            let event = SessionEvent(type: type, path: path)
            session.events.append(event)
            updateStats(&session, type: type, path: path)
            updateSessionName(&session)
            currentSession = session
            resetIdleTimer()
        }
    }

    private func updateSessionName(_ session: inout SessionRecord) {
        if session.nameSource == "file" && session.name == "New session" {
            if let firstMd = session.events.first(where: {
                ($0.type == .fileCreated || $0.type == .fileModified) && ($0.path?.hasSuffix(".md") ?? false)
            }) {
                session.name = URL(fileURLWithPath: firstMd.path ?? "").lastPathComponent
                session.nameSource = "file"
            }
        }
    }

    func recordCommit(hash: String, message: String, filesChanged: Int, insertions: Int, deletions: Int) {
        guard state == .active, var session = currentSession else { return }

        let commitEvent = SessionEvent(
            type: .commit,
            commitHash: hash,
            commitMessage: message,
            filesChanged: filesChanged,
            insertions: insertions,
            deletions: deletions
        )
        session.events.append(commitEvent)
        session.stats.commits += 1
        session.stats.totalInsertions += insertions
        session.stats.totalDeletions += deletions

        if session.stats.commits == 1 {
            session.name = message
            session.nameSource = "commit"
        }

        currentSession = session
        resetIdleTimer()
    }

    private func startSession() {
        currentSession = SessionRecord.create(projectPath: projectPath)
        state = .active
        resetIdleTimer()
    }

    private func resetIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleTimeout, repeats: false) { [weak self] _ in
            self?.endSession()
        }
    }

    private func endSession() {
        guard var session = currentSession else { return }
        session.status = .completed
        session.endedAt = Date()
        saveSession(session)
        pastSessions.insert(session, at: 0)
        currentSession = nil
        state = .idle
        recentEvents.removeAll()
        idleTimer?.invalidate()
    }

    private func updateStats(_ session: inout SessionRecord, type: SessionEvent.EventType, path: String) {
        switch type {
        case .fileCreated: session.stats.filesCreated += 1
        case .fileModified: session.stats.filesModified += 1
        case .fileDeleted: session.stats.filesDeleted += 1
        case .memoryCreated: session.stats.memoriesAdded += 1
        case .memoryUpdated: session.stats.memoriesUpdated += 1
        default: break
        }
    }

    private func saveSession(_ session: SessionRecord) {
        let url = sessionsDirectory.appendingPathComponent("\(session.id).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(session) {
            try? data.write(to: url)
        }
    }

    private func loadPastSessions() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: sessionsDirectory, includingPropertiesForKeys: nil)
            .filter({ $0.pathExtension == "json" })
            .sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
        else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        pastSessions = files.prefix(20).compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(SessionRecord.self, from: data)
        }
    }
}
