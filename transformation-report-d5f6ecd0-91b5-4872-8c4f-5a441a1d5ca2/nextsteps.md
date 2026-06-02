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
Perform a full build to confirm there are no errors or warnings that were not surfaced previously:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET.

### 5. Check for Windows-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any APIs that are Windows-only. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay attention to diagnostics prefixed with `CA1416`, which flag platform-specific API calls.

### 6. Verify Runtime Behavior
Run the application manually and exercise its primary workflows. Confirm that:

- File paths use `Path.Combine` and are not hardcoded with backslashes.
- Any configuration files (e.g., `app.config`) have been migrated to `appsettings.json` or equivalent if needed.
- Registry access, COM interop, or other Windows-specific features have been accounted for.

### 7. Review Removed or Changed APIs
Cross-reference the project against the [.NET Compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to confirm that any APIs used from .NET Framework that were removed or changed in cross-platform .NET have been properly replaced.

### 8. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify it runs correctly on the target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` flag to match your intended deployment target (e.g., `win-x64`, `osx-x64`).