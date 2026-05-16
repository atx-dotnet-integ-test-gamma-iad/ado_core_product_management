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
Run a full solution build to confirm the clean state holds outside of the transformation environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly `NU1701` (package targeting warnings) or `CS0618` (obsolete API usage), as these can indicate compatibility concerns.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures at this stage may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, reflection, or threading).

### 5. Check for Windows-Specific API Usage
Even without build errors, the code may reference APIs that only function correctly on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usages of `System.Windows.Forms`, `System.Drawing`, `Microsoft.Win32.Registry`, or P/Invoke calls that target Windows-only system libraries.

### 6. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or the appropriate .NET configuration model. The legacy XML configuration system is not fully supported in cross-platform .NET.

### 7. Validate Runtime Behavior
Run the application on the target platform (Linux, macOS, or Windows as appropriate) and exercise the primary workflows. Pay particular attention to:

- File path handling (`Path.Combine` vs. hardcoded separators)
- Culture and encoding assumptions
- Reflection-based code that may behave differently under .NET's updated type system

### 8. Review Removed APIs
Cross-reference the codebase against the [.NET Upgrade Assistant compatibility report](https://learn.microsoft.com/en-us/dotnet/core/porting/) or the [.NET API Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/api-analyzer) to identify any APIs that were available in .NET Framework but have been removed or changed in behavior in modern .NET.

## Deployment

Once validation is complete:

1. Publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

2. If a self-contained deployment is required (no .NET runtime pre-installed on the target machine), use:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your target environment.

3. Verify the contents of the `./publish` directory and confirm all required assets, configuration files, and dependencies are present before deploying to the target environment.