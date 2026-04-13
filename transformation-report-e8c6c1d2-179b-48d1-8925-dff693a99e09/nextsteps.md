# Next Steps

The solution appears to have transformed successfully — no build errors were reported across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, reflection, or threading).

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to identify any API usage that compiles but behaves differently at runtime:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Web` usages (not available on cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- `BinaryFormatter` (disabled by default in .NET 5+)
- `AppDomain` APIs with limited support

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and verify that all referenced NuGet packages have versions that support the target framework. You can check compatibility on [nuget.org](https://www.nuget.org) or by inspecting the `lib` folders of the packages in the local NuGet cache.

Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform .NET support.

### 6. Validate Configuration Files
If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration model. The legacy XML-based configuration system has limited support in cross-platform .NET.

### 7. Test on Target Operating Systems
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build on a single OS.

```bash
dotnet run --configuration Release
```

### 8. Publish and Verify Output
Perform a test publish to confirm the output is complete and runnable:

```bash
dotnet publish --configuration Release --output ./publish
```

Navigate to the `./publish` directory and run the output directly to verify the application starts and behaves as expected.