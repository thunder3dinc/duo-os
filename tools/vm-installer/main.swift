// Duo OS VM installer — first cut (2026-11-19)
//
// Installs a stock macOS 27.3 guest using Apple's Virtualization
// framework (the same framework UTM uses) and saves the result as a
// VM bundle named "Duo OS" that UTM can open.
//
// Built and run as a script step of the Duo OS Xcode build on the
// build Mac. Requires the Virtualization entitlement
// (com.apple.security.virtualization) on the built tool.
//
// Usage:
//   duo-os-vm-installer --ipsw <path-to-restore.ipsw> --out <bundle-dir>
//   duo-os-vm-installer --download-latest --out <bundle-dir>
//
// Status: builds clean (2026-11-19). First run 2026-11-20 crashed in
// VZMacOSRestoreImage.load — fetchLatestSupported returns a remote
// URL and the image was never downloaded; fixed the same day by
// downloading to ~/Library/Caches/duo-os-vm-installer/ first.
// Second run (2026-11-20) failed config validation: "No displays
// are configured" — the graphics device had no display. Fixed the
// same day: the Mac graphics device now carries a 1920x1080
// display, guest memory is clamped to the host's RAM, the sound
// device gets an output stream, and the UTM config.plist is
// written only after a successful install.
// Alignment pass (2026-11-20, at Alan's instruction to match the
// reference exactly): the sound device now carries input + output
// streams, and the entropy and memory-balloon devices from
// Apple's sample configuration were added — the VM configuration
// now matches Apple's reference macOS VM setup item for item.

import Foundation
import Virtualization

let diskSizeGB: UInt64 = 64
let cpuCount = 4
let memorySizeGB: UInt64 = 8

func fail(_ message: String) -> Never {
    FileHandle.standardError.write("error: \(message)\n".data(using: .utf8)!)
    exit(1)
}

// Downloads the restore image to a local file, printing coarse
// progress so the Xcode build log stays readable.
final class RestoreImageDownloader: NSObject, URLSessionDownloadDelegate {
    let destination: URL
    var finished = false
    var error: Error?
    private var lastPrintedPercent = -5.0

    init(destination: URL) { self.destination = destination }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let pct = Double(totalBytesWritten) /
                  Double(totalBytesExpectedToWrite) * 100
        if pct - lastPrintedPercent >= 5 {
            lastPrintedPercent = pct
            print(String(format: "  download %.0f%%", pct))
        }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
        } catch { self.error = error }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        if let error { self.error = error }
        finished = true
    }
}

// MARK: - Arguments

var args = CommandLine.arguments.dropFirst()
var ipswPath: String?
var downloadLatest = false
var outPath: String?

while let a = args.first {
    args = args.dropFirst()
    switch a {
    case "--ipsw":
        guard let v = args.first else { fail("--ipsw needs a path") }
        ipswPath = v; args = args.dropFirst()
    case "--download-latest":
        downloadLatest = true
    case "--out":
        guard let v = args.first else { fail("--out needs a path") }
        outPath = v; args = args.dropFirst()
    default:
        fail("unknown argument: \(a)")
    }
}

guard let bundlePath = outPath else { fail("--out is required") }
guard ipswPath != nil || downloadLatest else {
    fail("pass --ipsw <path> or --download-latest")
}

let fm = FileManager.default
let bundleURL = URL(fileURLWithPath: bundlePath)
let dataDir = bundleURL.appendingPathComponent("Data")
do {
    try fm.createDirectory(at: dataDir, withIntermediateDirectories: true)
} catch { fail("could not create bundle: \(error)") }

let diskURL = dataDir.appendingPathComponent("Disk.img")
let auxURL = dataDir.appendingPathComponent("AuxiliaryStorage")
let hwModelURL = dataDir.appendingPathComponent("HardwareModel")
let machineIDURL = dataDir.appendingPathComponent("MachineIdentifier")

// MARK: - Restore image

var ipswURL: URL?

