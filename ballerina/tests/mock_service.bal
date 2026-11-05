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

listener http:Listener ep0 = new (9090);

service / on ep0 {
    # Delete Filesystem
    #
    # + filesystem - The filesystem identifier.  The value must start and end with a letter or number and must contain only letters, numbers, and the dash (-) character.  Consecutive dashes are not permitted.  All letters must be lowercase.  The value must have between 3 and 63 characters
    # + 'resource - The value must be "filesystem" for all filesystem operations
    # + xMsClientRequestId - A UUID recorded in the analytics logs for troubleshooting and correlation
    # + timeout - An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails
    # + xMsDate - Specifies the Coordinated Universal Time (UTC) for the request.  This is required when using shared key authorization
    # + xMsVersion - Specifies the version of the REST protocol used for processing the request. Required for every authorized request, including those that use a Microsoft Entra ID bearer token. Defaults to 2019-10-31
    # + ifModifiedSince - Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time
    # + ifUnmodifiedSince - Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time
    # + return - `http:Accepted` on success, or a `DataLakeStorageErrorDefault` describing the storage error
    resource function delete [string filesystem]("filesystem" 'resource, @http:Header {name: "x-ms-client-request-id"} string? xMsClientRequestId, int:Signed32? timeout, @http:Header {name: "x-ms-date"} string? xMsDate, @http:Header {name: "If-Modified-Since"} string? ifModifiedSince, @http:Header {name: "If-Unmodified-Since"} string? ifUnmodifiedSince, @http:Header {name: "x-ms-version"} string? xMsVersion = "2019-10-31") returns http:Accepted|DataLakeStorageErrorDefault {
        lock {
            if !store.filesystems.hasKey(filesystem) {
                return storageError(404, "FilesystemNotFound", "The specified filesystem does not exist.");
            }
            _ = store.filesystems.remove(filesystem);
        }
        removePaths(filesystem);
        return <http:Accepted>{headers: {"x-ms-request-id": MOCK_REQUEST_ID}};
    }

    # Delete File | Delete Directory
    #
    # + filesystem - The filesystem identifier
    # + path - The file or directory path
    # + xMsClientRequestId - A UUID recorded in the analytics logs for troubleshooting and correlation
    # + timeout - An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails
    # + xMsDate - Specifies the Coordinated Universal Time (UTC) for the request.  This is required when using shared key authorization
    # + xMsVersion - Specifies the version of the REST protocol used for processing the request. Required for every authorized request, including those that use a Microsoft Entra ID bearer token. Defaults to 2019-10-31
    # + recursive - Required and valid only when the resource is a directory.  If "true", all paths beneath the directory will be deleted. If "false" and the directory is non-empty, an error occurs
    # + continuation - Optional.  When deleting a directory, the number of paths that are deleted with each invocation is limited.  If the number of paths to be deleted exceeds this limit, a continuation token is returned in this response header.  When a continuation token is returned in the response, it must be specified in a subsequent invocation of the delete operation to continue deleting the directory
    # + xMsLeaseId - The lease ID must be specified if there is an active lease
    # + ifMatch - Optional.  An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes
    # + ifNoneMatch - Optional.  An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes
    # + ifModifiedSince - Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time
    # + ifUnmodifiedSince - Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time
    # + return - `http:Ok` on success, or a `DataLakeStorageErrorDefault` describing the storage error
    resource function delete [string filesystem]/[string path](@http:Header {name: "x-ms-client-request-id"} string? xMsClientRequestId, int:Signed32? timeout, @http:Header {name: "x-ms-date"} string? xMsDate, boolean? recursive, string? continuation, @http:Header {name: "x-ms-lease-id"} string? xMsLeaseId, @http:Header {name: "If-Match"} string? ifMatch, @http:Header {name: "If-None-Match"} string? ifNoneMatch, @http:Header {name: "If-Modified-Since"} string? ifModifiedSince, @http:Header {name: "If-Unmodified-Since"} string? ifUnmodifiedSince, @http:Header {name: "x-ms-version"} string? xMsVersion = "2019-10-31") returns http:Ok|DataLakeStorageErrorDefault {
        string key = pathKey(filesystem, path);
        lock {
            Path? entry = store.paths[key];
            if entry is () {
                return storageError(404, "PathNotFound", "The specified path does not exist.");
            }
            if entry.isDirectory && recursive != true && hasChildren(store.paths, key) {
                return storageError(409, "DirectoryNotEmpty", "The recursive query parameter value must be true to delete a non-empty directory.");
            }
        }
        removePaths(key);
        return <http:Ok>{headers: {"x-ms-request-id": MOCK_REQUEST_ID}};
    }

    # List Filesystems
    #
    # + 'resource - The value must be "account" for all account operations
    # + prefix - Filters results to filesystems within the specified prefix
    # + continuation - The number of filesystems returned with each invocation is limited. If the number of filesystems to be returned exceeds this limit, a continuation token is returned in the response header x-ms-continuation. When a continuation token is  returned in the response, it must be specified in a subsequent invocation of the list operation to continue listing the filesystems
    # + maxResults - An optional value that specifies the maximum number of items to return. If omitted or greater than 5,000, the response will include up to 5,000 items
    # + xMsClientRequestId - A UUID recorded in the analytics logs for troubleshooting and correlation
    # + timeout - An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails
    # + xMsDate - Specifies the Coordinated Universal Time (UTC) for the request.  This is required when using shared key authorization
    # + xMsVersion - Specifies the version of the REST protocol used for processing the request. Required for every authorized request, including those that use a Microsoft Entra ID bearer token. Defaults to 2019-10-31
    # + return - `FilesystemList` on success, or a `DataLakeStorageErrorDefault` describing the storage error
    resource function get .("account" 'resource, string? prefix, string? continuation, int:Signed32? maxResults, @http:Header {name: "x-ms-client-request-id"} string? xMsClientRequestId, int:Signed32? timeout, @http:Header {name: "x-ms-date"} string? xMsDate, @http:Header {name: "x-ms-version"} string? xMsVersion = "2019-10-31") returns FilesystemList|DataLakeStorageErrorDefault {
        Filesystem[] filesystems;
        lock {
            Filesystem[] found = from Filesystem fs in store.filesystems
                where prefix is () || (fs.name ?: "").startsWith(prefix)
                select fs;
            filesystems = found.cloneReadOnly();
        }
        if maxResults is int && filesystems.length() > maxResults {
            filesystems = filesystems.slice(0, maxResults);
        }
        return {filesystems};
    }

    # List Paths
    #
    # + filesystem - The filesystem identifier.  The value must start and end with a letter or number and must contain only letters, numbers, and the dash (-) character.  Consecutive dashes are not permitted.  All letters must be lowercase.  The value must have between 3 and 63 characters
    # + 'resource - The value must be "filesystem" for all filesystem operations
    # + xMsClientRequestId - A UUID recorded in the analytics logs for troubleshooting and correlation
    # + timeout - An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails
    # + xMsDate - Specifies the Coordinated Universal Time (UTC) for the request.  This is required when using shared key authorization
    # + xMsVersion - Specifies the version of the REST protocol used for processing the request. Required for every authorized request, including those that use a Microsoft Entra ID bearer token. Defaults to 2019-10-31
    # + directory - Filters results to paths within the specified directory. An error occurs if the directory does not exist
    # + recursive - If "true", all paths are listed; otherwise, only paths at the root of the filesystem are listed.  If "directory" is specified, the list will only include paths that share the same root
    # + continuation - The number of paths returned with each invocation is limited. If the number of paths to be returned exceeds this limit, a continuation token is returned in the response header x-ms-continuation. When a continuation token is  returned in the response, it must be specified in a subsequent invocation of the list operation to continue listing the paths
    # + maxResults - An optional value that specifies the maximum number of items to return. If omitted or greater than 5,000, the response will include up to 5,000 items
    # + upn - Optional. Valid only when Hierarchical Namespace is enabled for the account. If "true", the user identity values returned in the owner and group fields of each list entry will be transformed from Azure Active Directory Object IDs to User Principal Names.  If "false", the values will be returned as Azure Active Directory Object IDs. The default value is false. Note that group and application Object IDs are not translated because they do not have unique friendly names
    # + return - `PathList` on success, or a `DataLakeStorageErrorDefault` describing the storage error
    resource function get [string filesystem]("filesystem" 'resource, @http:Header {name: "x-ms-client-request-id"} string? xMsClientRequestId, int:Signed32? timeout, @http:Header {name: "x-ms-date"} string? xMsDate, string? directory, boolean recursive, string? continuation, int:Signed32? maxResults, boolean? upn, @http:Header {name: "x-ms-version"} string? xMsVersion = "2019-10-31") returns PathList|DataLakeStorageErrorDefault {
        if !filesystemExists(filesystem) {
            return storageError(404, "FilesystemNotFound", "The specified filesystem does not exist.");
        }
        string base = directory is string ? pathKey(filesystem, directory) : filesystem;
        if directory is string && !pathExists(base) {
            return storageError(404, "PathNotFound", "The specified path does not exist.");
        }
        string prefixKey = base + "/";
        Path[] paths;
        lock {
            Path[] found = from [string, Path] [key, entry] in store.paths.entries()
                where key.startsWith(prefixKey) && (recursive || key.substring(prefixKey.length()).indexOf("/") is ())
                select entry;
            paths = found.cloneReadOnly();
        }
        if maxResults is int && paths.length() > maxResults {
            paths = paths.slice(0, maxResults);
        }
        return {paths};
    }

    # Read File
    #
    # + filesystem - The filesystem identifier
    # + path - The file or directory path
    # + xMsClientRequestId - A UUID recorded in the analytics logs for troubleshooting and correlation
    # + timeout - An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails
    # + xMsDate - Specifies the Coordinated Universal Time (UTC) for the request.  This is required when using shared key authorization
    # + xMsVersion - Specifies the version of the REST protocol used for processing the request. Required for every authorized request, including those that use a Microsoft Entra ID bearer token. Defaults to 2019-10-31
    # + range - The HTTP Range request header specifies one or more byte ranges of the resource to be retrieved
    # + xMsLeaseId - Optional. If this header is specified, the operation will be performed only if both of the following conditions are met: i) the path's lease is currently active and ii) the lease ID specified in the request matches that of the path
    # + xMsRangeGetContentMd5 - Optional. When this header is set to "true" and specified together with the Range header, the service returns the MD5 hash for the range, as long as the range is less than or equal to 4MB in size. If this header is specified without the Range header, the service returns status code 400 (Bad Request). If this header is set to true when the range exceeds 4 MB in size, the service returns status code 400 (Bad Request)
    # + ifMatch - Optional.  An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes
    # + ifNoneMatch - Optional.  An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes
    # + ifModifiedSince - Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time
    # + ifUnmodifiedSince - Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time
    # + return - `byte[]` or `ByteArrayPartialContent` on success, or a `DataLakeStorageErrorDefault` describing the storage error
    resource function get [string filesystem]/[string path](@http:Header {name: "x-ms-client-request-id"} string? xMsClientRequestId, int:Signed32? timeout, @http:Header {name: "x-ms-date"} string? xMsDate, @http:Header {name: "Range"} string? range, @http:Header {name: "x-ms-lease-id"} string? xMsLeaseId, @http:Header {name: "x-ms-range-get-content-md5"} boolean? xMsRangeGetContentMd5, @http:Header {name: "If-Match"} string? ifMatch, @http:Header {name: "If-None-Match"} string? ifNoneMatch, @http:Header {name: "If-Modified-Since"} string? ifModifiedSince, @http:Header {name: "If-Unmodified-Since"} string? ifUnmodifiedSince, @http:Header {name: "x-ms-version"} string? xMsVersion = "2019-10-31") returns byte[]|ByteArrayPartialContent|DataLakeStorageErrorDefault {
        string key = pathKey(filesystem, path);
        byte[] committed;
        lock {
            Path? entry = store.paths[key];
            if entry is () {
                return storageError(404, "PathNotFound", "The specified path does not exist.");
            }
            if entry.isDirectory {
                return storageError(400, "InvalidInput", "The specified path is a directory.");
            }
            byte[] content = store.contents[key] ?: [];
            int length = int:min(entry.contentLength ?: content.length(), content.length());
            committed = content.slice(0, length).cloneReadOnly();
        }
        if range is string {
            int[]|error bounds = parseRange(range, committed.length());
            if bounds is error {
                return storageError(400, "InvalidRange", "The range specified is invalid for the current size of the resource.");
            }
            return <ByteArrayPartialContent>{
                body: committed.slice(bounds[0], bounds[1] + 1),
                headers: {"Content-Range": string `bytes ${bounds[0]}-${bounds[1]}/${committed.length()}`, "ETag": MOCK_ETAG}
            };
        }
        return committed;
    }

    # Get Filesystem Properties.
    #
    # + filesystem - The filesystem identifier.  The value must start and end with a letter or number and must contain only letters, numbers, and the dash (-) character.  Consecutive dashes are not permitted.  All letters must be lowercase.  The value must have between 3 and 63 characters
    # + 'resource - The value must be "filesystem" for all filesystem operations
    # + xMsClientRequestId - A UUID recorded in the analytics logs for troubleshooting and correlation
    # + timeout - An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails
    # + xMsDate - Specifies the Coordinated Universal Time (UTC) for the request.  This is required when using shared key authorization
    # + xMsVersion - Specifies the version of the REST protocol used for processing the request. Required for every authorized request, including those that use a Microsoft Entra ID bearer token. Defaults to 2019-10-31
    # + return - `http:Ok` on success, or a `DataLakeStorageErrorDefault` describing the storage error
    resource function head [string filesystem]("filesystem" 'resource, @http:Header {name: "x-ms-client-request-id"} string? xMsClientRequestId, int:Signed32? timeout, @http:Header {name: "x-ms-date"} string? xMsDate, @http:Header {name: "x-ms-version"} string? xMsVersion = "2019-10-31") returns http:Ok|DataLakeStorageErrorDefault {
        if !filesystemExists(filesystem) {
            return storageError(404, "FilesystemNotFound", "The specified filesystem does not exist.");
        }
        string properties;
        lock {
            properties = store.properties[filesystem] ?: "";
        }
        return <http:Ok>{
            headers: {
                "ETag": MOCK_ETAG,
                "Last-Modified": MOCK_DATE,
                "x-ms-properties": properties,
                "x-ms-namespace-enabled": "true",
                "x-ms-request-id": MOCK_REQUEST_ID
            }
        };
    }

    # Get Properties | Get Status | Get Access Control List | Check Access
    #
    # + filesystem - The filesystem identifier
    # + path - The file or directory path
    # + xMsClientRequestId - A UUID recorded in the analytics logs for troubleshooting and correlation
    # + timeout - An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails
    # + xMsDate - Specifies the Coordinated Universal Time (UTC) for the request.  This is required when using shared key authorization
    # + xMsVersion - Specifies the version of the REST protocol used for processing the request. Required for every authorized request, including those that use a Microsoft Entra ID bearer token. Defaults to 2019-10-31
    # + action - Optional. If the value is "getStatus" only the system defined properties for the path are returned. If the value is "getAccessControl" the access control list is returned in the response headers (Hierarchical Namespace must be enabled for the account), otherwise the properties are returned
    # + upn - Optional. Valid only when Hierarchical Namespace is enabled for the account. If "true", the user identity values returned in the x-ms-owner, x-ms-group, and x-ms-acl response headers will be transformed from Azure Active Directory Object IDs to User Principal Names.  If "false", the values will be returned as Azure Active Directory Object IDs. The default value is false. Note that group and application Object IDs are not translated because they do not have unique friendly names
    # + fsAction - Required only for check access action. Valid only when Hierarchical Namespace is enabled for the account. File system operation read/write/execute in string form, matching regex pattern '[rwx-]{3}'
    # + xMsLeaseId - Optional. If this header is specified, the operation will be performed only if both of the following conditions are met: i) the path's lease is currently active and ii) the lease ID specified in the request matches that of the path
    # + ifMatch - Optional.  An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes
    # + ifNoneMatch - Optional.  An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes
    # + ifModifiedSince - Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time
    # + ifUnmodifiedSince - Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time
    # + return - `http:Ok` on success, or a `DataLakeStorageErrorDefault` describing the storage error
    resource function head [string filesystem]/[string path](@http:Header {name: "x-ms-client-request-id"} string? xMsClientRequestId, int:Signed32? timeout, @http:Header {name: "x-ms-date"} string? xMsDate, "getAccessControl"|"getStatus"|"checkAccess"? action, boolean? upn, string? fsAction, @http:Header {name: "x-ms-lease-id"} string? xMsLeaseId, @http:Header {name: "If-Match"} string? ifMatch, @http:Header {name: "If-None-Match"} string? ifNoneMatch, @http:Header {name: "If-Modified-Since"} string? ifModifiedSince, @http:Header {name: "If-Unmodified-Since"} string? ifUnmodifiedSince, @http:Header {name: "x-ms-version"} string? xMsVersion = "2019-10-31") returns http:Ok|DataLakeStorageErrorDefault {
        string key = pathKey(filesystem, path);
        Path entry;
        lock {
            Path? found = store.paths[key];
            if found is () {
                return storageError(404, "PathNotFound", "The specified path does not exist.");
            }
            entry = found.cloneReadOnly();
        }
        map<string> responseHeaders = {
            "ETag": entry.eTag ?: MOCK_ETAG,
            "Last-Modified": entry.lastModified ?: MOCK_DATE,
            "x-ms-resource-type": entry.isDirectory ? "directory" : "file",
            "x-ms-owner": entry.owner ?: "$superuser",
            "x-ms-group": entry.group ?: "$superuser",
            "x-ms-permissions": entry.permissions ?: "rw-r-----",
            "x-ms-request-id": MOCK_REQUEST_ID
        };
        if action == "getAccessControl" {
            responseHeaders["x-ms-acl"] = "user::rw-,group::r--,other::---";
        }
        return <http:Ok>{headers: responseHeaders};
    }

    # Set Filesystem Properties
    #
    # + filesystem - The filesystem identifier.  The value must start and end with a letter or number and must contain only letters, numbers, and the dash (-) character.  Consecutive dashes are not permitted.  All letters must be lowercase.  The value must have between 3 and 63 characters
    # + 'resource - The value must be "filesystem" for all filesystem operations
    # + xMsClientRequestId - A UUID recorded in the analytics logs for troubleshooting and correlation
    # + timeout - An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails
    # + xMsDate - Specifies the Coordinated Universal Time (UTC) for the request.  This is required when using shared key authorization
    # + xMsVersion - Specifies the version of the REST protocol used for processing the request. Required for every authorized request, including those that use a Microsoft Entra ID bearer token. Defaults to 2019-10-31
    # + xMsProperties - Optional. User-defined properties to be stored with the filesystem, in the format of a comma-separated list of name and value pairs "n1=v1, n2=v2, ...", where each value is a base64 encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set.  If the filesystem exists, any properties not included in the list will be removed.  All properties are removed if the header is omitted.  To merge new and existing properties, first get all existing properties and the current E-Tag, then make a conditional request with the E-Tag and include values for all properties
    # + ifModifiedSince - Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time
    # + ifUnmodifiedSince - Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time
    # + return - `http:Ok` on success, or a `DataLakeStorageErrorDefault` describing the storage error
    resource function patch [string filesystem]("filesystem" 'resource, @http:Header {name: "x-ms-client-request-id"} string? xMsClientRequestId, int:Signed32? timeout, @http:Header {name: "x-ms-date"} string? xMsDate, @http:Header {name: "x-ms-properties"} string? xMsProperties, @http:Header {name: "If-Modified-Since"} string? ifModifiedSince, @http:Header {name: "If-Unmodified-Since"} string? ifUnmodifiedSince, @http:Header {name: "x-ms-version"} string? xMsVersion = "2019-10-31") returns http:Ok|DataLakeStorageErrorDefault {
        if !filesystemExists(filesystem) {
            return storageError(404, "FilesystemNotFound", "The specified filesystem does not exist.");
        }
        if xMsProperties is string {
            lock {
                store.properties[filesystem] = xMsProperties;
            }
        }
        return <http:Ok>{headers: {"ETag": MOCK_ETAG, "Last-Modified": MOCK_DATE}};
    }

    # Append Data | Flush Data | Set Properties | Set Access Control
    #
    # + filesystem - The filesystem identifier
    # + path - The file or directory path
    # + xMsClientRequestId - A UUID recorded in the analytics logs for troubleshooting and correlation
    # + timeout - An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails
    # + xMsDate - Specifies the Coordinated Universal Time (UTC) for the request.  This is required when using shared key authorization
    # + xMsVersion - Specifies the version of the REST protocol used for processing the request. Required for every authorized request, including those that use a Microsoft Entra ID bearer token. Defaults to 2019-10-31
    # + action - The action must be "append" to upload data to be appended to a file, "flush" to flush previously uploaded data to a file, "setProperties" to set the properties of a file or directory, or "setAccessControl" to set the owner, group, permissions, or access control list for a file or directory.  Note that Hierarchical Namespace must be enabled for the account in order to use access control.  Also note that the Access Control List (ACL) includes permissions for the owner, owning group, and others, so the x-ms-permissions and x-ms-acl request headers are mutually exclusive
    # + position - This parameter allows the caller to upload data in parallel and control the order in which it is appended to the file.  It is required when uploading data to be appended to the file and when flushing previously uploaded data to the file.  The value must be the position where the data is to be appended.  Uploaded data is not immediately flushed, or written, to the file.  To flush, the previously uploaded data must be contiguous, the position parameter must be specified and equal to the length of the file after all data has been written, and there must not be a request entity body included with the request
    # + retainUncommittedData - Valid only for flush operations.  If "true", uncommitted data is retained after the flush operation completes; otherwise, the uncommitted data is deleted after the flush operation.  The default is false.  Data at offsets less than the specified position are written to the file when flush succeeds, but this optional parameter allows data after the flush position to be retained for a future flush operation
    # + close - Azure Storage Events allow applications to receive notifications when files change. When Azure Storage Events are enabled, a file changed event is raised. This event has a property indicating whether this is the final change to distinguish the difference between an intermediate flush to a file stream and the final close of a file stream. The close query parameter is valid only when the action is "flush" and change notifications are enabled. If the value of close is "true" and the flush operation completes successfully, the service raises a file change notification with a property indicating that this is the final update (the file stream has been closed). If "false" a change notification is raised indicating the file has changed. The default is false. This query parameter is set to true by the Hadoop ABFS driver to indicate that the file stream has been closed."
    # + contentLength - Required for "Append Data" and "Flush Data".  Must be 0 for "Flush Data".  Must be the length of the request content in bytes for "Append Data"
    # + contentMD5 - Optional. An MD5 hash of the request content. This header is valid on "Append" and "Flush" operations. This hash is used to verify the integrity of the request content during transport. When this header is specified, the storage service compares the hash of the content that has arrived with this header value. If the two hashes do not match, the operation will fail with error code 400 (Bad Request). Note that this MD5 hash is not stored with the file. This header is associated with the request content, and not with the stored content of the file itself
    # + xMsLeaseId - The lease ID must be specified if there is an active lease
    # + xMsCacheControl - Optional and only valid for flush and set properties operations.  The service stores this value and includes it in the "Cache-Control" response header for "Read File" operations
    # + xMsContentType - Optional and only valid for flush and set properties operations.  The service stores this value and includes it in the "Content-Type" response header for "Read File" operations
    # + xMsContentDisposition - Optional and only valid for flush and set properties operations.  The service stores this value and includes it in the "Content-Disposition" response header for "Read File" operations
    # + xMsContentEncoding - Optional and only valid for flush and set properties operations.  The service stores this value and includes it in the "Content-Encoding" response header for "Read File" operations
    # + xMsContentLanguage - Optional and only valid for flush and set properties operations.  The service stores this value and includes it in the "Content-Language" response header for "Read File" operations
    # + xMsContentMd5 - Optional and only valid for "Flush & Set Properties" operations.  The service stores this value and includes it in the "Content-Md5" response header for "Read & Get Properties" operations. If this property is not specified on the request, then the property will be cleared for the file. Subsequent calls to "Read & Get Properties" will not return this property unless it is explicitly set on that file again
    # + xMsProperties - Optional.  User-defined properties to be stored with the file or directory, in the format of a comma-separated list of name and value pairs "n1=v1, n2=v2, ...", where each value is a base64 encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set. Valid only for the setProperties operation. If the file or directory exists, any properties not included in the list will be removed.  All properties are removed if the header is omitted.  To merge new and existing properties, first get all existing properties and the current E-Tag, then make a conditional request with the E-Tag and include values for all properties
    # + xMsOwner - Optional and valid only for the setAccessControl operation. Sets the owner of the file or directory
    # + xMsGroup - Optional and valid only for the setAccessControl operation. Sets the owning group of the file or directory
    # + xMsPermissions - Optional and only valid if Hierarchical Namespace is enabled for the account. Sets POSIX access permissions for the file owner, the file owning group, and others. Each class may be granted read, write, or execute permission.  The sticky bit is also supported.  Both symbolic (rwxrw-rw-) and 4-digit octal notation (e.g. 0766) are supported. Invalid in conjunction with x-ms-acl
    # + xMsAcl - Optional and valid only for the setAccessControl operation. Sets POSIX access control rights on files and directories. The value is a comma-separated list of access control entries that fully replaces the existing access control list (ACL).  Each access control entry (ACE) consists of a scope, a type, a user or group identifier, and permissions in the format "[scope:][type]:[id]:[permissions]". The scope must be "default" to indicate the ACE belongs to the default ACL for a directory; otherwise scope is implicit and the ACE belongs to the access ACL.  There are four ACE types: "user" grants rights to the owner or a named user, "group" grants rights to the owning group or a named group, "mask" restricts rights granted to named users and the members of groups, and "other" grants rights to all users not found in any of the other entries. The user or group identifier is omitted for entries of type "mask" and "other".  The user or group identifier is also omitted for the owner and owning group.  The permission field is a 3-character sequence where the first character is 'r' to grant read access, the second character is 'w' to grant write access, and the third character is 'x' to grant execute permission.  If access is not granted, the '-' character is used to denote that the permission is denied. For example, the following ACL grants read, write, and execute rights to the file owner and john.doe@contoso, the read right to the owning group, and nothing to everyone else: "user::rwx,user:john.doe@contoso:rwx,group::r--,other::---,mask=rwx". Invalid in conjunction with x-ms-permissions
    # + ifMatch - Optional for Flush Data and Set Properties, but invalid for Append Data.  An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes
    # + ifNoneMatch - Optional for Flush Data and Set Properties, but invalid for Append Data.  An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes
    # + ifModifiedSince - Optional for Flush Data and Set Properties, but invalid for Append Data. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time
    # + ifUnmodifiedSince - Optional for Flush Data and Set Properties, but invalid for Append Data. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time
    # + payload - Valid only for append operations.  The data to be uploaded and appended to the file 
    # + return - `http:Ok` or `http:Accepted` on success, or a `DataLakeStorageErrorDefault` describing the storage error
    resource function patch [string filesystem]/[string path](@http:Header {name: "x-ms-client-request-id"} string? xMsClientRequestId, int:Signed32? timeout, @http:Header {name: "x-ms-date"} string? xMsDate, "append"|"flush"|"setProperties"|"setAccessControl" action, int? position, boolean? retainUncommittedData, boolean? close, @http:Header {name: "Content-Length"} int? contentLength, @http:Header {name: "Content-MD5"} string? contentMD5, @http:Header {name: "x-ms-lease-id"} string? xMsLeaseId, @http:Header {name: "x-ms-cache-control"} string? xMsCacheControl, @http:Header {name: "x-ms-content-type"} string? xMsContentType, @http:Header {name: "x-ms-content-disposition"} string? xMsContentDisposition, @http:Header {name: "x-ms-content-encoding"} string? xMsContentEncoding, @http:Header {name: "x-ms-content-language"} string? xMsContentLanguage, @http:Header {name: "x-ms-content-md5"} string? xMsContentMd5, @http:Header {name: "x-ms-properties"} string? xMsProperties, @http:Header {name: "x-ms-owner"} string? xMsOwner, @http:Header {name: "x-ms-group"} string? xMsGroup, @http:Header {name: "x-ms-permissions"} string? xMsPermissions, @http:Header {name: "x-ms-acl"} string? xMsAcl, @http:Header {name: "If-Match"} string? ifMatch, @http:Header {name: "If-None-Match"} string? ifNoneMatch, @http:Header {name: "If-Modified-Since"} string? ifModifiedSince, @http:Header {name: "If-Unmodified-Since"} string? ifUnmodifiedSince, @http:Payload byte[]|record {byte[] fileContent; string fileName;} payload, @http:Header {name: "x-ms-version"} string? xMsVersion = "2019-10-31") returns http:Ok|http:Accepted|DataLakeStorageErrorDefault {
        string key = pathKey(filesystem, path);
        byte[] & readonly data = (payload is byte[] ? payload : payload.fileContent).cloneReadOnly();
        lock {
            Path? entry = store.paths[key];
            if entry is () {
                return storageError(404, "PathNotFound", "The specified path does not exist.");
            }
            byte[] content = store.contents[key] ?: [];
            if action == "append" {
                if position != content.length() {
                    return storageError(400, "InvalidFlushPosition", "The uploaded data is not contiguous or the position query parameter value is not equal to the length of the file after appending the uploaded data.");
                }
                content.push(...data);
                store.contents[key] = content;
                return <http:Accepted>{headers: {"x-ms-request-id": MOCK_REQUEST_ID}};
            }
            if action == "flush" {
                if position is () || position > content.length() {
                    return storageError(400, "InvalidFlushPosition", "The uploaded data is not contiguous or the position query parameter value is not equal to the length of the file after appending the uploaded data.");
                }
                entry.contentLength = position;
                return <http:Ok>{headers: {"ETag": MOCK_ETAG, "Last-Modified": MOCK_DATE}};
            }
            if xMsOwner is string {
                entry.owner = xMsOwner;
            }
            if xMsGroup is string {
                entry.group = xMsGroup;
            }
            if xMsPermissions is string {
                entry.permissions = xMsPermissions;
            }
        }
        return <http:Ok>{headers: {"ETag": MOCK_ETAG, "Last-Modified": MOCK_DATE}};
    }

    # Lease Path
    #
    # + filesystem - The filesystem identifier
    # + path - The file or directory path
    # + xMsClientRequestId - A UUID recorded in the analytics logs for troubleshooting and correlation
    # + timeout - An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails
    # + xMsDate - Specifies the Coordinated Universal Time (UTC) for the request.  This is required when using shared key authorization
    # + xMsVersion - Specifies the version of the REST protocol used for processing the request. Required for every authorized request, including those that use a Microsoft Entra ID bearer token. Defaults to 2019-10-31
    # + xMsLeaseAction - There are five lease actions: "acquire", "break", "change", "renew", and "release". Use "acquire" and specify the "x-ms-proposed-lease-id" and "x-ms-lease-duration" to acquire a new lease. Use "break" to break an existing lease. When a lease is broken, the lease break period is allowed to elapse, during which time no lease operation except break and release can be performed on the file. When a lease is successfully broken, the response indicates the interval in seconds until a new lease can be acquired. Use "change" and specify the current lease ID in "x-ms-lease-id" and the new lease ID in "x-ms-proposed-lease-id" to change the lease ID of an active lease. Use "renew" and specify the "x-ms-lease-id" to renew an existing lease. Use "release" and specify the "x-ms-lease-id" to release a lease
    # + xMsLeaseDuration - The lease duration is required to acquire a lease, and specifies the duration of the lease in seconds.  The lease duration must be between 15 and 60 seconds or -1 for infinite lease
    # + xMsLeaseBreakPeriod - The lease break period duration is optional to break a lease, and  specifies the break period of the lease in seconds.  The lease break  duration must be between 0 and 60 seconds
    # + xMsLeaseId - Required when "x-ms-lease-action" is "renew", "change" or "release". For the renew and release actions, this must match the current lease ID
    # + xMsProposedLeaseId - Required when "x-ms-lease-action" is "acquire" or "change".  A lease will be acquired with this lease ID if the operation is successful
    # + ifMatch - Optional.  An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes
    # + ifNoneMatch - Optional.  An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes
    # + ifModifiedSince - Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time
    # + ifUnmodifiedSince - Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time
    # + return - `http:Ok` or `http:Created` or `http:Accepted` on success, or a `DataLakeStorageErrorDefault` describing the storage error
    resource function post [string filesystem]/[string path](@http:Header {name: "x-ms-client-request-id"} string? xMsClientRequestId, int:Signed32? timeout, @http:Header {name: "x-ms-date"} string? xMsDate, @http:Header {name: "x-ms-lease-action"} "acquire"|"break"|"change"|"renew"|"release" xMsLeaseAction, @http:Header {name: "x-ms-lease-duration"} int:Signed32? xMsLeaseDuration, @http:Header {name: "x-ms-lease-break-period"} int:Signed32? xMsLeaseBreakPeriod, @http:Header {name: "x-ms-lease-id"} string? xMsLeaseId, @http:Header {name: "x-ms-proposed-lease-id"} string? xMsProposedLeaseId, @http:Header {name: "If-Match"} string? ifMatch, @http:Header {name: "If-None-Match"} string? ifNoneMatch, @http:Header {name: "If-Modified-Since"} string? ifModifiedSince, @http:Header {name: "If-Unmodified-Since"} string? ifUnmodifiedSince, @http:Header {name: "x-ms-version"} string? xMsVersion = "2019-10-31") returns http:Ok|http:Created|http:Accepted|DataLakeStorageErrorDefault {
        if !pathExists(pathKey(filesystem, path)) {
            return storageError(404, "PathNotFound", "The specified path does not exist.");
        }
        if xMsLeaseAction == "acquire" {
            return <http:Created>{headers: {"x-ms-lease-id": xMsProposedLeaseId ?: MOCK_LEASE_ID, "ETag": MOCK_ETAG}};
        }
        if xMsLeaseAction == "break" {
            return <http:Accepted>{headers: {"x-ms-lease-time": "0", "ETag": MOCK_ETAG}};
        }
        if xMsLeaseId is () {
            return storageError(400, "MissingRequiredHeader", "An HTTP header that's mandatory for this request is not specified.");
        }
        string leaseId = xMsLeaseAction == "change" ? (xMsProposedLeaseId ?: xMsLeaseId) : xMsLeaseId;
        return <http:Ok>{headers: {"x-ms-lease-id": leaseId, "ETag": MOCK_ETAG}};
    }

    # Create Filesystem
    #
    # + filesystem - The filesystem identifier.  The value must start and end with a letter or number and must contain only letters, numbers, and the dash (-) character.  Consecutive dashes are not permitted.  All letters must be lowercase.  The value must have between 3 and 63 characters
    # + 'resource - The value must be "filesystem" for all filesystem operations
    # + xMsClientRequestId - A UUID recorded in the analytics logs for troubleshooting and correlation
    # + timeout - An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails
    # + xMsDate - Specifies the Coordinated Universal Time (UTC) for the request.  This is required when using shared key authorization
    # + xMsVersion - Specifies the version of the REST protocol used for processing the request. Required for every authorized request, including those that use a Microsoft Entra ID bearer token. Defaults to 2019-10-31
    # + xMsProperties - User-defined properties to be stored with the filesystem, in the format of a comma-separated list of name and value pairs "n1=v1, n2=v2, ...", where each value is a base64 encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set
    # + return - `http:Created` on success, or a `DataLakeStorageErrorDefault` describing the storage error
    resource function put [string filesystem]("filesystem" 'resource, @http:Header {name: "x-ms-client-request-id"} string? xMsClientRequestId, int:Signed32? timeout, @http:Header {name: "x-ms-date"} string? xMsDate, @http:Header {name: "x-ms-properties"} string? xMsProperties, @http:Header {name: "x-ms-version"} string? xMsVersion = "2019-10-31") returns http:Created|DataLakeStorageErrorDefault {
        lock {
            if store.filesystems.hasKey(filesystem) {
                return storageError(409, "FilesystemAlreadyExists", "The specified filesystem already exists.");
            }
            store.filesystems[filesystem] = {name: filesystem, lastModified: MOCK_DATE, eTag: MOCK_ETAG};
        }
        if xMsProperties is string {
            lock {
                store.properties[filesystem] = xMsProperties;
            }
        }
        return <http:Created>{headers: {"ETag": MOCK_ETAG, "Last-Modified": MOCK_DATE, "x-ms-namespace-enabled": "true"}};
    }

    # Create File | Create Directory | Rename File | Rename Directory
    #
    # + filesystem - The filesystem identifier
    # + path - The file or directory path
    # + xMsClientRequestId - A UUID recorded in the analytics logs for troubleshooting and correlation
    # + timeout - An optional operation timeout value in seconds. The period begins when the request is received by the service. If the timeout value elapses before the operation completes, the operation fails
    # + xMsDate - Specifies the Coordinated Universal Time (UTC) for the request.  This is required when using shared key authorization
    # + xMsVersion - Specifies the version of the REST protocol used for processing the request. Required for every authorized request, including those that use a Microsoft Entra ID bearer token. Defaults to 2019-10-31
    # + 'resource - Required only for Create File and Create Directory. The value must be "file" or "directory"
    # + continuation - Optional.  When renaming a directory, the number of paths that are renamed with each invocation is limited.  If the number of paths to be renamed exceeds this limit, a continuation token is returned in this response header.  When a continuation token is returned in the response, it must be specified in a subsequent invocation of the rename operation to continue renaming the directory
    # + mode - Optional. Valid only when namespace is enabled. This parameter determines the behavior of the rename operation. The value must be "legacy" or "posix", and the default value will be "posix". 
    # + cacheControl - Optional.  The service stores this value and includes it in the "Cache-Control" response header for "Read File" operations for "Read File" operations
    # + contentEncoding - Optional.  Specifies which content encodings have been applied to the file. This value is returned to the client when the "Read File" operation is performed
    # + contentLanguage - Optional.  Specifies the natural language used by the intended audience for the file
    # + contentDisposition - Optional.  The service stores this value and includes it in the "Content-Disposition" response header for "Read File" operations
    # + xMsCacheControl - Optional.  The service stores this value and includes it in the "Cache-Control" response header for "Read File" operations
    # + xMsContentType - Optional.  The service stores this value and includes it in the "Content-Type" response header for "Read File" operations
    # + xMsContentEncoding - Optional.  The service stores this value and includes it in the "Content-Encoding" response header for "Read File" operations
    # + xMsContentLanguage - Optional.  The service stores this value and includes it in the "Content-Language" response header for "Read File" operations
    # + xMsContentDisposition - Optional.  The service stores this value and includes it in the "Content-Disposition" response header for "Read File" operations
    # + xMsRenameSource - An optional file or directory to be renamed.  The value must have the following format: "/{filesystem}/{path}".  If "x-ms-properties" is specified, the properties will overwrite the existing properties; otherwise, the existing properties will be preserved. This value must be a URL percent-encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set
    # + xMsLeaseId - Optional.  A lease ID for the path specified in the URI.  The path to be overwritten must have an active lease and the lease ID must match
    # + xMsSourceLeaseId - Optional for rename operations.  A lease ID for the source path.  The source path must have an active lease and the lease ID must match
    # + xMsProperties - Optional.  User-defined properties to be stored with the file or directory, in the format of a comma-separated list of name and value pairs "n1=v1, n2=v2, ...", where each value is a base64 encoded string. Note that the string may only contain ASCII characters in the ISO-8859-1 character set
    # + xMsPermissions - Optional and only valid if Hierarchical Namespace is enabled for the account. Sets POSIX access permissions for the file owner, the file owning group, and others. Each class may be granted read, write, or execute permission.  The sticky bit is also supported.  Both symbolic (rwxrw-rw-) and 4-digit octal notation (e.g. 0766) are supported
    # + xMsUmask - Optional and only valid if Hierarchical Namespace is enabled for the account. When creating a file or directory and the parent folder does not have a default ACL, the umask restricts the permissions of the file or directory to be created.  The resulting permission is given by p & ^u, where p is the permission and u is the umask.  For example, if p is 0777 and u is 0057, then the resulting permission is 0720.  The default permission is 0777 for a directory and 0666 for a file.  The default umask is 0027.  The umask must be specified in 4-digit octal notation (e.g. 0766)
    # + ifMatch - Optional.  An ETag value. Specify this header to perform the operation only if the resource's ETag matches the value specified. The ETag must be specified in quotes
    # + ifNoneMatch - Optional.  An ETag value or the special wildcard ("*") value. Specify this header to perform the operation only if the resource's ETag does not match the value specified. The ETag must be specified in quotes
    # + ifModifiedSince - Optional. A date and time value. Specify this header to perform the operation only if the resource has been modified since the specified date and time
    # + ifUnmodifiedSince - Optional. A date and time value. Specify this header to perform the operation only if the resource has not been modified since the specified date and time
    # + xMsSourceIfMatch - Optional.  An ETag value. Specify this header to perform the rename operation only if the source's ETag matches the value specified. The ETag must be specified in quotes
    # + xMsSourceIfNoneMatch - Optional.  An ETag value or the special wildcard ("*") value. Specify this header to perform the rename operation only if the source's ETag does not match the value specified. The ETag must be specified in quotes
    # + xMsSourceIfModifiedSince - Optional. A date and time value. Specify this header to perform the rename operation only if the source has been modified since the specified date and time
    # + xMsSourceIfUnmodifiedSince - Optional. A date and time value. Specify this header to perform the rename operation only if the source has not been modified since the specified date and time
    # + return - `http:Created` on success, or a `DataLakeStorageErrorDefault` describing the storage error
    resource function put [string filesystem]/[string path](@http:Header {name: "x-ms-client-request-id"} string? xMsClientRequestId, int:Signed32? timeout, @http:Header {name: "x-ms-date"} string? xMsDate, "directory"|"file"? 'resource, string? continuation, "legacy"|"posix"? mode, @http:Header {name: "Cache-Control"} string? cacheControl, @http:Header {name: "Content-Encoding"} string? contentEncoding, @http:Header {name: "Content-Language"} string? contentLanguage, @http:Header {name: "Content-Disposition"} string? contentDisposition, @http:Header {name: "x-ms-cache-control"} string? xMsCacheControl, @http:Header {name: "x-ms-content-type"} string? xMsContentType, @http:Header {name: "x-ms-content-encoding"} string? xMsContentEncoding, @http:Header {name: "x-ms-content-language"} string? xMsContentLanguage, @http:Header {name: "x-ms-content-disposition"} string? xMsContentDisposition, @http:Header {name: "x-ms-rename-source"} string? xMsRenameSource, @http:Header {name: "x-ms-lease-id"} string? xMsLeaseId, @http:Header {name: "x-ms-source-lease-id"} string? xMsSourceLeaseId, @http:Header {name: "x-ms-properties"} string? xMsProperties, @http:Header {name: "x-ms-permissions"} string? xMsPermissions, @http:Header {name: "x-ms-umask"} string? xMsUmask, @http:Header {name: "If-Match"} string? ifMatch, @http:Header {name: "If-None-Match"} string? ifNoneMatch, @http:Header {name: "If-Modified-Since"} string? ifModifiedSince, @http:Header {name: "If-Unmodified-Since"} string? ifUnmodifiedSince, @http:Header {name: "x-ms-source-if-match"} string? xMsSourceIfMatch, @http:Header {name: "x-ms-source-if-none-match"} string? xMsSourceIfNoneMatch, @http:Header {name: "x-ms-source-if-modified-since"} string? xMsSourceIfModifiedSince, @http:Header {name: "x-ms-source-if-unmodified-since"} string? xMsSourceIfUnmodifiedSince, @http:Header {name: "x-ms-version"} string? xMsVersion = "2019-10-31") returns http:Created|DataLakeStorageErrorDefault {
        if !filesystemExists(filesystem) {
            return storageError(404, "FilesystemNotFound", "The specified filesystem does not exist.");
        }
        string key = pathKey(filesystem, path);
        if xMsRenameSource is string {
            string sourceKey = xMsRenameSource.startsWith("/") ? xMsRenameSource.substring(1) : xMsRenameSource;
            if !pathExists(sourceKey) {
                return storageError(404, "SourcePathNotFound", "The source path for a rename operation does not exist.");
            }
            renamePaths(sourceKey, key, filesystem);
            return <http:Created>{headers: {"ETag": MOCK_ETAG, "Last-Modified": MOCK_DATE}};
        }
        boolean isDirectory = 'resource == "directory";
        lock {
            store.paths[key] = {
                name: path,
                isDirectory,
                lastModified: MOCK_DATE,
                eTag: MOCK_ETAG,
                contentLength: 0,
                owner: "$superuser",
                group: "$superuser",
                permissions: xMsPermissions ?: (isDirectory ? "rwxr-x---" : "rw-r-----")
            };
            if !isDirectory {
                store.contents[key] = [];
            }
        }
        return <http:Created>{headers: {"ETag": MOCK_ETAG, "Last-Modified": MOCK_DATE}};
    }
}

