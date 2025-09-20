//
//  QRCodeScannerView.swift
//  Purple
//
//  Created by Jimmy Bosse on 9/20/25.
//

import SwiftUI
import AVFoundation

struct QRCodeScannerView: View {
    let onResult: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermissionAlert = false
    @State private var permissionDenied = false

    var body: some View {
        NavigationView {
            ZStack {
                if permissionDenied {
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            Text("Camera Access Required")
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text("Please enable camera access in Settings to scan QR codes")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        Button("Open Settings") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .foregroundColor(.purple)
                    }
                    .padding()
                } else {
                    QRCodeScannerRepresentable(onResult: onResult, onPermissionDenied: {
                        permissionDenied = true
                    })
                    .ignoresSafeArea()

                    // Overlay with scanning frame
                    VStack {
                        Spacer()

                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.purple, lineWidth: 3)
                            .frame(width: 250, height: 250)
                            .overlay(
                                VStack {
                                    Text("Scan QR Code")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.bottom, 8)

                                    Text("Position the QR code within the frame")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .offset(y: -140)
                            )

                        Spacer()
                    }
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        }
    }
}

struct QRCodeScannerRepresentable: UIViewControllerRepresentable {
    let onResult: (String) -> Void
    let onPermissionDenied: () -> Void

    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let scanner = QRCodeScannerViewController()
        scanner.onResult = onResult
        scanner.onPermissionDenied = onPermissionDenied
        return scanner
    }

    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {
        // No updates needed
    }
}

class QRCodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onResult: ((String) -> Void)?
    var onPermissionDenied: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            failed()
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            failed()
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Request camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        DispatchQueue.global(qos: .userInitiated).async {
                            self.captureSession.startRunning()
                        }
                    } else {
                        self.onPermissionDenied?()
                    }
                }
            }
        case .denied, .restricted:
            onPermissionDenied?()
        @unknown default:
            failed()
        }
    }

    private func failed() {
        let alert = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        captureSession = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            DispatchQueue.main.async {
                self.onResult?(stringValue)
            }
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

#Preview {
    QRCodeScannerView { result in
        print("Scanned: \(result)")
    }
}
