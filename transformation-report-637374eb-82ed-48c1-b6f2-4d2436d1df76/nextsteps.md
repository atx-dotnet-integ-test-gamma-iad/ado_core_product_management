# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the no-error state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check both `Debug` and `Release` configurations.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral differences between the old and new runtimes.

### 5. Audit Removed Windows-Specific APIs
Search the codebase for APIs that are available on .NET but are Windows-only and decorated with `[SupportedOSPlatform("windows")]`. These will compile successfully but will throw `PlatformNotSupportedException` at runtime on non-Windows systems. Common areas to check:

- `System.Drawing` (GDI+)
- `Microsoft.Win32.Registry`
- `System.Windows.Forms` or `System.Web` references
- COM interop calls

### 6. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration provider. Verify that connection strings, app settings, and custom configuration sections are all accessible at runtime.

### 7. Validate Third-Party Package Compatibility
For each NuGet package in the solution, confirm it has a version compatible with the target framework. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Replace any packages that do not support the target framework with their modern equivalents or supported alternatives.

### 8. Smoke Test Core Functionality
Run the application manually and exercise the primary workflows to confirm end-to-end behavior matches the legacy version. Pay particular attention to:

- File I/O paths (path separators differ on Linux/macOS)
- Culture and encoding defaults (these changed between .NET Framework and .NET)
- Reflection-based code, which may behave differently under the new runtime