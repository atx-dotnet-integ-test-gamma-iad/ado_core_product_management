# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `net472`, or any other legacy .NET Framework moniker unless explicitly required.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly `NU1701` warnings, which indicate packages were restored for a different framework and may not be fully compatible.

### 4. Run the Test Suite
If the solution contains test projects, execute all tests to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, reflection, or threading).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any APIs that may compile successfully but are not supported on non-Windows platforms at runtime. Pay particular attention to:

- `System.Drawing` (GDI+ dependent)
- `Microsoft.Win32` registry access
- Windows Communication Foundation (WCF) server-side APIs
- `System.Security.Permissions` attributes

### 6. Validate Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where applicable, and that the application reads them correctly at runtime.

### 7. Smoke Test the Application
Run the application manually in a development environment and exercise the primary workflows to confirm there are no runtime exceptions that were not caught by the test suite.

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 8. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.