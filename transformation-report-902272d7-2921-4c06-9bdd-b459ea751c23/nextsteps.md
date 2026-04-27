# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues even if the build succeeds.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and the new .NET runtime.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that may have been removed or changed. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Pay attention to any `CA1416` (platform compatibility) warnings, which indicate APIs that are Windows-only and may not behave correctly on Linux or macOS.

### 6. Validate Runtime Behavior
Run the application and exercise its primary workflows manually or through integration tests. Pay particular attention to:

- File path handling, since .NET on Linux/macOS uses `/` as a separator rather than `\`.
- Any configuration files (e.g., `app.config`) that may need to be migrated to `appsettings.json` or another supported format.
- Reflection-based code, which may behave differently under the new runtime.

### 7. Review Removed or Changed APIs
Cross-reference any usages of the following commonly removed APIs against the official Microsoft migration documentation:

- `System.Web` (not available outside of ASP.NET Framework)
- `BinaryFormatter` (disabled by default in .NET 5+)
- `AppDomain.CreateDomain`
- Windows Registry APIs (Windows-only)

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --runtime <target-rid> --self-contained false
```

Replace `<target-rid>` with the appropriate Runtime Identifier, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the publish output directory to confirm all expected assets are present before deploying.