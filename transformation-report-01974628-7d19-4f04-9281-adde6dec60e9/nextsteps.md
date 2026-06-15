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
Perform a full build to confirm the error-free state is consistent across all configurations:

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

### 5. Check for Runtime-Only Issues
Some issues do not surface at build time. Manually exercise the core functionality of the application and watch for:

- `PlatformNotSupportedException` — APIs that exist but are not supported on the current OS.
- `TypeLoadException` or `MissingMethodException` — APIs that were removed in modern .NET.
- Differences in `System.Configuration` usage if the project previously relied on `app.config` or `web.config`.

### 6. Review Removed or Changed APIs
Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to surface any API usage that may behave differently at runtime on Linux or macOS if cross-platform support is a goal.

### 7. Validate Output Artifacts
Confirm the build output is placed in the expected location and that all required assets (configuration files, static resources, etc.) are being copied correctly:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all necessary files are present.

### 8. Smoke Test the Published Output
Run the published output directly to confirm the application starts and operates correctly outside of the development environment:

```bash
dotnet ./publish/AdoCore.dll
```

Adjust the entry point name as appropriate for your project.