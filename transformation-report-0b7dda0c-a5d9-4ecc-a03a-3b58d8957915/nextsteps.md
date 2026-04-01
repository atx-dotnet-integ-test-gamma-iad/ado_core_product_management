# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

### 3. Build the Solution
Perform a clean build to confirm there are no errors in the restored state:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output for any failures that may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Platform-Specific API Usage
Even when a project builds successfully, it may reference APIs that are not fully supported on all platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any warnings produced during the build related to platform compatibility attributes such as `[SupportedOSPlatform]`.

### 6. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that configuration values have been migrated to `appsettings.json` or equivalent mechanisms supported by the new hosting model.

### 7. Verify Runtime Behavior
Run the application manually or through its entry point and exercise the primary workflows to confirm that output and behavior match the legacy version:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 8. Check for Removed or Changed APIs
Review the [.NET Upgrade Assistant compatibility reports](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [.NET API Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/api-analyzer) output to identify any APIs that were available in .NET Framework but have changed behavior or been removed in cross-platform .NET.

### 9. Validate Third-Party Dependencies
Confirm that all NuGet packages referenced in the project have versions available that target `netstandard2.0`, `netstandard2.1`, or the specific `net6.0`/`net7.0`/`net8.0` moniker. Packages that only ship .NET Framework binaries may require replacement.

### 10. Publish a Release Build
Once validation is complete, produce a published output to confirm the final artifact is generated correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all expected assemblies and assets are present.