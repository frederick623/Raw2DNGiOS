//
//  ContentView.swift
//  Raw2DNG
//
//  Main interface for RAW to DNG conversion
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var converter = Raw2DNGConverter()
    @State private var showingFilePicker = false
    @State private var showingOutputFolderPicker = false
    @State private var selectedFiles: [URL] = []
    @State private var outputFolder: URL?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text("RAW to DNG Converter")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                Spacer()
                
                // Selected files display
                if !selectedFiles.isEmpty {
                    VStack(spacing: 10) {
                        Text("Selected Files:")
                            .font(.headline)
                        Text("\(selectedFiles.count) RAW files")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        // Show first few file names
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(selectedFiles.prefix(3), id: \.self) { url in
                                Text("• \(url.lastPathComponent)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if selectedFiles.count > 3 {
                                Text("• and \(selectedFiles.count - 3) more...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Select Files Button
                Button(action: {
                    showingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                        Text("Select RAW Files")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .disabled(converter.isConverting)
                
                // Select Output Folder Button
                Button(action: {
                    showingOutputFolderPicker = true
                }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                            .font(.title2)
                        Text("Select Output Folder")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .disabled(converter.isConverting)
                
                // Convert Button
                Button(action: {
                    convertFiles()
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title2)
                        Text("Convert Files")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canConvert ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40)
                .disabled(!canConvert || converter.isConverting)
                
                // Output folder display
                if let outputURL = outputFolder {
                    VStack(spacing: 10) {
                        Text("Output Folder:")
                            .font(.headline)
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.green)
                            Text(outputURL.lastPathComponent)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Progress view
                if converter.isConverting {
                    VStack(spacing: 10) {
                        ProgressView(value: Double(converter.convertedCount), total: Double(converter.totalCount))
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding(.horizontal, 40)
                        
                        Text("Converting: \(converter.currentFile)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Text("\(converter.convertedCount) of \(converter.totalCount) files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Status message
                if !converter.statusMessage.isEmpty {
                    Text(converter.statusMessage)
                        .font(.body)
                        .foregroundColor(converter.hasError ? .red : .green)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
                
                // Info text
                Text("Supported formats: CR2, NEF, ARW, DNG, ORF, RAF, and more")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingFilePicker) {
                FilesPicker(selectedFiles: $selectedFiles)
            }
            .sheet(isPresented: $showingOutputFolderPicker) {
                FolderPicker(selectedFolder: $outputFolder)
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Conversion Complete"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private var canConvert: Bool {
        !selectedFiles.isEmpty && outputFolder != nil
    }
    
    private func convertFiles() {
        guard !selectedFiles.isEmpty, let output = outputFolder else { return }
        
        converter.convertFiles(selectedFiles, toFolder: output) { success, message in
            DispatchQueue.main.async {
                alertMessage = message
                showingAlert = true
            }
        }
    }
}

// Document Picker for selecting multiple RAW files
struct FilesPicker: UIViewControllerRepresentable {
    @Binding var selectedFiles: [URL]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Create document types for RAW files
        let rawTypes: [UTType] = [
            .data,  // Generic fallback
            UTType(filenameExtension: "cr2") ?? .data,
            UTType(filenameExtension: "nef") ?? .data,
            UTType(filenameExtension: "arw") ?? .data,
            UTType(filenameExtension: "dng") ?? .data,
            UTType(filenameExtension: "orf") ?? .data,
            UTType(filenameExtension: "raf") ?? .data,
            UTType(filenameExtension: "rw2") ?? .data,
        ]
        
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: rawTypes, asCopy: false)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilesPicker
        
        init(_ parent: FilesPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedFiles = urls
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Document Picker for selecting output folder
struct FolderPicker: UIViewControllerRepresentable {
    @Binding var selectedFolder: URL?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FolderPicker
        
        init(_ parent: FolderPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.selectedFolder = url
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
