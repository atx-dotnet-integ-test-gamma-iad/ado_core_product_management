# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility (`CA1416`), as these can indicate runtime issues on non-Windows platforms.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., changes in globalization, reflection, or threading behavior).

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer to identify any APIs that are Windows-only. Run a build with the analyzer active by ensuring the project targets a non-Windows RID or by inspecting analyzer warnings prefixed with `CA1416`. Common problem areas include:

- `System.Drawing` (requires `libgdiplus` on Linux/macOS or the `System.Drawing.Common` compatibility package)
- Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side APIs
- `System.Security.Permissions` and related CAS APIs

### 6. Validate Runtime Behavior on Target Platforms
Run the application on each intended target platform (Linux, macOS, Windows) to catch any platform-specific runtime exceptions that static analysis may not surface. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case-sensitive file systems on Linux
- Environment variable differences across operating systems

### 7. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or another supported configuration mechanism, as `System.Configuration.ConfigurationManager` has limited support and behavior differences in cross-platform .NET.

### 8. Inspect Output Artifacts
After a successful Release build, inspect the output directory:

```bash
dotnet publish --configuration Release --output ./publish
```

Confirm that all expected assemblies, configuration files, and static assets are present in the publish output before deploying.