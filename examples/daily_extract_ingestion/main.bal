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

// Lands a local data extract in Azure Data Lake Storage. The example creates the target
// filesystem when it does not exist yet, creates a directory for the extract date, uploads
// the file in chunks (append, then flush), lists the directory, and reads the file back to
// confirm that the stored content matches the local file.

import ballerina/http;
import ballerina/io;
import ballerinax/azure.datalake;

configurable string storageAccount = ?;
configurable string token = ?;
configurable string filesystem = ?;
configurable string extractDate = ?;
configurable string localFilePath = ?;
configurable int chunkSize = 4194304;

public function main() returns error? {
    datalake:Client datalake = check new ({auth: {token}}, string `https://${storageAccount}.dfs.core.windows.net`);

    // Step 1: Create the filesystem if it does not exist yet.
    // A HEAD request carries no error body, so a missing filesystem is reported by status code.
    http:Response properties = check datalake->getFilesystemProperties(filesystem, 'resource = "filesystem");
    if properties.statusCode == 404 {
        check datalake->createFilesystem(filesystem, 'resource = "filesystem");
        io:println(string `Created filesystem '${filesystem}'`);
    } else if properties.statusCode != 200 {
        return error(string `Could not read filesystem '${filesystem}': HTTP ${properties.statusCode}`);
    }

    // Step 2: Create a directory for this extract date.
    string directory = string `extracts/${extractDate}`;
    check datalake->createPath(filesystem, directory, 'resource = "directory");

    // Step 3: Upload the file. Data is appended in chunks and becomes readable only once it is flushed.
    byte[] content = check io:fileReadBytes(localFilePath);
    string filePath = string `${directory}/${fileNameOf(localFilePath)}`;
    check datalake->createPath(filesystem, filePath, 'resource = "file");
    int position = 0;
    while position < content.length() {
        int end = int:min(position + chunkSize, content.length());
        check datalake->updatePath(filesystem, filePath, content.slice(position, end), action = "append", position = position);
        position = end;
    }
    check datalake->updatePath(filesystem, filePath, [], action = "flush", position = position);
    io:println(string `Uploaded ${content.length()} bytes to ${filesystem}/${filePath}`);

    // Step 4: List what the directory now holds.
    datalake:PathList listing = check datalake->listPaths(filesystem, 'resource = "filesystem",
        recursive = false, directory = directory);
    foreach datalake:Path entry in listing.paths ?: [] {
        io:println(string `  ${entry.name ?: "<unnamed>"} (${entry.contentLength ?: 0} bytes)`);
    }

    // Step 5: Read the file back and compare it with the local copy.
    byte[] stored = check datalake->readFile(filesystem, filePath);
    if stored != content {
        return error(string `Stored content of ${filePath} does not match ${localFilePath}`);
    }
    io:println("Verified: the stored file matches the local extract");
}

function fileNameOf(string path) returns string {
    int? separator = path.lastIndexOf("/");
    return separator is int ? path.substring(separator + 1) : path;
}
