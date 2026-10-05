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
// the file in chunks (append, then flush) to a temporary path, reads it back range by range
// to confirm that the stored content matches the local file, renames it into place, and
// lists the directory.

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
    if chunkSize <= 0 {
        return error(string `chunkSize must be greater than zero, got ${chunkSize}`);
    }
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

    // Step 2: Create a directory for this extract date. Missing parent directories are created with it.
    string directory = string `extracts/${extractDate}`;
    check datalake->createPath(filesystem, directory, 'resource = "directory");

    // Step 3: Upload the file to a temporary path, so a rerun leaves the existing extract in place
    // until the new one is verified. Data is appended in chunks and becomes readable only once it is flushed.
    string filePath = string `${directory}/${fileNameOf(localFilePath)}`;
    string tempPath = string `${filePath}.uploading`;
    check datalake->createPath(filesystem, tempPath, 'resource = "file");
    int position = 0;
    stream<io:Block, io:Error?> upload = check io:fileReadBlocksAsStream(localFilePath, chunkSize);
    check from io:Block block in upload
        do {
            check datalake->updatePath(filesystem, tempPath, block, action = "append", position = position);
            position += block.length();
        };
    check datalake->updatePath(filesystem, tempPath, [], action = "flush", position = position);
    io:println(string `Uploaded ${position} bytes to ${filesystem}/${tempPath}`);

    // Step 4: Verify the upload against the local file, one byte range per block.
    http:Response stat = check datalake->getPathProperties(filesystem, tempPath);
    if stat.statusCode != 200 {
        return error(string `Could not read ${tempPath}: HTTP ${stat.statusCode}`);
    }
    int storedLength = check int:fromString(check stat.getHeader("Content-Length"));
    if storedLength != position {
        return error(string `Stored length of ${tempPath} is ${storedLength} bytes, expected ${position}`);
    }
    int offset = 0;
    stream<io:Block, io:Error?> verify = check io:fileReadBlocksAsStream(localFilePath, chunkSize);
    check from io:Block block in verify
        do {
            string range = string `bytes=${offset}-${offset + block.length() - 1}`;
            byte[] stored = check datalake->readFile(filesystem, tempPath, {range});
            if stored != block {
                return error(string `Stored content of ${tempPath} does not match ${localFilePath} in ${range}`);
            }
            offset += block.length();
        };
    io:println("Verified: the stored file matches the local extract");

    // Step 5: Rename the verified upload into place, replacing any earlier extract of the same name.
    check datalake->createPath(filesystem, filePath, {xMsRenameSource: string `/${filesystem}/${tempPath}`});
    io:println(string `Stored ${filesystem}/${filePath}`);

    // Step 6: List what the directory now holds.
    datalake:PathList listing = check datalake->listPaths(filesystem, 'resource = "filesystem",
        recursive = false, directory = directory);
    foreach datalake:Path entry in listing.paths ?: [] {
        io:println(string `  ${entry.name ?: "<unnamed>"} (${entry.contentLength ?: 0} bytes)`);
    }
}

function fileNameOf(string path) returns string {
    int? separator = path.lastIndexOf("/");
    return separator is int ? path.substring(separator + 1) : path;
}
