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
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to their current equivalents.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that could indicate latent issues:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they reflect regressions introduced during the transformation or pre-existing issues.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining Windows-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Alternatively, audit usages of namespaces such as `System.Windows.Forms`, `Microsoft.Win32`, or `System.Drawing` which may have limited cross-platform support.

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior. Pay particular attention to:

- File path separators
- Environment variable access
- Registry access (Windows-only)
- Culture and encoding assumptions

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages support the target framework. Visit [nuget.org](https://www.nuget.org) for each dependency and confirm the listed supported frameworks include your target.

## Deployment

### 1. Publish a Self-Contained or Framework-Dependent Build
To produce a deployable output, run:

```bash
# Framework-dependent (requires .NET runtime installed on target machine)
dotnet publish --configuration Release

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --self-contained true --runtime linux-x64
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed.

### 2. Verify Published Output
Navigate to the `publish` output directory and confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.