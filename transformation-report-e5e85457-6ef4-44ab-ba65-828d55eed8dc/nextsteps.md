# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to supported versions.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that could indicate hidden issues:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and the new .NET runtime.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for APIs that are Windows-only. These will typically be annotated with `[SupportedOSPlatform("windows")]`. If cross-platform support is required, these usages will need to be replaced or conditionally compiled.

You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

to surface platform compatibility diagnostics.

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS as applicable) to confirm there are no platform-specific runtime issues that do not surface at compile time.

```bash
dotnet run --configuration Release
```

### 7. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (e.g., `win-x64`, `osx-x64`) based on your deployment target. Review the output directory to confirm all required files are present.

### 8. Review NuGet Package Versions
Confirm that all third-party NuGet packages in use have versions that support the target .NET version. Check the package pages on [nuget.org](https://www.nuget.org) if there is any uncertainty.