# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues even if they do not block the build.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are present but throw `PlatformNotSupportedException` at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

Alternatively, run the application on each target platform (Linux, macOS, Windows) to surface any runtime issues.

### 6. Review Removed or Replaced APIs
Cross-reference any usages of the following commonly problematic areas that may compile but behave differently:

- `System.Configuration.ConfigurationManager` — requires the `System.Configuration.ConfigurationManager` NuGet package on .NET Core/.NET 5+.
- `System.Drawing` — requires the `System.Drawing.Common` package and may have OS-level dependencies.
- Windows Registry access — not available on non-Windows platforms.
- `AppDomain.CreateDomain` — not supported on .NET Core and later.

### 7. Run the Application and Perform Smoke Testing
Execute the application manually and walk through the primary workflows to confirm functional correctness:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Compare the output and behavior against the known baseline from the original .NET Framework version.

### 8. Review Output Artifacts
Confirm the published output contains the expected files and structure:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all required assets, configuration files, and dependencies are present.