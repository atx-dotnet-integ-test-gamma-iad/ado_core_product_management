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
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Removed or Changed APIs
Some .NET Framework APIs are not available or behave differently in cross-platform .NET. Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to scan for API usage that may fail at runtime even if it compiles successfully:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

### 5. Review NuGet Package Versions
Open each `.csproj` and verify that all NuGet package references are pointing to versions that support your target framework. Run:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that previously targeted only .NET Framework.

### 6. Validate Platform-Specific Behavior
If the original project used any of the following, manual testing on each target platform (Windows, Linux, macOS) is recommended:

- File path handling (`\` vs `/`)
- Registry access (not available on Linux/macOS)
- Windows-specific APIs such as `System.Drawing`, WCF, or WPF
- COM interop or P/Invoke calls

### 7. Publish and Smoke Test
Publish the application to a local folder and run it to confirm it executes correctly outside of the development environment:

```bash
dotnet publish --configuration Release --output ./publish
cd ./publish
dotnet AdoCore.dll
```

Verify the application starts and core functionality operates as expected.

### 8. Review Output Artifacts
Confirm that the published output does not include unexpected `.exe` wrappers or leftover `.config` files from the legacy .NET Framework build that are no longer applicable.