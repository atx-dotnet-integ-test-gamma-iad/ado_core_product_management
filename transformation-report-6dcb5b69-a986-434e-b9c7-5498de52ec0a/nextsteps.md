# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `net472`, or any other legacy .NET Framework moniker unless that is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies in each `.csproj` file. Confirm that every package version supports the target .NET version. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions compatible with your target framework.

### 5. Review Removed or Changed APIs
Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any API calls that existed in .NET Framework but behave differently or are absent in cross-platform .NET. Pay particular attention to:

- `System.Web` usages (not available in .NET Core/.NET 5+)
- `AppDomain` APIs with limited support
- Windows-specific registry or COM interop calls
- `BinaryFormatter` (deprecated and disabled by default)

### 6. Validate Platform-Specific Behavior
If the application previously ran only on Windows, test it on the target platform (Linux or macOS if applicable) to surface any platform-specific runtime issues such as file path casing, line endings, or missing native dependencies.

### 7. Check Configuration and App Settings
Confirm that any `App.config` or `Web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. Verify that connection strings, environment-specific settings, and logging configuration are all functioning correctly at runtime.

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required files and dependencies are present. If a self-contained deployment is needed, add the runtime identifier:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target environment (e.g., `linux-x64`, `osx-x64`).