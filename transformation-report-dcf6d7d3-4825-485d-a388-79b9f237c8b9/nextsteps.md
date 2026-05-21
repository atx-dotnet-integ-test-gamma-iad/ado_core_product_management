# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless a multi-targeting scenario is intentional.

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

Check the output for any warnings that may indicate compatibility issues even if they do not produce hard errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Runtime-Only Issues
Some issues do not surface at compile time. Pay attention to the following areas during manual or automated testing:

- **File paths**: Ensure no hardcoded Windows-style paths (e.g., `C:\`) exist in the codebase.
- **Registry access**: Any use of `Microsoft.Win32.Registry` will not function on Linux or macOS.
- **Windows-specific APIs**: APIs such as `System.Drawing` (GDI+) or certain `System.Security` features may behave differently or require additional NuGet packages (e.g., `System.Drawing.Common`).
- **Globalization**: .NET on Linux uses ICU by default. If the application relies on specific culture or encoding behavior, test those code paths explicitly.
- **Case-sensitive file systems**: Linux file systems are case-sensitive. Verify that all file and directory references use consistent casing.

### 6. Review Removed or Changed APIs
Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs that were available in .NET Framework but are absent or changed in cross-platform .NET.

### 7. Publish the Application
Once testing is complete, publish the application for the target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier (`linux-x64`, `win-x64`, `osx-x64`, etc.) and `--self-contained` flag to match your deployment requirements. Review the publish output directory to confirm all expected assets are present.