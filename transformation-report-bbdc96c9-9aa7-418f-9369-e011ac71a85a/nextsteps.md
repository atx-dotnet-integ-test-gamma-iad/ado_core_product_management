# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated package versions targeting older frameworks.

### 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while non-blocking, may indicate compatibility concerns worth addressing.

### 3. Review Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the runtime environment where the application will be deployed.

### 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework APIs and their cross-platform equivalents.

### 5. Check for Runtime-Only Issues

Some issues do not surface at compile time. Specifically, review the following areas manually:

- **Reflection-based code**: Behavior can differ between .NET Framework and modern .NET.
- **Windows-specific APIs**: Any use of APIs such as the registry, WCF, or `System.Drawing` may require additional NuGet packages (e.g., `System.Drawing.Common`) or replacement libraries.
- **Configuration**: If the project previously used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or the appropriate modern equivalent.
- **File paths**: Ensure no hardcoded Windows-style paths exist that would break on Linux or macOS.

### 6. Validate Output Artifacts

After a successful build, inspect the output directory (typically `bin/Release/net8.0/`) to confirm all expected assemblies, configuration files, and dependencies are present.

### 7. Run the Application

Execute the application directly to perform a basic smoke test:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Observe the output and logs for any runtime exceptions or unexpected behavior.

### 8. Review Removed APIs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to scan for any API usage that is present in .NET Framework but absent or changed in modern .NET, even if it currently compiles without error.