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

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. If any packages were previously targeting .NET Framework, confirm their cross-platform compatible versions are now referenced.

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to platform compatibility (e.g., `CA1416` platform-specific API warnings).

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release
```

Review the test results carefully. Any failures may indicate behavioral differences between .NET Framework and cross-platform .NET, such as:

- Changes in `System.Data` behavior
- Differences in connection string handling
- Removed or changed APIs in ADO.NET

## 5. Validate ADO.NET Functionality

Since the project is named `AdoCore`, it likely involves database access. Verify the following:

- The correct database provider NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` for SQL Server).
- Connection strings are valid and accessible in the new environment.
- Any use of `System.Data.OleDb` or `System.Data.Odbc` is reviewed, as these have limited or no support on non-Windows platforms.

You can check for `System.Data.OleDb` usage specifically by searching your codebase:

```bash
grep -r "OleDb" .
```

If OleDb usage is found and cross-platform support is required, a replacement provider will be needed.

## 6. Check for Platform-Specific Code

Use the .NET Compatibility Analyzer to surface any remaining platform-specific API usage:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Review any `CA1416` warnings, which indicate APIs that are only supported on specific operating systems.

## 7. Run the Application

Execute the application directly to perform a basic smoke test:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Confirm the application starts and behaves as expected against your target database or data source.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment.

For a self-contained deployment on a specific runtime:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

The published output will be located in the `bin/Release/{TargetFramework}/publish/` directory. Verify the output directory contains all expected assemblies and configuration files before deploying to your target environment.