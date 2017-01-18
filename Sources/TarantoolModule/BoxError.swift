/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import CTarantool

public struct BoxError: Error {
    public let code: BoxErrorCode
    public let message: String

    init(){
        guard let errorPointer = box_error_last() else {
            self.code = .unknown
            self.message = "success"
            return
        }
        let errorCode = box_error_code(errorPointer)
        let errorMessage = box_error_message(errorPointer)

        self.code = BoxErrorCode(rawValue: errorCode) ?? .unknown
        self.message = errorMessage != nil ? String(cString: errorMessage!) : "nil"
    }

    public static func returnError(code: BoxErrorCode, message: String, file: String = #file, line: Int = #line) -> BoxResult {
        return box_error_set_wrapper(file, UInt32(line), code.rawValue, message)
    }
}

extension BoxError: CustomStringConvertible {
    public var description: String {
        return "code: \(code) message: \(message)"
    }
}
