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

extension BoxWrapper {
    struct Transaction {
        @inline(__always)
        fileprivate static func begin() throws {
            guard _box_txn_begin() == 0 else {
                throw BoxError()
            }
        }

        @inline(__always)
        fileprivate static func commit() throws {
            guard _box_txn_commit() == 0 else {
                throw BoxError()
            }
        }

        @inline(__always)
        fileprivate static func rollback() throws {
            guard _box_txn_rollback() == 0 else {
                throw BoxError()
            }
        }
    }
}

extension Box {
    public static func transaction<T>(
        _ closure: () throws -> T
    ) throws -> T {
        try BoxWrapper.Transaction.begin()

        do {
            let result = try closure()
            try BoxWrapper.Transaction.commit()
            return result
        } catch {
            try BoxWrapper.Transaction.rollback()
            throw error
        }
    }
}