if let p = ipswPath {
    ipswURL = URL(fileURLWithPath: p)
} else {
    // Apple's feed of the latest macOS restore image for VMs.
    // NOTE: fetchLatestSupported returns a REMOTE https URL — the image
    // must be downloaded to a local file before load(from:) will take
    // it (load validates that the URL is a file URL and throws
    // NSInvalidArgumentException otherwise — crash found 2026-11-20).
    let semaphore = DispatchSemaphore(value: 0)
    var remoteURL: URL?
    VZMacOSRestoreImage.fetchLatestSupported { result in
        switch result {
        case .success(let image):
            remoteURL = image.url
        case .failure(let e):
            fail("could not fetch latest restore image: \(e)")
        }
        semaphore.signal()
    }
    semaphore.wait()
    guard let remote = remoteURL else { fail("no restore image") }

    let cacheDir = fm.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Caches/duo-os-vm-installer")
    do {
        try fm.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    } catch { fail("could not create cache folder: \(error)") }
    let localURL = cacheDir.appendingPathComponent(remote.lastPathComponent)

    if let attrs = try? fm.attributesOfItem(atPath: localURL.path),
       let size = attrs[.size] as? UInt64, size > 1_000_000_000 {
        print("Using cached restore image: \(localURL.lastPathComponent)")
        ipswURL = localURL
    } else {
        print("Downloading restore image: \(remote.lastPathComponent)")
        let downloader = RestoreImageDownloader(destination: localURL)
        let session = URLSession(configuration: .default,
                                 delegate: downloader, delegateQueue: nil)
        let task = session.downloadTask(with: remote)
        task.resume()
        while !downloader.finished {
            RunLoop.current.run(mode: .default,
                                before: Date(timeIntervalSinceNow: 0.5))
        }
        session.invalidateAndCancel()
        if let e = downloader.error {
            fail("restore image download failed: \(e)")
        }
        ipswURL = localURL
    }
}
guard let ipswURL else { fail("no restore image") }
print("Restore image: \(ipswURL.lastPathComponent)")

// MARK: - Platform configuration from the restore image

var platformConfig: VZMacPlatformConfiguration?
let loadSem = DispatchSemaphore(value: 0)
VZMacOSRestoreImage.load(from: ipswURL) { result in
    switch result {
    case .success(let image):
        guard let req = image.mostFeaturefulSupportedConfiguration else {
            fail("this Mac does not support any configuration in the restore image")
        }
        let platform = VZMacPlatformConfiguration()
        platform.hardwareModel = req.hardwareModel
        do {
            platform.auxiliaryStorage = try VZMacAuxiliaryStorage(
                creatingStorageAt: auxURL,
                hardwareModel: req.hardwareModel,
                options: [])
        } catch { fail("auxiliary storage: \(error)") }
        platform.machineIdentifier = VZMacMachineIdentifier()
        do {
            try req.hardwareModel.dataRepresentation.write(to: hwModelURL)
            try platform.machineIdentifier.dataRepresentation.write(to: machineIDURL)
        } catch { fail("saving platform data: \(error)") }
        platformConfig = platform
    case .failure(let e):
        fail("loading restore image: \(e)")
    }
    loadSem.signal()
}
loadSem.wait()
guard let platform = platformConfig else { fail("no platform configuration") }

// MARK: - Disk image

do {
    fm.createFile(atPath: diskURL.path, contents: nil)
    let handle = try FileHandle(forWritingTo: diskURL)
    try handle.truncate(atOffset: diskSizeGB * 1024 * 1024 * 1024)
    try handle.close()
} catch { fail("disk image: \(error)") }

// MARK: - VM configuration

// Guest memory: on small hosts (<= 8 GB) the guest gets 2 GB —
// Alan's explicit pick (2026-11-20 night) after 4 GB and 6 GB
// guests both died at the restore wall (AMRestore error 100);
// a smaller guest leaves the host more RAM for its own restore
// services during the install.
// On larger hosts the 8 GB target with the half-host clamp
// applies. The host size is printed for the build log.
let hostMemoryBytes = ProcessInfo.processInfo.physicalMemory
let guestMemoryBytes: UInt64
if hostMemoryBytes <= 8 * 1024 * 1024 * 1024 {
    guestMemoryBytes = 2 * 1024 * 1024 * 1024
} else {
    guestMemoryBytes = min(memorySizeGB * 1024 * 1024 * 1024,
                           max(4 * 1024 * 1024 * 1024, hostMemoryBytes / 2))
}
print(String(format: "Host RAM: %.0f GB - guest memory: %.0f GB",
             Double(hostMemoryBytes) / 1_073_741_824,
             Double(guestMemoryBytes) / 1_073_741_824))

