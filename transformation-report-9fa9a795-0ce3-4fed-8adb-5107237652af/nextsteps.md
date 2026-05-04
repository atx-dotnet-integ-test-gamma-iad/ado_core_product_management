# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that may indicate latent issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review test output carefully, particularly for any tests that exercise platform-specific behavior such as file paths, registry access, or Windows-only APIs.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the built-in platform compatibility analyzer to identify any remaining calls to Windows-only APIs (e.g., `System.Windows.Forms`, `Microsoft.Win32.Registry`, COM interop). These will compile but will throw `PlatformNotSupportedException` at runtime on non-Windows systems.

You can enable the analyzer by ensuring this is present in your `.csproj`:

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisMode>All</AnalysisMode>
</PropertyGroup>
```

### 6. Validate Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (Windows, Linux, macOS) and verify:

- File I/O paths use `Path.Combine` and are not hardcoded with backslashes.
- Configuration files load correctly.
- Any external process calls or native library references resolve on the target OS.

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages support the target framework. Visit [nuget.org](https://www.nuget.org) for each dependency and confirm `.NET 6`, `.NET 7`, or `.NET 8` (whichever applies) is listed under supported frameworks. Replace any packages that only support .NET Framework with their modern equivalents.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Adjust the `--runtime` identifier (`win-x64`, `osx-x64`, `linux-arm64`, etc.) to match your deployment target. Review the publish output directory to confirm all required assets are present.