// Service-mode response types. `bal openapi --mode client` collapses 4XX/5XX
// to `error` and never emits these, so they are defined here for the mock only.
public type DataLakeStorageErrorDefault record {|
    *http:DefaultStatusCodeResponse;
    DataLakeStorageError body;
    record {|string x\-ms\-version?; string x\-ms\-request\-id?;|} headers;
|};

# An error returned by the Data Lake Storage service

# The service error response object

const MOCK_ETAG = "\"0x8DEDC4A1F2B3C4D\"";
const MOCK_DATE = "Thu, 24 Sep 2026 09:30:00 GMT";
const MOCK_REQUEST_ID = "a1b2c3d4-0000-4e5f-8a9b-0123456789ab";
const MOCK_LEASE_ID = "5e1f9a3c-7b2d-4c8e-9f60-1a2b3c4d5e6f";
const SEED_REPORT = "region,revenue\nnorth,12500\nsouth,9800\n";

// In-memory state, so that what a test creates is what the next call returns.
// Seeded through an initializer because the mock must not declare an `init()`.
type MockStore record {|
    map<Filesystem> filesystems;
    map<string> properties;
    map<Path> paths;
    map<byte[]> contents;
|};

isolated MockStore store = {
    filesystems: {
        "analytics": {name: "analytics", lastModified: MOCK_DATE, eTag: MOCK_ETAG},
        "raw-events": {name: "raw-events", lastModified: MOCK_DATE, eTag: MOCK_ETAG}
    },
    properties: {"analytics": "department=ZmluYW5jZQ=="},
    paths: {
        "analytics/reports": {
            name: "reports", isDirectory: true, lastModified: MOCK_DATE, eTag: MOCK_ETAG,
            contentLength: 0, owner: "$superuser", group: "$superuser", permissions: "rwxr-x---"
        },
        "analytics/reports/2026-09.csv": {
            name: "reports/2026-09.csv", isDirectory: false, lastModified: MOCK_DATE, eTag: MOCK_ETAG,
            contentLength: SEED_REPORT.length(), owner: "$superuser", group: "$superuser", permissions: "rw-r-----"
        }
    },
    contents: {"analytics/reports/2026-09.csv": SEED_REPORT.toBytes()}
};

