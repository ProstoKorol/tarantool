/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import Platform
import Foundation

struct TarantoolProcessError: Error {
    let message: String
}

class TarantoolProcess {
    let process = Process()
    let port: UInt16
    let scriptBody: String

    var temp: URL = {
        return URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("TarantoolTemp\(arc4random())")
    }()

    var lock: URL {
        return temp.appendingPathComponent("lock")
    }
    
    var isRunning: Bool {
        return process.isRunning
    }

    init(with script: String = "", listen port: UInt16 = 3301) throws {
        self.port = port
        self.scriptBody = script
        
    }

    func launch() throws {
        let config = temp.appendingPathComponent("init.lua")
        let script = "box.cfg{listen=\(port),snap_dir='\(temp.path)',wal_dir='\(temp.path)',vinyl_dir='\(temp.path)',slab_alloc_arena=0.1}\n" +
            "\(scriptBody)\n" +
            "local fiber = require('fiber')\n" +
            "local fio = require('fio')\n" +
            "while fio.stat('\(lock.path)') do\n" +
            "  fiber.sleep(0.1)\n" +
            "end\n" +
            "os.exit(0)"

        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        _ = FileManager.default.createFile(atPath: lock.path, contents: nil)
        try script.write(to: config, atomically: true, encoding: .utf8)

    #if os(macOS)
        process.launchPath = "/usr/local/bin/tarantool"
    #else
        process.launchPath = "/usr/bin/tarantool"
    #endif
        process.arguments = [config.path]

        guard FileManager.default.fileExists(atPath: process.launchPath!) else {
            throw TarantoolProcessError(message: "\(process.launchPath!) doesn't exist")
        }

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.launch()
        usleep(500000)
        guard process.isRunning else {
            let data = outputPipe.fileHandleForReading.availableData
            guard let output = String(data: data, encoding: .utf8) else {
                throw TarantoolProcessError(message: "can't launch tarantool")
            }
            throw TarantoolProcessError(message: output)
        }
    }

    func terminate() -> Int {
        if process.isRunning {
            // not yet implemented
            // process.terminate()
            try? FileManager.default.removeItem(at: lock)
            process.waitUntilExit()
        }
        try? FileManager.default.removeItem(at: temp)
        return Int(process.terminationStatus)
    }
}
