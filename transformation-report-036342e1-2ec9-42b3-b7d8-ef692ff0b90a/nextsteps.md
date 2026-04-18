# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully, paying attention to any tests that are skipped or that produce unexpected results.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining calls to Windows-only APIs. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Look for diagnostics prefixed with `CA1416` (platform compatibility), which flag APIs that are not available on all platforms.

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) to confirm runtime behavior is consistent. Pay particular attention to:

- File path separators (`/` vs `\`)
- Environment variable access
- Registry access (Windows-only; must be abstracted or removed for cross-platform support)
- Any use of `System.Windows.Forms` or `System.Drawing` that may require additional compatibility packages

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages in use have versions that support the target .NET version. Visit [nuget.org](https://www.nuget.org) and verify the supported frameworks listed for each package.

### 8. Publish a Release Build
Once validation is complete, produce a self-contained or framework-dependent publish to confirm the output is as expected:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target. Review the published output directory to ensure all required assets are present.