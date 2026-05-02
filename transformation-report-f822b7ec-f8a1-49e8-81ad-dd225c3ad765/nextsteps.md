# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that could not be resolved.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run Existing Tests
If the solution contains test projects, execute the test suite to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences introduced by the migration.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for any APIs that were available in .NET Framework but are not available or behave differently in cross-platform .NET. Pay particular attention to:

- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions
- COM interop usage

You can also run the following to surface compatibility warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

### 6. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS as applicable) and verify that the core functionality behaves as expected. Do not rely solely on a successful build as confirmation of correctness.

### 7. Review NuGet Package Versions
Check that all NuGet packages referenced in the `.csproj` files have versions that are compatible with the target .NET version. Visit [nuget.org](https://www.nuget.org) to confirm compatibility if needed.

### 8. Deployment
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

If targeting a specific runtime, include the runtime identifier, for example:

```bash
dotnet publish --configuration Release -r win-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.