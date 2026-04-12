# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly under the new target framework:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that have been deprecated and may need replacement.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build
```

Review warnings in addition to errors, as some warnings may indicate APIs that are obsolete or behave differently in cross-platform .NET.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test
```

Pay close attention to any tests that interact with file paths, registry access, Windows-specific APIs, or COM interop, as these areas are common sources of cross-platform issues that may not surface as build errors.

## 5. Validate Runtime Behavior on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) and verify:

- File path separators behave correctly (`Path.Combine` should handle this, but hardcoded paths may not).
- Any database or ADO.NET connections (given the `AdoCore` project name) function as expected with the appropriate driver packages.
- Configuration files (e.g., `appsettings.json`) are read correctly and any legacy `app.config` or `web.config` values have been accounted for.

## 6. Review ADO.NET and Data Access Code

Given the project name `AdoCore`, confirm the following:

- The correct database provider NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` for SQL Server).
- Connection strings are sourced from a cross-platform compatible configuration source.
- Any use of `System.Data.OleDb` or `System.Data.Odbc` is reviewed, as these have limited or no support on non-Windows platforms.

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish -c Release -r <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value, for example:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Review the publish output directory to confirm all required files are present before deployment.