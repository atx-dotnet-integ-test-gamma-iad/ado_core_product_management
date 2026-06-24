# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if the build succeeds.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Removed or Changed APIs
Even with a clean build, some APIs that existed in .NET Framework may behave differently or have been replaced in cross-platform .NET. Review the [.NET Upgrade Assistant compatibility analyzer results](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or run the compatibility analyzer manually:

```bash
dotnet add package Microsoft.DotNet.UpgradeAssistant.Extensions.Default.Analyzers
dotnet build
```

Pay particular attention to:
- `System.Web` usages (not available on cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WinForms, WPF) if cross-platform support is required
- `BinaryFormatter` usage, which is disabled by default in .NET 5+

### 5. Review NuGet Package Versions
Open the `.csproj` files and confirm all NuGet packages reference versions compatible with the target framework. Run:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that previously targeted .NET Framework only.

### 6. Verify Runtime Behavior
Execute the application manually or through its entry point and exercise the primary workflows. Confirm that:
- Configuration files (e.g., `appsettings.json` vs. `app.config`) are being read correctly
- Connection strings and environment-specific settings resolve as expected
- Any file I/O paths use `Path.Combine` and are not hardcoded with Windows-style separators

### 7. Publish a Release Build
Once the above steps pass, produce a published output to confirm the final artifact is correct:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all required files, assemblies, and configuration files are present.