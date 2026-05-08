# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime environment you intend to deploy to.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality behaves as expected after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new .NET runtime.

## 4. Check for Runtime Compatibility Issues

Some APIs behave differently or are absent in cross-platform .NET even when they compile without errors. Pay attention to the following areas:

- **Windows-specific APIs**: Any usage of `System.Windows.Forms`, `System.Drawing`, `Microsoft.Win32`, or P/Invoke calls may not function on non-Windows platforms. Use the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to identify these.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package in cross-platform .NET.
- **AppDomain and Reflection**: Some `AppDomain` members are no longer supported and may throw `PlatformNotSupportedException` at runtime.

## 5. Review NuGet Package Versions

Ensure all NuGet packages referenced in `AdoCore.csproj` are compatible with your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that previously targeted .NET Framework only.

## 6. Validate Database Connectivity (ADO Specific)

Given the project name `AdoCore`, it likely involves ADO.NET data access. Verify the following at runtime:

- Connection strings are correctly sourced (e.g., from `appsettings.json` rather than `app.config` if applicable).
- The correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of the legacy `System.Data.SqlClient` where applicable).
- Any `DataSet`, `DataTable`, or `DataAdapter` usage functions as expected, as these are supported but carry known behavioral nuances.

## 7. Test on Target Platform

If the intent is to run on a non-Windows OS, perform an explicit test on that platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Then execute the published output on the target machine and validate behavior against the legacy application.

## 8. Review Application Output and Logs

Run the application end-to-end in a staging environment and compare output and behavior against the original .NET Framework version. Pay particular attention to:

- Exception handling paths
- File I/O operations (path separators differ between Windows and Linux)
- Culture and encoding-sensitive operations