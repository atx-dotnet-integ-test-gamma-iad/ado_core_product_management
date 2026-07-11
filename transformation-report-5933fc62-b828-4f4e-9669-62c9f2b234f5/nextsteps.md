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
Perform a full build to confirm there are no warnings that may indicate compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers (`CA1416`).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral regressions introduced during the migration.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to identify any remaining calls to Windows-only APIs. Pay particular attention to:

- `System.Windows.Forms` or `System.Drawing` usage
- Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls targeting Windows libraries

### 6. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent .NET configuration providers where appropriate.

### 7. Validate Runtime Behavior
Run the application locally on each target platform (Windows, Linux, macOS) if cross-platform execution is a goal. Confirm that file paths, line endings, and environment-specific behavior work as expected on non-Windows systems.

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate RID, such as `win-x64`, `linux-x64`, or `osx-x64`. Review the publish output directory to confirm all required assets are present before deployment.