# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the root of the solution to confirm a clean restore and build:

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

Address any failing tests before proceeding.

### 4. Check for Platform-Specific API Usage
Even without build errors, some APIs may have been silently replaced or may behave differently on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for platform-specific calls:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Drawing` usage
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (backslashes, drive letters)
- COM interop or P/Invoke calls

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and check each `<PackageReference>`. Confirm that every package listed supports the target framework. You can verify this on [nuget.org](https://www.nuget.org) or by inspecting the package's supported frameworks. Replace any packages that do not support the new target framework with maintained alternatives.

### 6. Validate Configuration Files
If the project previously relied on `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration provider, as `System.Configuration.ConfigurationManager` behavior differs in cross-platform .NET.

### 7. Smoke Test on Target Platforms
Run the application on each platform you intend to support (e.g., Linux, macOS, Windows) to catch any runtime-only issues:

```bash
dotnet run --configuration Release
```

### 8. Publish the Application
Once validation is complete, publish a self-contained or framework-dependent build as appropriate:

```bash
# Framework-dependent
dotnet publish -c Release -o ./publish

# Self-contained for a specific runtime
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish/linux-x64
```

Verify the output in the `./publish` directory runs correctly on the target machine.