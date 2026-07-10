# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that may have been replaced during the transformation (e.g., `System.Data.SqlClient` replaced by `Microsoft.Data.SqlClient`).

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review any warnings in the build output. While warnings do not block compilation, they may indicate areas where APIs have changed behavior in cross-platform .NET.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review failing tests carefully, as they may indicate runtime behavioral differences between .NET Framework and cross-platform .NET, particularly around:

- `System.Data` and ADO.NET behavior differences
- Connection string formats
- Platform-specific APIs that may have been silently removed or stubbed

## 5. Validate ADO.NET Functionality

Since the project is named `AdoCore`, it likely contains data access logic. Manually verify the following:

- **Connection strings** are valid and use a supported provider (e.g., `Microsoft.Data.SqlClient` for SQL Server).
- **DataSet, DataTable, and DataAdapter** usage still behaves as expected, as some serialization behaviors differ in cross-platform .NET.
- **Transactions** and **stored procedure calls** execute correctly against your target database.
- Any use of `OleDb` or `Odbc` providers is noted — `System.Data.OleDb` is Windows-only and `System.Data.Odbc` has platform limitations.

## 6. Check for Windows-Only API Usage

Run the .NET Compatibility Analyzer to detect any remaining platform-specific API calls:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Alternatively, review the project for usage of:

- `Microsoft.Win32` namespaces
- `System.Web` references
- Windows registry access
- COM interop

## 7. Test on Target Platform

If cross-platform support (Linux/macOS) is a goal, run the application on the intended target operating system to surface any runtime issues that do not appear on Windows.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example:

- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Review the publish output directory to confirm all required assemblies and configuration files are present before deploying to the target environment.