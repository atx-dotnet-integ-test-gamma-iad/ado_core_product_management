# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Removed or Changed APIs
Even without build errors, some APIs behave differently or have been removed in modern .NET. Review the [.NET Upgrade Assistant compatibility analyzer output](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or run the following to surface compatibility warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisLevel=latest
```

Pay particular attention to:
- `System.Web` usages (not available in .NET Core+)
- Windows-only APIs if cross-platform support is required
- Any `#pragma warning disable` suppressions that may be hiding real issues

### 5. Review NuGet Package Versions
Confirm all NuGet dependencies are up to date and compatible with the target framework:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any vulnerable or outdated packages and rebuild.

### 6. Validate Platform-Specific Behavior
If the original project used Windows-specific features (e.g., registry access, COM interop, Windows services), test on both Windows and the intended cross-platform environment (Linux/macOS) to confirm correct behavior or that appropriate guards are in place.

### 7. Publish a Release Build
Once validation passes, produce a published output to confirm the application packages correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required assets, configuration files, and dependencies are present.

### 8. Smoke Test the Published Output
Run the published application directly from the output directory to catch any runtime issues that do not surface at build time:

```bash
cd ./publish
dotnet AdoCore.dll
```

Verify the application starts and core functionality operates as expected.