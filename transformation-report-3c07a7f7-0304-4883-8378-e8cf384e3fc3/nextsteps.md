# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. The project `AdoCore.csproj` compiled without issues.

## Validation

### 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or platform-specific code that may cause runtime issues.

### 3. Run the Test Suite

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

### 4. Check for Platform-Specific Code

Even without build errors, runtime issues can arise from platform-specific APIs that were valid in .NET Framework but behave differently or are unavailable in cross-platform .NET. Review the codebase for usage of:

- `System.Web` namespaces
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` features not supported in .NET Core+
- COM interop or P/Invoke calls targeting Windows-only libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility concerns.

### 5. Review NuGet Package Versions

Confirm that all NuGet dependencies reference versions compatible with the target framework. Run:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable releases compatible with your target framework.

### 6. Test on Target Platforms

Since the goal is cross-platform support, run the application on each intended platform (Windows, Linux, macOS) to catch any platform-specific runtime behavior:

```bash
dotnet run --configuration Release
```

### 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate for your deployment target:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish/linux-x64
```

**Self-contained (example for Windows x64):**
```bash
dotnet publish -c Release -r win-x64 --self-contained true -o ./publish/win-x64
```

Review the contents of the output directory to confirm all required assets and dependencies are present before deploying.