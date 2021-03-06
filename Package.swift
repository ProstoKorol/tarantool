// swift-tools-version:4.0
/*
 * Copyright 2017 Tris Foundation and the project authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License
 *
 * See LICENSE.txt in the project root for license information
 * See CONTRIBUTORS.txt for the list of the project authors
 */

import PackageDescription

let package = Package(
    name: "Tarantool",
    products: [
        .library(name: "TarantoolConnector", targets: ["TarantoolConnector"]),
        .library(name: "TarantoolModule", targets: ["TarantoolModule"]),
        // used by TarantoolModuleTests
        .library(
            name: "TarantoolModuleTest",
            type: .dynamic,
            targets: ["TarantoolModuleTest"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/tris-foundation/platform.git",
            .branch("master")),
        .package(
            url: "https://github.com/tris-foundation/async.git",
            .branch("master")),
        .package(
            url: "https://github.com/tris-foundation/crypto.git",
            .branch("master")),
        .package(
            url: "https://github.com/tris-foundation/network.git",
            .branch("master")),
        .package(
            url: "https://github.com/tris-foundation/messagepack.git",
            .branch("master")),
        .package(
            url: "https://github.com/tris-foundation/test.git",
            .branch("master"))
    ],
    targets: [
        .target(name: "CTarantool"),
        .target(name: "Tarantool", dependencies: ["MessagePack"]),
        .target(
            name: "TarantoolConnector",
            dependencies: ["Tarantool", "Network", "Crypto"]),
        .target(
            name: "TarantoolModule",
            dependencies: ["CTarantool", "Tarantool", "Async"]),
        .target(
            name: "TarantoolModuleTest",
            dependencies: ["TarantoolModule"]),
        .target(
            name: "TestUtils",
            dependencies: ["Platform", "Network"]),
        .testTarget(
            name: "TarantoolModuleTests",
            dependencies: [
                "TarantoolModule", "TarantoolConnector", "Test", "AsyncDispatch"
            ]),
        .testTarget(
            name: "TarantoolConnectorTests",
            dependencies: ["TarantoolConnector", "Test", "AsyncDispatch"]),
        .testTarget(
            name: "TestUtilsTests",
            dependencies: ["TestUtils", "Test", "AsyncDispatch"])
    ]
)
