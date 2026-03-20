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
Perform a full build to confirm there are no issues:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing functionality is intact:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Review Removed or Unsupported APIs
Check the code for any usage of APIs that were available in .NET Framework but have been removed or altered in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) can assist with this.

Common areas to review include:
- `System.Web` usage (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- `BinaryFormatter` (deprecated and disabled by default)
- `AppDomain` APIs with limited support

### 6. Verify Configuration Files
If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated appropriately to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`.

### 7. Test on Target Platforms
If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear at build time.

### 8. Review Output Artifacts
Confirm that the build output in the `bin/Release` folder contains the expected assemblies and that the application runs correctly:

```bash
dotnet run --configuration Release
```

Or for a published output:

```bash
dotnet publish --configuration Release --output ./publish
```

Then execute the published output directly to validate the final deployable state.