# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies in each `.csproj` file. Confirm that every package has a version compatible with the target framework. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Replace any packages that have known compatibility issues with their recommended cross-platform equivalents.

### 5. Review Removed or Changed APIs
Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` analyzer to identify any API calls that may compile successfully but behave differently at runtime on non-Windows platforms.

Pay particular attention to:
- `System.Drawing` (replaced by cross-platform alternatives such as `SkiaSharp` or `ImageSharp`)
- Windows Registry access (`Microsoft.Win32.Registry`)
- Platform-specific file path assumptions (use `Path.Combine` and `Path.DirectorySeparatorChar`)
- `System.Runtime.InteropServices` P/Invoke calls targeting Windows-only native libraries

### 6. Run on Target Platforms
If cross-platform support is a goal, execute the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime errors that would not appear during compilation.

```bash
dotnet run --configuration Release
```

### 7. Publish a Self-Contained or Framework-Dependent Build
Once validation passes, produce a release build artifact:

```bash
# Framework-dependent
dotnet publish -c Release -o ./publish

# Self-contained for a specific runtime
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish-linux
```

Verify the published output runs correctly in the target environment before distributing it.