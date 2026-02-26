//
//  Raw2DNGConverter.swift
//  Raw2DNG
//
//  Handles batch conversion of RAW files
//

import Foundation
import Combine
import Raw2DngLibrary

internal import CxxStdlib

class Raw2DNGConverter: ObservableObject {
    @Published var isConverting = false
    @Published var currentFile = ""
    @Published var convertedCount = 0
    @Published var totalCount = 0
    @Published var statusMessage = ""
    @Published var hasError = false
    
    private let rawExtensions = ["cr2", "nef", "arw", "orf", "rw2", "dng", "raf", "raw", "3fr", "ari", "arw", "bay", "crw", "cr2", "cap", "data", "dcs", "dcr", "dng", "drf", "eip", "erf", "fff", "gpr", "iiq", "k25", "kdc", "mdc", "mef", "mos", "mrw", "nef", "nrw", "obm", "orf", "pef", "ptx", "pxn", "r3d", "raf", "raw", "rwl", "rw2", "rwz", "sr2", "srf", "srw", "x3f"]
    
    func convertFiles(in folderURL: URL, completion: @escaping (Bool, String) -> Void) {
        // Request access to the folder
        guard folderURL.startAccessingSecurityScopedResource() else {
            DispatchQueue.main.async {
                self.statusMessage = "Unable to access folder"
                self.hasError = true
            }
            completion(false, "Unable to access folder")
            return
        }
        
        defer {
            folderURL.stopAccessingSecurityScopedResource()
        }
        
        // Start conversion in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isConverting = true
                self.hasError = false
                self.statusMessage = "Scanning folder..."
            }
            
            // Get all RAW files in the folder
            let rawFiles = self.getRawFiles(in: folderURL)
            
            guard !rawFiles.isEmpty else {
                DispatchQueue.main.async {
                    self.isConverting = false
                    self.statusMessage = "No RAW files found in folder"
                    self.hasError = true
                }
                completion(false, "No RAW files found in folder")
                return
            }
            
            DispatchQueue.main.async {
                self.totalCount = rawFiles.count
                self.convertedCount = 0
                self.statusMessage = "Found \(rawFiles.count) RAW files"
            }
            
            // Convert each file
            var successCount = 0
            var failCount = 0
            
            for (index, rawFile) in rawFiles.enumerated() {
                DispatchQueue.main.async {
                    self.currentFile = rawFile.lastPathComponent
                    self.convertedCount = index + 1
                }
                
                let outputFile = self.getOutputFilename(for: rawFile)
          
                // Call the C++ conversion function
                var r2d = Raw2DngConverter();
                let error = r2d.raw2dng(
                    std.string(rawFile.path.cString(using: .utf8)),
                    std.string(rawFile.path.cString(using: .utf8))
                )
                
                if error.empty() {
                    successCount += 1
                } else {
                    failCount += 1
                    print("Failed to convert: \(std.string(rawFile.path.cString(using: .utf8))) - \(error)")
                }

                // Update progress
                DispatchQueue.main.async {
                    self.statusMessage = "Converted: \(successCount), Failed: \(failCount)"
                }
            }
            
            // Complete
            DispatchQueue.main.async {
                self.isConverting = false
                self.currentFile = ""
                let message = """
                Conversion complete!
                Successfully converted: \(successCount)
                Failed: \(failCount)
                """
                self.statusMessage = "Conversion complete!"
                self.hasError = failCount > 0
                completion(failCount == 0, message)
            }
        }
    }
    
    private func getRawFiles(in folderURL: URL) -> [URL] {
        let canAccess = folderURL.startAccessingSecurityScopedResource()
            
        // Ensure we release access when the function exits
        defer {
            if canAccess {
                folderURL.stopAccessingSecurityScopedResource()
            }
        }
    
        let fileManager = FileManager.default
            
        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        
        var rawFiles: [URL] = []
        
        for case let fileURL as URL in enumerator {
            print("Found file: \(fileURL.lastPathComponent)")
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  let isRegularFile = resourceValues.isRegularFile,
                  isRegularFile else {
                continue
            }
            
            let fileExtension = fileURL.pathExtension.lowercased()
            if rawExtensions.contains(fileExtension) {
                rawFiles.append(fileURL)
            }
        }
        
        return rawFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
    
    private func getOutputFilename(for inputURL: URL) -> URL {
        let directory = inputURL.deletingLastPathComponent()
        let filename = inputURL.deletingPathExtension().lastPathComponent
        return directory.appendingPathComponent("\(filename).dng")
    }
}
