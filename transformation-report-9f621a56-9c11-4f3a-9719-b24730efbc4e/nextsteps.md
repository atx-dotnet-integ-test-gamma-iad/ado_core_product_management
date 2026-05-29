# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. The following steps outline how to validate, test, and deploy the migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element targets the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this is consistent with any dependent or consuming projects in the solution.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore NuGet Packages

Run a package restore to ensure all dependencies are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. Replace any packages that have known .NET-compatible alternatives if warnings are present.

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete API usage, as these can indicate areas of risk.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify that existing behavior has been preserved after the migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether the failure is due to a behavioral difference in the new runtime or a pre-existing issue.

## 5. Validate ADO.NET Functionality

Since this project appears to be ADO-related (`AdoCore`), manually verify the following:

- **Connection strings** are correctly configured and point to the intended database.
- **Data provider packages** (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are the cross-platform compatible versions and not legacy Windows-only packages.
- **Database operations** such as open/close connections, queries, and transactions execute without errors against a real or test database instance.

## 6. Check for Windows-Specific API Usage

Run the .NET Compatibility Analyzer or review the code manually for any remaining Windows-specific APIs that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet build /p:PlatformTarget=AnyCPU
```

Pay particular attention to:
- `System.Data.OleDb` (Windows-only)
- `System.Data.Odbc` (limited cross-platform support)
- Registry access or Windows file path assumptions

## 7. Test on Target Platform

If cross-platform support is a goal, run and test the application on the intended non-Windows platform (Linux or macOS) to surface any runtime issues that do not appear during compilation.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag to match your deployment target (e.g., `win-x64`, `osx-x64`, `linux-x64`). Use `--self-contained true` if the target environment does not have the .NET runtime installed.