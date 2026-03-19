# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm the absence of errors is consistent:

```bash
dotnet build --configuration Release
```

Review any warnings that appear, as some warnings may indicate compatibility concerns that do not block the build but could cause runtime issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully, paying attention to any tests that were previously passing under .NET Framework but may now fail due to behavioral differences in cross-platform .NET.

### 5. Check for Windows-Specific API Usage
Even when a project builds successfully, it may contain APIs that only function on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the build output for `CA1416` platform compatibility warnings, which indicate APIs that are not supported on all platforms.

### 6. Review `app.config` and `web.config` Usage
.NET no longer uses `app.config` or `web.config` in the same way as .NET Framework. If the project relied on these files for configuration, migrate the relevant settings to `appsettings.json` and use `Microsoft.Extensions.Configuration` for access.

### 7. Validate Runtime Behavior
Run the application manually and exercise its primary workflows. Pay particular attention to:

- File path handling, since .NET on Linux and macOS uses case-sensitive paths.
- Reflection-based code, which may behave differently under .NET's trimming and AOT considerations.
- Any use of `System.Runtime.Remoting`, `System.Web`, or `System.Drawing` on non-Windows platforms, as these namespaces are either removed or have limited cross-platform support.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your deployment target. Review the publish output directory to confirm all required assets are present.