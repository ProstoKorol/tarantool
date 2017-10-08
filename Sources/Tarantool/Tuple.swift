/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import MessagePack

public protocol TupleProtocol: RandomAccessCollection, CustomStringConvertible {
    var count: Int { get }
    func unpack() -> [MessagePack]
    subscript(index: Int) -> MessagePack? { get }
}

extension TupleProtocol {
    public var description: String {
        return unpack().description
    }
}

public typealias Map = [MessagePack : MessagePack]
