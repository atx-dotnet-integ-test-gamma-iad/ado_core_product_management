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

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no issues beyond what was captured in the initial error report:

```bash
dotnet build --configuration Release
```

Review all warnings in addition to errors, as some warnings may indicate compatibility issues that could cause runtime problems.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and the new .NET runtime.

### 5. Check for Windows-Specific API Usage
Even if the project builds successfully, it may contain APIs that are Windows-only and will fail at runtime on other platforms. Use the .NET Compatibility Analyzer to identify these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the build output for `CA1416` platform compatibility warnings, which are emitted by the built-in platform compatibility analyzer in .NET 5+.

### 6. Review `App.config` / `Web.config` Usage
.NET does not use `App.config` or `Web.config` in the same way as .NET Framework. If the project relied on these files, migrate the relevant configuration to `appsettings.json` or environment variables using `Microsoft.Extensions.Configuration`.

### 7. Validate Runtime Behavior
Run the application manually and exercise the primary workflows to confirm that behavior matches the original .NET Framework version. Pay particular attention to:

- Serialization and deserialization logic
- File path handling (use `Path.Combine` and avoid hardcoded backslashes)
- Culture-sensitive string operations
- Reflection-based code, which may behave differently under .NET's trimming or AOT scenarios

### 8. Review Removed or Changed APIs
Cross-reference any usages of APIs that were removed or had behavioral changes in .NET. The official Microsoft migration guide is a useful reference:

[https://learn.microsoft.com/en-us/dotnet/core/compatibility/](https://learn.microsoft.com/en-us/dotnet/core/compatibility/)

### 9. Publish the Application
Once validation is complete, publish the application for the target platform:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your deployment target (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all required assets are present.