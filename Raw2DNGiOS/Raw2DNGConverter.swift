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
    
    private let rawExtensions = ["cr2", "nef", "arw", "orf", "rw2", "dng", "raf", "raw", "3fr", "ari", "arw", "bay", "crw", "cr2", "cap", "data", "dcs", "dcr", "drf", "eip", "erf", "fff", "gpr", "iiq", "k25", "kdc", "mdc", "mef", "mos", "mrw", "nef", "nrw", "obm", "orf", "pef", "ptx", "pxn", "r3d", "raf", "raw", "rwl", "rw2", "rwz", "sr2", "srf", "srw", "x3f"]
    
    func convertFiles(_ rawFiles: [URL], toFolder outputFolder: URL, completion: @escaping (Bool, String) -> Void) {

        // Start conversion in background
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isConverting = true
                self.hasError = false
                self.statusMessage = "Scanning folder..."
            }
            
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
                self.totalCount = rawFiles.count;
                self.statusMessage = "Found \(self.totalCount) RAW files"
            }
            
            // Convert each file
            var successCount = 0
            var failCount = 0
            
            for (index, rawFile) in rawFiles.enumerated() {
                DispatchQueue.main.async {
                    self.currentFile = rawFile.lastPathComponent
                }
                
                // 1. Request access to the security-scoped URL
                let outputFile = self.getOutputFilename(for: rawFile, in: outputFolder)
                let canAccess = rawFile.startAccessingSecurityScopedResource()
                    && outputFolder.startAccessingSecurityScopedResource()
                
                // 2. Use a 'defer' block to ensure we stop accessing the resource
                // no matter how the function exits
                defer {
                    if canAccess {
                        rawFile.stopAccessingSecurityScopedResource()
                        outputFolder.stopAccessingSecurityScopedResource()
                    }
                }

                if canAccess {
                    do {
                        let data = try Data(contentsOf: rawFile)
                        print("Successfully opened file: \(data.count) bytes")
                        var r2d = Raw2DngConverter();
                        let res = r2d.raw2dng(
                            std.string(rawFile.path.cString(using: .utf8)),
                            std.string(outputFile.path.cString(using: .utf8))
                        )
                        if (res.empty()) {
                            successCount += 1;
                        }
                        else {
                            failCount += 1;
                            print("Error processing file: \(res)")
                        }
                    } catch {
                        print("Error reading file: \(error.localizedDescription)")
                    }
                } else {
                    print("Permission denied by the OS.")
                }
                
                // Update progress
                DispatchQueue.main.async {
                    self.statusMessage = "Converted: \(successCount), Failed: \(failCount)"
                    self.convertedCount = successCount;
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
    
    private func getOutputFilename(for inputURL: URL, in outputFolder: URL) -> URL {
        let filename = inputURL.deletingPathExtension().lastPathComponent
        return outputFolder.appendingPathComponent("\(filename).dng")
    }
}
