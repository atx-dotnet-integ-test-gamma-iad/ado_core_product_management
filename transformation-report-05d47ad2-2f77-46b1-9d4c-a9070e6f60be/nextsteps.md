# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore NuGet Packages
Run the following command from the solution root to confirm all dependencies resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved dependencies.

### 3. Build the Solution
Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate latent issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior.

### 5. Check for Removed or Changed APIs
Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tools to scan for any API usage that may compile but behave differently on cross-platform .NET compared to .NET Framework.

Pay particular attention to:
- `System.Drawing` (requires `System.Drawing.Common` and has platform restrictions on non-Windows)
- `System.Web` (not available on cross-platform .NET)
- Windows Registry access
- COM interop

### 6. Validate Runtime Behavior on Target Platforms
Run the application on each intended target operating system (e.g., Linux, macOS, Windows) to surface any platform-specific issues that would not appear at compile time.

```bash
dotnet run --configuration Release
```

### 7. Review Configuration and File Paths
Confirm that any file paths, directory separators, and configuration file references use `Path.Combine` or `Path.DirectorySeparatorChar` rather than hardcoded backslashes, which will cause failures on non-Windows systems.

### 8. Publish the Application
Once the above steps are completed and the application behaves correctly, publish it for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`. Review the contents of the publish output directory to confirm all required assets are present.