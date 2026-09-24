// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/os;
import ballerina/test;
import ballerina/time;

final boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
final string serviceUrl = isLiveServer
    ? string `https://${os:getEnv("AZURE_STORAGE_ACCOUNT")}.dfs.core.windows.net`
    : "http://localhost:9090";
final string token = isLiveServer ? os:getEnv("AZURE_STORAGE_TOKEN") : "test_token";

// The mock listener is plain HTTP, where an HTTP/2 client must upgrade from HTTP/1.1
// (h2c) and a request carrying a body is not upgraded cleanly. Live traffic is HTTPS.
final Client datalake = check new ({auth: {token}, httpVersion: isLiveServer ? http:HTTP_2_0 : http:HTTP_1_1}, serviceUrl);

// A deleted filesystem name stays reserved for a while, so live runs suffix every
// fixture name. Against the mock the name is used as-is.
isolated function fixture(string name) returns string =>
    isLiveServer ? string `${name}-${time:utcNow()[0]}` : name;

isolated function createFilesystemFixture(string name) returns string|error {
    string filesystem = fixture(name);
    check datalake->createFilesystem(filesystem, 'resource = "filesystem");
    return filesystem;
}

isolated function writeFile(string filesystem, string path, string content) returns error? {
    byte[] data = content.toBytes();
    check datalake->createPath(filesystem, path, 'resource = "file");
    check datalake->updatePath(filesystem, path, data, action = "append", position = 0);
    check datalake->updatePath(filesystem, path, [], action = "flush", position = data.length());
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListFilesystems() returns error? {
    string filesystem = check createFilesystemFixture("list-filesystems");
    FilesystemList response = check datalake->listFilesystems('resource = "account", prefix = filesystem);
    Filesystem[] filesystems = response.filesystems ?: [];
    test:assertEquals(filesystems.length(), 1);
    test:assertEquals(filesystems[0].name, filesystem);
    check datalake->deleteFilesystem(filesystem, 'resource = "filesystem");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testCreateFilesystem() returns error? {
    string filesystem = fixture("create-filesystem");
    check datalake->createFilesystem(filesystem, {xMsProperties: "owner=ZGF0YS10ZWFt"}, 'resource = "filesystem");
    http:Response properties = check datalake->getFilesystemProperties(filesystem, 'resource = "filesystem");
    test:assertEquals(properties.statusCode, 200);
    test:assertEquals(check properties.getHeader("x-ms-properties"), "owner=ZGF0YS10ZWFt");
    check datalake->deleteFilesystem(filesystem, 'resource = "filesystem");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testDeleteFilesystem() returns error? {
    string filesystem = fixture("delete-filesystem");
    check datalake->createFilesystem(filesystem, 'resource = "filesystem");
    check datalake->deleteFilesystem(filesystem, 'resource = "filesystem");
    FilesystemList response = check datalake->listFilesystems('resource = "account", prefix = filesystem);
    test:assertEquals((response.filesystems ?: []).length(), 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetFilesystemProperties() returns error? {
    string filesystem = check createFilesystemFixture("get-filesystem-properties");
    http:Response response = check datalake->getFilesystemProperties(filesystem, 'resource = "filesystem");
    test:assertEquals(response.statusCode, 200);
    test:assertTrue((check response.getHeader("ETag")).length() > 0);
    check datalake->deleteFilesystem(filesystem, 'resource = "filesystem");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testSetFilesystemProperties() returns error? {
    string filesystem = check createFilesystemFixture("set-filesystem-properties");
    check datalake->setFilesystemProperties(filesystem, {xMsProperties: "stage=cmF3"}, 'resource = "filesystem");
    http:Response response = check datalake->getFilesystemProperties(filesystem, 'resource = "filesystem");
    test:assertEquals(check response.getHeader("x-ms-properties"), "stage=cmF3");
    check datalake->deleteFilesystem(filesystem, 'resource = "filesystem");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testListPaths() returns error? {
    string filesystem = check createFilesystemFixture("list-paths");
    check datalake->createPath(filesystem, "logs", 'resource = "directory");
    check writeFile(filesystem, "logs/app.log", "started\n");
    check writeFile(filesystem, "readme.txt", "sample\n");

    PathList topLevel = check datalake->listPaths(filesystem, 'resource = "filesystem", recursive = false);
    test:assertEquals((topLevel.paths ?: []).length(), 2);

    PathList logs = check datalake->listPaths(filesystem, 'resource = "filesystem", recursive = true, directory = "logs");
    Path[] entries = logs.paths ?: [];
    test:assertEquals(entries.length(), 1);
    test:assertEquals(entries[0].name, "logs/app.log");
    test:assertFalse(entries[0].isDirectory);
    check datalake->deleteFilesystem(filesystem, 'resource = "filesystem");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testCreatePath() returns error? {
    string filesystem = check createFilesystemFixture("create-path");
    check datalake->createPath(filesystem, "incoming", 'resource = "directory");
    http:Response response = check datalake->getPathProperties(filesystem, "incoming");
    test:assertEquals(check response.getHeader("x-ms-resource-type"), "directory");

    // Renaming is also a createPath call, with the source in x-ms-rename-source.
    check datalake->createPath(filesystem, "processed", {xMsRenameSource: string `/${filesystem}/incoming`});
    http:Response renamed = check datalake->getPathProperties(filesystem, "processed");
    test:assertEquals(check renamed.getHeader("x-ms-resource-type"), "directory");
    http:Response original = check datalake->getPathProperties(filesystem, "incoming");
    test:assertEquals(original.statusCode, 404, "the rename source should no longer exist");
    check datalake->deleteFilesystem(filesystem, 'resource = "filesystem");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testUpdatePath() returns error? {
    string filesystem = check createFilesystemFixture("update-path");
    check datalake->createPath(filesystem, "events.csv", 'resource = "file");
    byte[] first = "id,type\n".toBytes();
    byte[] second = "1,click\n".toBytes();
    check datalake->updatePath(filesystem, "events.csv", first, action = "append", position = 0);
    check datalake->updatePath(filesystem, "events.csv", second, action = "append", position = first.length());
    check datalake->updatePath(filesystem, "events.csv", [], action = "flush", position = first.length() + second.length());

    byte[] content = check datalake->readFile(filesystem, "events.csv");
    test:assertEquals(check string:fromBytes(content), "id,type\n1,click\n");
    check datalake->deleteFilesystem(filesystem, 'resource = "filesystem");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testReadFile() returns error? {
    string filesystem = check createFilesystemFixture("read-file");
    check writeFile(filesystem, "notes.txt", "hello data lake");

    byte[] whole = check datalake->readFile(filesystem, "notes.txt");
    test:assertEquals(check string:fromBytes(whole), "hello data lake");

    byte[] head = check datalake->readFile(filesystem, "notes.txt", {range: "bytes=0-4"});
    test:assertEquals(check string:fromBytes(head), "hello");
    check datalake->deleteFilesystem(filesystem, 'resource = "filesystem");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testLeasePath() returns error? {
    string filesystem = check createFilesystemFixture("lease-path");
    check writeFile(filesystem, "locked.txt", "exclusive");
    string leaseId = "7c9e6679-7425-40de-944b-e07fc1f90ae7";
    check datalake->leasePath(filesystem, "locked.txt",
        {xMsLeaseAction: "acquire", xMsLeaseDuration: 15, xMsProposedLeaseId: leaseId});
    check datalake->leasePath(filesystem, "locked.txt", {xMsLeaseAction: "renew", xMsLeaseId: leaseId});
    check datalake->leasePath(filesystem, "locked.txt", {xMsLeaseAction: "release", xMsLeaseId: leaseId});
    check datalake->deleteFilesystem(filesystem, 'resource = "filesystem");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testDeletePath() returns error? {
    string filesystem = check createFilesystemFixture("delete-path");
    check datalake->createPath(filesystem, "tmp", 'resource = "directory");
    check writeFile(filesystem, "tmp/scratch.txt", "discard me");
    check datalake->deletePath(filesystem, "tmp", recursive = true);
    PathList remaining = check datalake->listPaths(filesystem, 'resource = "filesystem", recursive = true);
    test:assertEquals((remaining.paths ?: []).length(), 0);
    check datalake->deleteFilesystem(filesystem, 'resource = "filesystem");
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetPathProperties() returns error? {
    string filesystem = check createFilesystemFixture("get-path-properties");
    check writeFile(filesystem, "config.json", "{}");
    http:Response properties = check datalake->getPathProperties(filesystem, "config.json");
    test:assertEquals(check properties.getHeader("x-ms-resource-type"), "file");

    http:Response acl = check datalake->getPathProperties(filesystem, "config.json", action = "getAccessControl");
    test:assertTrue((check acl.getHeader("x-ms-acl")).startsWith("user::"));
    check datalake->deleteFilesystem(filesystem, 'resource = "filesystem");
}

@test:Config {groups: ["mock_tests"]}
isolated function testReadMissingFile() returns error? {
    byte[]|error response = datalake->readFile("analytics", "reports/missing.csv");
    test:assertTrue(response is http:ClientRequestError, "a missing file should surface as a 4XX client error");
}
