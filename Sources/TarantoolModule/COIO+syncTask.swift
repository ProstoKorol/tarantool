/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import Async
import Platform
import Dispatch

import struct Foundation.Date
#if os(Linux)
import class Foundation.Thread
#endif

extension COIO {
    public static func syncTask<T>(
        onQueue queue: DispatchQueue = DispatchQueue.global(),
        qos: DispatchQoS = .background,
        deadline: Date = Date.distantFuture,
        task: @escaping () throws -> T
    ) throws -> T {
        var result: T? = nil
        var error: Error? = nil

        let fd = try pipe()

        try wait(for: fd.1, event: .write, deadline: deadline)

        // TODO: allow fibers inside the task
        // cord_create, cord_destroy, ev_run, ev_break
        let closure = {
            // fiber {
            // ...
            //}
            // TarantoolLoop.current.run()
            do {
                result = try task()
            } catch let taskError {
                error = taskError
            }

            var done: UInt8 = 1
            write(fd.1.rawValue, &done, 1)
        }

        // FIXME: Doesn't work on Linux anymore
        #if os(macOS)
        let workItem = DispatchWorkItem(qos: qos, block: closure)
        queue.async(execute: workItem)
        #else
        Thread(block: closure).start()
        #endif

        try wait(for: fd.0, event: .read, deadline: deadline)

        close(fd.0.rawValue)
        close(fd.1.rawValue)

        if let result = result {
            return result
        } else if let error = error {
            throw error
        }

        throw AsyncError.taskCanceled
    }

    private static func pipe() throws -> (Descriptor, Descriptor) {
        var fd: (Int32, Int32) = (0, 0)
        let pointer = UnsafeMutableRawPointer(&fd)
            .assumingMemoryBound(to: Int32.self)
        guard Platform.pipe(pointer) != -1 else {
            throw SystemError()
        }
        return (Descriptor(rawValue: fd.0)!, Descriptor(rawValue: fd.1)!)
    }
}
