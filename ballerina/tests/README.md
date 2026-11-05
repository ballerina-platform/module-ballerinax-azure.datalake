# Tests

The suite covers all 12 operations of the connector: creating, listing, reading the properties of, updating and deleting filesystems; creating, renaming, listing and deleting files and directories; appending, flushing and reading file content, including a ranged read; reading path properties and access control lists; and acquiring, renewing and releasing a lease. Every test creates the filesystem it works in and deletes it afterwards, so tests do not depend on each other or on execution order.

The mock server keeps state in memory, so a file written by a test is what the next call reads back.

## Running Tests

```bash
bal test
```

The test suite uses a mock server (`tests/mock_service.bal`) that intercepts HTTP calls so no real credentials are required.

To run the `live_tests` group against a real storage account, set the following environment variables. The account must have a hierarchical namespace enabled, and the token's identity needs the **Storage Blob Data Owner** role on it, because the tests read access control lists.

| Variable | Value |
|---|---|
| `IS_LIVE_SERVER` | `true` |
| `AZURE_STORAGE_ACCOUNT` | The storage account name |
| `AZURE_STORAGE_TOKEN` | A Microsoft Entra ID access token for `https://storage.azure.com/` |

```bash
bal test --groups live_tests
```
