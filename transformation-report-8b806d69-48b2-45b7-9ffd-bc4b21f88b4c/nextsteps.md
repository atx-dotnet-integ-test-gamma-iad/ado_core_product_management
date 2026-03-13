# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

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

Address any failing tests before proceeding further.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies in each `.csproj` file. Confirm that every package has a version compatible with the target .NET version. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that do not support the current target framework.

### 5. Review Removed or Changed APIs
Run the .NET Upgrade Assistant compatibility analyzer or the `ApiPort` tool to identify any API usage that was available in .NET Framework but is absent or behaves differently in cross-platform .NET:

```bash
dotnet tool install -g dotnet-apiport
apiport analyze -f ./
```

Pay particular attention to areas such as:
- `System.Web` usage (not available in cross-platform .NET)
- Windows Registry access
- Windows-specific interop or `PInvoke` calls
- `AppDomain` usage
- Remoting APIs

### 6. Validate Runtime Behavior on Target Platforms
If cross-platform support (Linux, macOS) is a goal, run the application on each intended platform and verify that file paths, line endings, culture-sensitive operations, and any OS-specific logic behave as expected.

### 7. Review Configuration and Resource Files
Confirm that any configuration files (e.g., `app.config`, `web.config`) have been migrated to the appropriate format, typically `appsettings.json` combined with `Microsoft.Extensions.Configuration`. Legacy `.config` files are not processed automatically in cross-platform .NET.

### 8. Publish the Application
Once validation is complete, publish the application using the desired runtime identifier:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (`win-x64`, `osx-x64`, etc.). Review the publish output directory to confirm all required assets are present.