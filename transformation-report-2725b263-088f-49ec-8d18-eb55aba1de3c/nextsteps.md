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
If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review test results carefully. A successful build does not guarantee correct runtime behavior, especially after a framework migration.

### 4. Check for Removed or Changed APIs
Some .NET Framework APIs are not available or behave differently in cross-platform .NET. Review the Microsoft API compatibility documentation and run the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to surface any potential runtime incompatibilities that do not produce build errors.

### 5. Review NuGet Package Versions
Open each `.csproj` and verify that all NuGet package references are targeting versions compatible with your target framework. Outdated packages may have been carried over from the legacy project. Run:

```bash
dotnet list package --outdated
```

Update packages where appropriate, testing after each update.

### 6. Validate Platform-Specific Code
Search the codebase for any usage of Windows-specific APIs such as the registry, `System.Drawing`, WCF, or `System.Windows.Forms`. These may compile successfully with compatibility shims but will fail at runtime on non-Windows platforms. Address these by either replacing them with cross-platform alternatives or adding runtime platform guards.

### 7. Test on Target Platforms
If cross-platform support is a goal, run and test the application on each intended operating system (e.g., Linux, macOS) to catch any platform-specific runtime failures.

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the output directory to confirm all expected files are present before deploying.