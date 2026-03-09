# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not block compilation.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check for Removed or Incompatible APIs
Even with a clean build, some APIs that existed in .NET Framework may have changed behavior in cross-platform .NET. Review the [.NET Upgrade Assistant compatibility analyzer output](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or run the compatibility analyzer manually:

```bash
dotnet add package Microsoft.DotNet.UpgradeAssistant.Extensions.Default.Analyzers
dotnet build
```

Pay particular attention to:
- `System.Configuration` usage (replaced by `Microsoft.Extensions.Configuration`)
- `System.Web` usage (not available outside of ASP.NET Core)
- Windows-specific APIs (registry, COM interop, WCF client/server)
- Any `AppDomain`, reflection, or serialization patterns that behave differently

### 5. Review NuGet Package Versions
Open each `.csproj` and confirm all `<PackageReference>` entries reference versions that are compatible with the target .NET version. Run:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any outdated or vulnerable packages as appropriate.

### 6. Validate Configuration Files
If the project previously used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or environment-based configuration where applicable. Verify that connection strings, logging settings, and application settings are all loading correctly at runtime.

### 7. Perform Runtime Smoke Testing
Run the application locally and exercise the primary workflows to confirm runtime behavior is correct. Pay attention to:
- File path handling (use `Path.Combine` and avoid hardcoded backslashes)
- Case sensitivity on file systems (Linux/macOS are case-sensitive)
- Any platform-specific code paths that may not execute on non-Windows systems

### 8. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier:

**Framework-dependent (requires .NET runtime installed on target machine):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) for your target environment.

### 9. Verify Published Output
Navigate to the `./publish` directory and confirm all expected files are present, including configuration files, static assets, and any native dependencies. Run the published output directly to confirm it starts and operates correctly outside of the development environment.