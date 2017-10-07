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
import TarantoolModule
import MessagePack

struct LuaTests {
    static func testEval() throws {
        let null = try Lua.eval("return nil")
        try assertEqualThrows(null, [.nil])

        let answer = try Lua.eval("return 40 + 2")
        try assertEqualThrows(answer, [.int(42)])

        let negative = try Lua.eval("return 7 - 8")
        try assertEqualThrows(negative, [.int(-1)])

        let pi = try Lua.eval("return 3.14")
        try assertEqualThrows(pi, [.double(3.14)])

        let id = try Lua.eval("return box.space._vindex.id")
        try assertEqualThrows(id, [.int(289)])

        let arguments = try Lua.eval("""
            local name, value = ...
            local result = {}
            result[name] = value
            return result
            """, [.string("answer"), .int(42)])
        try assertEqualThrows(arguments, [.map([.string("answer") : .int(42)])])

        let empty = try Lua.eval("local var = 'empty stack'")
        try assertEqualThrows(empty, [])
    }

    static func testPushPop() throws {
        try Lua.withNewStack { L in
            try Lua.push(values: [.int(1), .int(2), .int(3)], to: L)
            let one2Three = try Lua.popValues(from: L)
            try assertEqualThrows(one2Three, [.int(1), .int(2), .int(3)])

            try Lua.push(value: .int(1), to: L)
            try Lua.push(value: .int(2), to: L)
            try Lua.push(value: .int(3), to: L)

            guard let one = try Lua.popFirst(from: L) else {
                throw "value not found"
            }
            try assertEqualThrows(one, .int(1))

            guard let three = try Lua.popLast(from: L) else {
                throw "value not found"
            }
            try assertEqualThrows(three, .int(3))
        }
    }
}

// C API Wrappers

@_silgen_name("LuaTests_testEval")
public func LuaTests_testEval(context: BoxContext) -> BoxResult {
    do {
        try LuaTests.testEval()
    } catch {
        return Box.returnError(code: .procC, message: String(describing: error))
    }
    return 0
}

@_silgen_name("LuaTests_testPushPop")
public func LuaTests_testPushPop(context: BoxContext) -> BoxResult {
    do {
        try LuaTests.testPushPop()
    } catch {
        return Box.returnError(code: .procC, message: String(describing: error))
    }
    return 0
}
