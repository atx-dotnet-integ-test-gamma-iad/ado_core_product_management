# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional.

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

Check both `Debug` and `Release` configurations if the project has configuration-specific code paths.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral differences between the old and new runtimes.

### 5. Audit Removed APIs
Cross-platform .NET removes certain Windows-specific and legacy APIs. Run the .NET Compatibility Analyzer to surface any calls that may compile but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, use the **upgrade-assistant** analyze command if it is still available in your environment:

```bash
upgrade-assistant analyze <solution>.sln
```

### 6. Check for Platform-Specific Code
Search the codebase for any remaining usage of:
- `System.Windows.Forms` or `System.Web` namespaces
- P/Invoke calls targeting Windows-only DLLs (e.g., `kernel32.dll`, `user32.dll`)
- Registry access via `Microsoft.Win32.Registry`

If these are required, confirm that the relevant platform-specific NuGet packages have been added and that runtime platform guards (`RuntimeInformation.IsOSPlatform`) are in place where necessary.

### 7. Validate Configuration Files
Confirm that any `app.config` or `web.config` files have been migrated to `appsettings.json` where applicable, and that the application reads configuration through `Microsoft.Extensions.Configuration`.

### 8. Smoke Test the Application
Run the application locally and exercise the primary workflows to confirm end-to-end behavior matches the pre-migration baseline:

```bash
dotnet run --project src/AdoCore/AdoCore.csproj --configuration Release
```

Compare outputs, logs, and any database or file artifacts against known-good results from the legacy version.

### 9. Review Warnings
Even with zero errors, the build may have produced warnings. Review them with:

```bash
dotnet build --configuration Release 2>&1 | grep -i warning
```

Address any warnings related to nullable reference types, obsolete API usage, or package compatibility, as these can indicate latent issues.