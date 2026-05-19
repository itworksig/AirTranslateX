import Foundation

enum AppFileLocations {
    static var documentsDirectoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents", isDirectory: true)
    }

    static var appDocumentsDirectoryURL: URL {
        documentsDirectoryURL.appendingPathComponent("AirTranslateX", isDirectory: true)
    }

    static var configFileURL: URL {
        appDocumentsDirectoryURL.appendingPathComponent("config.ini", isDirectory: false)
    }

    static var transcriptsDirectoryURL: URL {
        appDocumentsDirectoryURL.appendingPathComponent("Transcripts", isDirectory: true)
    }
}