# An error returned by the Data Lake Storage service.
public type DataLakeStorageError record {
    # The service error response object
    DataLakeStorageErrorDetail 'error?;
};

# The service error response object.
public type DataLakeStorageErrorDetail record {
    # The service error code
    string code?;
    # The service error message
    string message?;
};

# Service-mode response type for a ranged read (HTTP 206).
public type ByteArrayPartialContent record {|
    *http:PartialContent;
    # The requested byte range of the file
    byte[] body;
|};

isolated function pathKey(string filesystem, string path) returns string =>
    filesystem + "/" + (path.startsWith("/") ? path.substring(1) : path);

isolated function filesystemExists(string filesystem) returns boolean {
    lock {
        return store.filesystems.hasKey(filesystem);
    }
}

isolated function pathExists(string key) returns boolean {
    lock {
        return store.paths.hasKey(key);
    }
}

isolated function hasChildren(map<Path> store, string key) returns boolean {
    foreach string candidate in store.keys() {
        if candidate.startsWith(key + "/") {
            return true;
        }
    }
    return false;
}

// Removes the entry at `key` and everything beneath it.
isolated function removePaths(string key) {
    lock {
        foreach string candidate in store.paths.keys() {
            if candidate == key || candidate.startsWith(key + "/") {
                _ = store.paths.remove(candidate);
                if store.contents.hasKey(candidate) {
                    _ = store.contents.remove(candidate);
                }
            }
        }
    }
}

