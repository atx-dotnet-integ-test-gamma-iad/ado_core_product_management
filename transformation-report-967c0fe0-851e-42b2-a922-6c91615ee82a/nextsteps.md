# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version mismatches. If any packages targeting only .NET Framework are present, locate cross-platform equivalents on [NuGet](https://www.nuget.org).

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete APIs, as these can indicate areas that may cause runtime issues.

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between .NET Framework and cross-platform .NET, such as changes in:

- `System.Data` behavior
- ADO.NET provider availability
- Connection string formats
- Platform-specific file path handling

## 5. Validate ADO.NET Database Connectivity

Since this project is named `AdoCore`, it likely involves database access. Verify the following:

- The database provider package (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) is referenced and up to date in the `.csproj` file.
- Connection strings are valid and accessible from the target environment.
- Any use of `System.Data.OleDb` or `System.Data.Odbc` is reviewed, as these have limited or no support on non-Windows platforms.

Run a manual integration test or a small console program that exercises the database connection to confirm end-to-end connectivity.

## 6. Check for Platform-Specific Code

Search the codebase for APIs that may behave differently or are unavailable on non-Windows platforms:

- `Registry` access (`Microsoft.Win32.Registry`)
- `System.Drawing` (requires additional packages on Linux/macOS)
- `System.Security.Permissions`
- COM interop or P/Invoke calls

If any are found, evaluate whether a cross-platform alternative exists or whether the code path needs to be conditionally compiled.

## 7. Run on Target Platform

If the goal is cross-platform execution, test the application explicitly on the target operating system (Linux or macOS) by publishing a self-contained or framework-dependent build:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Then execute the output on the target machine and observe any runtime exceptions that did not appear during the Windows build.

## 8. Review Output and Assembly Metadata

Confirm the output assembly is produced in the expected location under `bin/Release/net8.0/` (or whichever target framework was chosen) and that the assembly metadata, such as version and company information, is correctly defined in the `.csproj` or an `AssemblyInfo.cs` file.