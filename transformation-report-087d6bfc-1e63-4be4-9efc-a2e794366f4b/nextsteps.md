# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only target frameworks unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Review any warnings that surface during the build, as some may indicate compatibility concerns that did not produce hard errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test results carefully, particularly for any tests that exercise platform-specific functionality such as file paths, registry access, or Windows APIs.

### 5. Check for Platform-Specific API Usage
Even without build errors, the code may reference APIs that exist in .NET but behave differently across platforms, or APIs that are marked with `[SupportedOSPlatform]` attributes. Run a static analysis pass:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Address any `CA1416` (platform compatibility) warnings that appear.

### 6. Verify Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (Windows, Linux, macOS) and confirm core functionality behaves as expected. Pay particular attention to:

- File system path separators
- Line ending handling
- Culture and encoding defaults
- Any use of `System.Drawing` or other packages with platform-specific native dependencies

### 7. Review Removed or Changed APIs
Cross-reference the code against the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/net-framework-tech-unavailable) documentation to confirm that no APIs in use have been silently replaced with cross-platform alternatives that carry different behavior.

### 8. Publish the Application
Once validation is complete, publish the application for your target runtime(s):

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

Adjust the `--runtime` identifier to match your deployment targets. Review the publish output directory to confirm all required assets are present.