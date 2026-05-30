# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that could indicate latent issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral regressions introduced during the migration.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the built-in platform compatibility analyzers to identify any remaining calls to Windows-only or framework-only APIs. You can enable the analyzer by ensuring the following is present in each `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild after adding these properties and review any new diagnostics.

### 6. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File path separators
- Environment variable access
- Registry access (Windows-only; must be replaced or guarded)
- Any use of `System.Windows.Forms` or `System.Drawing` which may require additional packages on non-Windows platforms

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages support the target framework. Visit [nuget.org](https://www.nuget.org) or use the following command to audit packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update or replace any packages that do not have a compatible version for your target framework.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required assets are present.