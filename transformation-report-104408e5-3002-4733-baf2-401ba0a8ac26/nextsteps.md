# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
```

## 2. Restore and Build the Solution

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were not caught as errors.

## 3. Review NuGet Package Compatibility

Check all NuGet dependencies referenced in `AdoCore.csproj` to confirm they target .NET Standard 2.0+ or the specific .NET version you are using. You can inspect package compatibility using:

```bash
dotnet list package --outdated
```

Update any outdated or incompatible packages as needed.

## 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger trx
```

Review the test results carefully. Pay particular attention to any tests covering data access or ADO.NET-specific functionality, as these are most likely to surface behavioral differences between .NET Framework and cross-platform .NET.

## 5. Validate ADO.NET and Database Connectivity

Since the project name suggests ADO.NET usage (`AdoCore`), verify the following:

- Connection strings are correctly configured for the target environment.
- Any database drivers or providers (e.g., `Microsoft.Data.SqlClient`, `Npgsql`, `MySql.Data`) are the cross-platform compatible versions.
- Replace any usage of `System.Data.OleDb` or `System.Data.Odbc` if targeting non-Windows platforms, as these have limited or no support on Linux/macOS.

## 6. Check for Platform-Specific Code

Search the codebase for any APIs that are Windows-only and may not function correctly on Linux or macOS. Common areas to check:

- Registry access (`Microsoft.Win32.Registry`)
- Windows Event Log (`System.Diagnostics.EventLog`)
- `System.Drawing` (requires `libgdiplus` on Linux or replacement with a cross-platform library)

Use the .NET Compatibility Analyzer to assist with this:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

## 7. Test on the Target Platform

If the goal is cross-platform support, run the application on the intended non-Windows platform (Linux or macOS) to catch any runtime issues not surfaced during the Windows build:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the output in the `./publish` directory contains all expected files before deploying to the target environment.