// Moves the entry at `sourceKey`, and everything beneath it, to `targetKey`.
isolated function renamePaths(string sourceKey, string targetKey, string filesystem) {
    lock {
        foreach string candidate in store.paths.keys() {
            if candidate == sourceKey || candidate.startsWith(sourceKey + "/") {
                string newKey = targetKey + candidate.substring(sourceKey.length());
                Path entry = store.paths.remove(candidate);
                entry.name = newKey.substring(filesystem.length() + 1);
                store.paths[newKey] = entry;
                if store.contents.hasKey(candidate) {
                    store.contents[newKey] = store.contents.remove(candidate);
                }
            }
        }
    }
}

// Parses a single `bytes=<start>-<end>` range against a file of `size` bytes.
isolated function parseRange(string range, int size) returns int[]|error {
    if !range.startsWith("bytes=") {
        return error("unsupported range unit");
    }
    string spec = range.substring(6);
    int? dash = spec.indexOf("-");
    if dash is () {
        return error("malformed range");
    }
    int 'start = check int:fromString(spec.substring(0, dash));
    string endText = spec.substring(dash + 1);
    int end = endText == "" ? size - 1 : int:min(check int:fromString(endText), size - 1);
    if 'start > end || 'start >= size {
        return error("range not satisfiable");
    }
    return ['start, end];
}

isolated function storageError(int statusCode, string code, string message) returns DataLakeStorageErrorDefault => {
    status: new (statusCode),
    body: {'error: {code, message}},
    headers: {}
};
