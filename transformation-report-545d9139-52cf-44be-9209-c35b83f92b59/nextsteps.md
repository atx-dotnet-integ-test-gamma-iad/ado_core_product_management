# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the clean state holds outside of the transformation environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility analyzers (`CA1416`), as these can indicate runtime issues on specific operating systems.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that behavior has not changed during transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may point to behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Windows-Specific API Usage
Run the .NET Compatibility Analyzer by ensuring the following property is set in each `.csproj` where applicable:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<TargetPlatformMinVersion>...</TargetPlatformMinVersion>
```

Look for `CA1416` warnings in the build output, which flag APIs that are only supported on specific platforms such as Windows. These will not cause build errors but can cause runtime failures on Linux or macOS.

### 6. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) if cross-platform execution is a requirement. Pay particular attention to:

- File system path separators (`\` vs `/`)
- Case sensitivity in file paths on Linux
- Registry access or Windows-specific configuration sources
- `System.Drawing` or other packages that may require native dependencies on non-Windows systems

### 7. Review `App.config` / `Web.config` Migration
If the original project used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or another supported configuration provider, as `System.Configuration.ConfigurationManager` has limited support in cross-platform .NET.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier and `--self-contained` flag based on your deployment requirements. Review the publish output directory to confirm all required assets are present.