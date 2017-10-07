/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import Test
import AsyncDispatch
@testable import TestUtils
@testable import TarantoolConnector

class IProtoSpaceTests: TestCase {
    var tarantool: TarantoolProcess!
    var space: Space<IProto>!

    override func setUp() {
        do {
            AsyncDispatch().registerGlobal()
            tarantool = try TarantoolProcess(with: """
                box.schema.user.grant('guest', 'read,write,execute', 'universe')
                local test = box.schema.space.create('test')
                test:create_index('primary', {type = 'tree', parts = {1, 'unsigned'}})
                test:replace({1, 'foo'})
                test:replace({2, 'bar'})
                test:replace({3, 'baz'})
                """)
            try tarantool.launch()

            let connection = try IProtoConnection(host: "127.0.0.1", port: tarantool.port)
            let iproto = IProto(connection: connection)
            let schema = try Schema(iproto)

            self.space = schema.spaces["test"]
        } catch {
            fatalError(String(describing: error))
        }
    }

    override func tearDown() {
        let status = tarantool.terminate()
        assertEqual(status, 0)
    }

    func testCount() {
        do {
            let result = try space.count(.all)
            assertEqual(result, 3)
        } catch {
            fail(String(describing: error))
        }
    }

    func testSelect() {
        do {
            let expected: [IProtoTuple] = [
                IProtoTuple(rawValue: [1, "foo"]),
                IProtoTuple(rawValue: [2, "bar"]),
                IProtoTuple(rawValue: [3, "baz"])
            ]
            let result = try space.select(iterator: .all)
            assertEqual([IProtoTuple](result), expected)
        } catch {
            fail(String(describing: error))
        }
    }

    func testGet() {
        do {
            guard let result = try space.get(keys: [3]) else {
                fail()
                return
            }
            assertEqual(result, IProtoTuple(rawValue: [3, "baz"]))
        } catch {
            fail(String(describing: error))
        }
    }

    func testInsert() {
        do {
            try space.insert([4, "quux"])
            guard let result = try space.get(keys: [4]) else {
                fail()
                return
            }
            assertEqual(result, IProtoTuple(rawValue: [4, "quux"]))
        } catch {
            fail(String(describing: error))
        }
    }

    func testReplace() {
        do {
            try space.replace([3, "zab"])
            guard let result = try space.get(keys: [3]) else {
                fail()
                return
            }
            assertEqual(result, IProtoTuple(rawValue: [3, "zab"]))
        } catch {
            fail(String(describing: error))
        }
    }

    func testDelete() {
        do {
            try space.delete(keys: [3])
            assertNil(try space.get(keys: [3]))
        } catch {
            fail(String(describing: error))
        }
    }

    func testUpdate() {
        do {
            try space.update(keys: [3], operations: [["=", 1, "zab"]])
            guard let result = try space.get(keys: [3]) else {
                fail()
                return
            }
            assertEqual(result, IProtoTuple(rawValue: [3, "zab"]))
        } catch {
            fail(String(describing: error))
        }
    }

    func testUpsert() {
        do {
            assertNil(try space.get(keys: [4]))

            try space.upsert([4, "quux", 42], operations: [["+", 2, 8]])
            guard let insertResult = try space.get(keys: [4]) else {
                fail()
                return
            }
            assertEqual(insertResult, IProtoTuple(rawValue: [4, "quux", 42]))

            try space.upsert([4, "quux", 42], operations: [["+", 2, 8]])
            guard let updateResult = try space.get(keys: [4]) else {
                fail()
                return
            }
            assertEqual(updateResult, IProtoTuple(rawValue: [4, "quux", 50]))
        } catch {
            fail(String(describing: error))
        }
    }


    static var allTests = [
        ("testCount", testCount),
        ("testSelect", testSelect),
        ("testGet", testGet),
        ("testInsert", testInsert),
        ("testReplace", testReplace),
        ("testDelete", testDelete),
        ("testUpdate", testUpdate),
        ("testUpsert", testUpsert),
    ]
}
