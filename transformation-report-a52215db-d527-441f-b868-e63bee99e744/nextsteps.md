# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

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

Address any failing tests before proceeding further.

### 4. Check for Removed or Changed APIs
Even with a clean build, some APIs behave differently on cross-platform .NET compared to .NET Framework. Review the code for usage of the following common problem areas:

- `System.Web` — not available on .NET Core/.NET 5+
- `AppDomain` — partially supported
- `BinaryFormatter` — removed in .NET 9, obsolete in earlier versions
- Windows Registry APIs — only functional on Windows
- `System.Drawing` — requires the `System.Drawing.Common` NuGet package and has platform restrictions

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining compatibility concerns.

### 5. Review NuGet Package Versions
Open the `.csproj` files and verify all NuGet packages reference versions that support your target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where necessary, being cautious of breaking changes between major versions.

### 6. Validate Platform-Specific Behavior
If the application is expected to run on non-Windows platforms, test it explicitly on Linux or macOS. Some APIs that compile successfully are guarded at runtime by platform checks. Use `RuntimeInformation.IsOSPlatform()` where platform-specific code paths are required.

### 7. Publish the Application
Once the build and tests are confirmed clean, produce a release publish:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all expected assemblies and assets are present.

### 8. Smoke Test the Published Output
Run the published output directly to verify the application starts and behaves correctly in its published form:

```bash
dotnet ./publish/AdoCore.dll
```

Adjust the entry point name as appropriate for your solution.