# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that could indicate latent issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior, especially after a framework migration.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining Windows-specific API calls that may compile but fail at runtime on Linux or macOS:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Only add this package if Windows-specific APIs are required and cross-platform support is not needed for those code paths.

### 6. Review Configuration and App Settings
Confirm that any `App.config` or `Web.config` files have been migrated to `appsettings.json` where applicable, and that configuration is loaded using `Microsoft.Extensions.Configuration`.

### 7. Validate Output Artifacts
After a successful Release build, inspect the output directory:

```bash
dotnet publish --configuration Release --output ./publish
```

Confirm the published output contains the expected assemblies and that the entry point executes correctly on the target platform:

```bash
dotnet ./publish/AdoCore.dll
```

### 8. Smoke Test Core Functionality
Manually exercise the primary workflows of the application to confirm that behavior matches the pre-migration baseline. Pay particular attention to:

- Database connections and queries
- File I/O operations
- Any interop or reflection-based code
- Serialization and deserialization logic