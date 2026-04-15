# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and consider updating them.

### 3. Build the Solution
Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Review Removed or Replaced APIs
Check the code for any APIs that were available in .NET Framework but behave differently in cross-platform .NET. Common areas to review include:

- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific APIs such as the registry, WCF, or remoting
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)
- `ConfigurationManager` (requires the `System.Configuration.ConfigurationManager` NuGet package)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to surface any remaining concerns.

### 6. Run the Application
Execute the application and perform manual or automated smoke testing against its primary workflows to confirm runtime behavior matches expectations from the legacy version.

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 7. Review Output Artifacts
Confirm the build output is placed in the expected location and that all required files (configuration files, static assets, etc.) are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure the output is complete before deploying.

### 8. Deployment
Once validation is complete, publish the application to the target environment using the appropriate runtime identifier if a self-contained deployment is needed:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`). Refer to the [.NET RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog) for a full list of supported identifiers.