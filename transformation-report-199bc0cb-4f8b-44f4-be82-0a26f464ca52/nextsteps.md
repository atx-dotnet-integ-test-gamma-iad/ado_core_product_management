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

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output for any failures or skipped tests that may indicate platform-specific behavior that no longer applies.

### 5. Check for Windows-Specific API Usage
Even without build errors, the code may reference APIs that are Windows-only. Use the .NET Compatibility Analyzer to surface these at build time by adding the following property to each `.csproj` file:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild and review any `CA1416` platform compatibility warnings.

### 6. Verify Runtime Behavior
Run the application on each intended target platform (Windows, Linux, macOS) to confirm it behaves correctly at runtime. Pay particular attention to:

- File path separators (`/` vs `\`)
- Environment variable access
- Registry access (Windows-only)
- Any use of `System.Drawing` or other packages that may require native dependencies on non-Windows platforms

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages in use have versions that support the target framework. Visit [nuget.org](https://www.nuget.org) for each package and confirm `.NET` or `.NET Standard` compatible versions are referenced.

### 8. Deployment
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --runtime <target-rid> --self-contained false
```

Replace `<target-rid>` with the appropriate Runtime Identifier for your target platform, for example:
- `win-x64`
- `linux-x64`
- `osx-x64`

Review the contents of the publish output folder to confirm all required assemblies and configuration files are present before deploying to the target environment.