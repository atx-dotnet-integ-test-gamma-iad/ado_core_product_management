# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that may have been replaced during the transformation. Update any outdated packages using:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

## 3. Build the Solution

Perform a clean build to confirm there are no errors:

```bash
dotnet clean
dotnet build
```

Address any warnings that surface during the build, particularly those related to nullable reference types or platform compatibility annotations.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test
```

Review the test output carefully. Any failing tests should be investigated to determine whether the failure is due to the migration or a pre-existing issue.

## 5. Validate Platform-Specific Behavior

Since this project was migrated from a legacy (likely Windows-only) framework, identify any APIs that may behave differently across platforms. Check for:

- File path separators (`\` vs `/`) — use `Path.Combine` where applicable.
- Windows registry access — not available on Linux/macOS.
- `System.Windows` or `System.Drawing` namespaces — these may require the `System.Drawing.Common` NuGet package or a platform-specific alternative.
- Any P/Invoke calls targeting Windows-specific native libraries.

Run the application on each target platform (Windows, Linux, macOS) to surface any runtime issues that would not appear at compile time.

## 6. Review Removed or Changed APIs

Cross-reference the project's usage of APIs against the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) output. You can enable this in the project file:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild after adding these properties and address any new diagnostics.

## 7. Test Runtime Behavior

Run the application manually and exercise its primary workflows. Confirm that:

- Configuration files (e.g., `appsettings.json`, previously `app.config`) are being read correctly.
- Database connections (given the `Ado` naming, ADO.NET usage is likely) function as expected against the target database.
- Any connection strings have been migrated from `app.config` to the appropriate .NET configuration system.

## 8. Publish the Application

Once validation is complete, publish the application for the target platform:

```bash
dotnet publish -c Release -r <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example:

- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Review the contents of the `publish` output folder before deploying to confirm all required assets are present.