let config = VZVirtualMachineConfiguration()
config.platform = platform
config.bootLoader = VZMacOSBootLoader()
config.cpuCount = cpuCount
config.memorySize = guestMemoryBytes
do {
    let attachment = try VZDiskImageStorageDeviceAttachment(url: diskURL, readOnly: false)
    config.storageDevices = [VZVirtioBlockDeviceConfiguration(attachment: attachment)]
} catch { fail("storage: \(error)") }
let net = VZVirtioNetworkDeviceConfiguration()
net.attachment = VZNATNetworkDeviceAttachment()
config.networkDevices = [net]
let graphics = VZMacGraphicsDeviceConfiguration()
graphics.displays = [VZMacGraphicsDisplayConfiguration(
    widthInPixels: 1920, heightInPixels: 1080, pixelsPerInch: 200)]
config.graphicsDevices = [graphics]
let sound = VZVirtioSoundDeviceConfiguration()
sound.streams = [VZVirtioSoundDeviceInputStreamConfiguration(),
                 VZVirtioSoundDeviceOutputStreamConfiguration()]
config.audioDevices = [sound]
config.keyboards = [VZUSBKeyboardConfiguration()]
config.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]
config.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
config.memoryBalloonDevices = [VZVirtioTraditionalMemoryBalloonDeviceConfiguration()]
do { try config.validate() } catch { fail("config validation: \(error)") }

// MARK: - UTM config.plist
// Make the bundle openable by UTM. UTM keeps its Apple-Virtualization
// VMs as .utm bundles whose Data folder holds Disk.img,
// AuxiliaryStorage, HardwareModel and MachineIdentifier — the files
// written above — plus this config.plist at the bundle root.
// (--out should therefore name a .utm bundle, e.g. "Duo OS.utm",
// inside the folder UTM keeps its virtual machines in.)
// First cut: if UTM refuses this config, adjust from its parser errors.
let utmConfig: [String: Any] = [
    "Backend": "Apple",
    "ConfigurationVersion": 4,
    "Information": ["Name": "Duo OS", "Icon": ""],
    "System": [
        "Architecture": "arm64",
        "CPUCount": cpuCount,
        "MemorySize": Int(guestMemoryBytes),
        "Boot": ["OperatingSystem": "macOS"],
        "MacPlatform": [
            "AuxiliaryStoragePath": "AuxiliaryStorage",
            "HardwareModelPath": "HardwareModel",
            "MachineIdentifierPath": "MachineIdentifier",
        ],
    ],
    "Drives": [[
        "Identifier": UUID().uuidString,
        "ImageName": "Disk.img",
        "ImageType": "Disk",
        "Interface": "VirtIO",
        "ReadOnly": false,
    ]],
    "Networks": [["Mode": "Shared", "Interface": "VirtIO"]],
    "Displays": [[
        "WidthInPixels": 1920,
        "HeightInPixels": 1080,
        "PixelsPerInch": 200,
        "DynamicResolution": true,
    ]],
]
// The config.plist itself is written only after the install
// succeeds (see the install completion handler), so a failed
// install never leaves a presentable-but-broken VM in UTM.

// MARK: - Install

let vm = VZVirtualMachine(configuration: config)
let installer = VZMacOSInstaller(virtualMachine: vm, restoringFromImageAt: ipswURL)
print("Installing macOS into the Duo OS guest — this takes a while…")
let progress = installer.progress
let observation = progress.observe(\.fractionCompleted, options: [.new]) { p, _ in
    print(String(format: "  %.0f%%", p.fractionCompleted * 100))
}
installer.install { result in
    switch result {
    case .success:
        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: utmConfig, format: .xml, options: 0)
            try data.write(to: bundleURL.appendingPathComponent("config.plist"))
            print("Wrote UTM config.plist")
        } catch { fail("writing config.plist: \(error)") }
        print("Install complete. Guest bundle saved at: \(bundlePath)")
        exit(0)
    case .failure(let error):
        fail("install failed: \(error)")
    }
}
_ = observation
dispatchMain()
