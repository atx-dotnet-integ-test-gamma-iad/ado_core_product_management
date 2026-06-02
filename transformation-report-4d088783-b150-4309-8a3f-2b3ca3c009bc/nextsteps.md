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
Run a full build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues that did not surface as hard errors.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., changes in globalization, reflection, or threading behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are present but marked with `[SupportedOSPlatform]` attributes or that throw `PlatformNotSupportedException` at runtime on non-Windows systems:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Only add this package if Windows-specific APIs are required and the deployment target is Windows. Otherwise, replace those APIs with cross-platform equivalents.

### 6. Validate Runtime Behavior
Execute the application on each target operating system (Windows, Linux, macOS) that is part of your deployment requirement. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Registry access (not available on Linux/macOS)
- Windows-specific libraries such as `System.Drawing.Common` (restricted on non-Windows in .NET 6+)

### 7. Review NuGet Package Compatibility
Run the following to check for outdated or non-compatible packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any packages flagged as vulnerable or incompatible with the target framework.

### 8. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify it runs correctly in the target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target (e.g., `win-x64`, `osx-x64`).