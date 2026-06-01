# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any APIs that may have been available in .NET Framework but behave differently or are unavailable in cross-platform .NET. Pay particular attention to:

- `System.Windows.Forms` or `System.Web` references, which are not cross-platform
- Registry access (`Microsoft.Win32.Registry`)
- File path assumptions (backslash vs. forward slash)
- `AppDomain` usage

### 6. Run the Application on a Non-Windows Platform
If cross-platform support is a goal, run the application on Linux or macOS to surface any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

### 7. Review NuGet Package Versions
Check that all referenced NuGet packages have versions compatible with the target framework. Replace any packages that have known cross-platform alternatives, for example:

- Replace `System.Drawing.Common` (Windows-only after .NET 6) with `SkiaSharp` or `ImageSharp` if image processing is required.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier to match your deployment target (e.g., `win-x64`, `osx-x64`, `linux-x64`).