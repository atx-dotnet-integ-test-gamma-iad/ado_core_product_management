# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the absence of errors is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check both `Debug` and `Release` configurations to rule out configuration-specific issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral regressions introduced during the migration.

### 5. Check for Windows-Specific API Usage
Even without build errors, the code may still contain Windows-specific APIs that will fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually or with a tool such as the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) to identify calls to APIs guarded by the `[SupportedOSPlatform("windows")]` attribute.

### 6. Validate Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (e.g., Linux, macOS, Windows) and confirm that all features behave as expected. Pay particular attention to:

- File path handling (`Path.Combine` vs. hardcoded separators)
- Registry access (Windows-only)
- `System.Drawing` usage (requires `libgdiplus` on Linux or replacement with a cross-platform library)
- P/Invoke calls to native libraries

### 7. Review Output Artifacts
Confirm the build output in the `bin/Release` folder contains the expected assemblies and that no legacy `.config` files or `app.manifest` files are causing unintended behavior.

### 8. Publish a Self-Contained Build
To verify the project is fully portable, attempt a self-contained publish targeting a specific runtime identifier:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Repeat for any other runtime identifiers relevant to your deployment targets (e.g., `win-x64`, `osx-x64`).