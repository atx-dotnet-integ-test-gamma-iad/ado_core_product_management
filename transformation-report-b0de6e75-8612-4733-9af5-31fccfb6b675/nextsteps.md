# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no hidden warnings or errors:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests that previously passed may indicate a behavioral difference introduced by the migration.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for APIs that are Windows-only or otherwise platform-restricted. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Look for diagnostics prefixed with `CA1416` which flag platform-specific API calls.

### 6. Run the Application
Execute the application on each target platform (Windows, Linux, macOS as applicable) to confirm runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Verify that connection strings, file paths, and any environment-specific configuration are correctly handled for each platform.

### 7. Review Configuration Files
Check `appsettings.json` or any other configuration files to ensure:
- File path separators use `Path.Combine` or forward slashes rather than hardcoded backslashes.
- Any registry-based configuration has been replaced with a cross-platform alternative.

### 8. Publish the Application
Once validation is complete, produce a published output to confirm the final artifact is correct:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present.