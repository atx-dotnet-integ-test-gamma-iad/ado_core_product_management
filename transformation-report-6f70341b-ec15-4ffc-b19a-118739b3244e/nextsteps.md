# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including the core project `AdoCore.csproj`.

## Validation Steps

### 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to a supported cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages.

### 3. Build the Solution

Perform a full build to confirm there are no runtime or configuration issues that were not caught during the initial transformation analysis:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output and address any failing tests before proceeding.

### 5. Check for Platform-Specific API Usage

Even without build errors, there may be runtime issues caused by Windows-specific APIs that compile successfully but fail on other platforms. Use the .NET Platform Compatibility Analyzer by ensuring your project file includes:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Then rebuild and review any new analyzer warnings related to platform compatibility (e.g., `CA1416`).

### 6. Review `app.config` or `web.config` Migrations

If the original project used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment-based configuration, as these legacy config mechanisms have limited support in cross-platform .NET.

### 7. Verify Runtime Behavior on Target Platforms

Run the application on each intended target platform (Linux, macOS, Windows) to catch any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

### 8. Check for Removed or Changed APIs

Review the [.NET Upgrade Assistant compatibility report](https://learn.microsoft.com/en-us/dotnet/core/porting/) or use `dotnet-apicompat` to identify any APIs that may have changed behavior between .NET Framework and modern .NET, even if they compiled without errors.

### 9. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example:
- `win-x64`
- `linux-x64`
- `osx-x64`

Review the publish output directory to confirm all required assets are present.