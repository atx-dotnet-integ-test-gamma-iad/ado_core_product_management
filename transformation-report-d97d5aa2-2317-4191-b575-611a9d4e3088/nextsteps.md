# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review test results and investigate any failures, as compilation success does not guarantee correct runtime behavior.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies in each `.csproj` file. Confirm that every package has a version compatible with the target .NET version. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that do not support the target framework.

### 5. Review Removed or Changed APIs
Cross-platform .NET removes certain APIs that existed in .NET Framework. Run the .NET Upgrade Assistant compatibility analyzer or the Platform Compatibility Analyzer to surface any API usage that may fail at runtime:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

Pay particular attention to:
- `System.Web` usages
- Windows-specific APIs (registry, WCF, remoting)
- `AppDomain` and reflection-based patterns

### 6. Validate Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables as appropriate for the new hosting model.

### 7. Smoke Test Core Functionality
Run the application manually and exercise the primary workflows to confirm end-to-end behavior is consistent with the original .NET Framework version. Compare outputs, logs, and any data produced against known baselines if available.

### 8. Review Platform-Specific Code Paths
Search the codebase for any conditional compilation symbols such as `#if NETFRAMEWORK` or `#if WINDOWS` to ensure the cross-platform code paths are correct and complete.

```bash
grep -rn "NETFRAMEWORK\|WINDOWS" --include="*.cs"
```

### 9. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application starts correctly from that output.