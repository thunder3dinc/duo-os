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
// NOT yet compiled or run — see README.md in this folder.

import Foundation
import Virtualization

let diskSizeGB: UInt64 = 64
let cpuCount = 4
let memorySizeGB: UInt64 = 8

func fail(_ message: String) -> Never {
    FileHandle.standardError.write("error: \(message)\n".data(using: .utf8)!)
    exit(1)
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

let semaphore = DispatchSemaphore(value: 0)
var restoreImageURL: URL?

if let p = ipswPath {
    restoreImageURL = URL(fileURLWithPath: p)
    semaphore.signal()
} else {
    // Apple's feed of the latest macOS restore image for VMs.
    VZMacOSRestoreImage.fetchLatestSupported { result in
        switch result {
        case .success(let image):
            restoreImageURL = image.url
        case .failure(let e):
            fail("could not fetch latest restore image: \(e)")
        }
        semaphore.signal()
    }
}
semaphore.wait()
guard let ipswURL = restoreImageURL else { fail("no restore image") }
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

let config = VZVirtualMachineConfiguration()
config.platform = platform
config.bootLoader = VZMacOSBootLoader()
config.cpuCount = cpuCount
config.memorySize = memorySizeGB * 1024 * 1024 * 1024
do {
    let attachment = try VZDiskImageStorageDeviceAttachment(url: diskURL, readOnly: false)
    config.storageDevices = [VZVirtioBlockDeviceConfiguration(attachment: attachment)]
} catch { fail("storage: \(error)") }
let net = VZVirtioNetworkDeviceConfiguration()
net.attachment = VZNATNetworkDeviceAttachment()
config.networkDevices = [net]
config.graphicsDevices = [VZMacGraphicsDeviceConfiguration()]
config.audioDevices = [VZVirtioSoundDeviceConfiguration()]
config.keyboards = [VZUSBKeyboardConfiguration()]
config.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]
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
        "MemorySize": Int(memorySizeGB * 1024 * 1024 * 1024),
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
do {
    let data = try PropertyListSerialization.data(
        fromPropertyList: utmConfig, format: .xml, options: 0)
    try data.write(to: bundleURL.appendingPathComponent("config.plist"))
    print("Wrote UTM config.plist")
} catch { fail("writing config.plist: \(error)") }

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
        print("Install complete. Guest bundle saved at: \(bundlePath)")
        exit(0)
    case .failure(let error):
        fail("install failed: \(error)")
    }
}
_ = observation
dispatchMain()
