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

Check the output for any warnings that may indicate compatibility concerns even if they are not hard errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to scan for any APIs that are present but throw `PlatformNotSupportedException` at runtime on non-Windows systems:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to areas such as:
- `System.Drawing` (requires `libgdiplus` on Linux/macOS or replacement with `SkiaSharp`/`ImageSharp`)
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or COM calls

### 6. Validate Configuration and App Settings
Confirm that any `App.config` or `Web.config` files have been migrated to `appsettings.json` or equivalent .NET configuration patterns. The legacy XML-based configuration system is not fully supported in cross-platform .NET.

### 7. Run on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) and verify that file paths, line endings, culture-sensitive operations, and environment variables behave as expected.

### 8. Publish the Application
Once validation is complete, produce a published output to confirm the deployment artifact is correct:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required assets, configuration files, and dependencies are present.