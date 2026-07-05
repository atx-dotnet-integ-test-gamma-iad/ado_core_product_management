# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

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

Review all test results and investigate any failures.

### 4. Check for Removed or Changed APIs
Some .NET Framework APIs are not available in cross-platform .NET. Run the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tool to surface any runtime-level API usage that may not have produced build errors but could fail at runtime.

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

### 5. Review NuGet Package Versions
Open each `.csproj` and verify that all NuGet packages reference versions that support the target framework. You can check compatibility on [nuget.org](https://www.nuget.org). Update any outdated packages:

```bash
dotnet list package --outdated
```

Then update as appropriate:

```bash
dotnet add package <PackageName> --version <NewVersion>
```

### 6. Validate Platform-Specific Code
Search the codebase for any usage of Windows-specific APIs such as the registry, `System.Windows.Forms`, `System.Drawing`, or COM interop. These may compile but will throw `PlatformNotSupportedException` at runtime on non-Windows platforms.

```bash
grep -rn "Microsoft.Win32\|System.Windows.Forms\|System.Drawing\|System.Runtime.InteropServices.Marshal" --include="*.cs"
```

If such APIs are found and cross-platform support is required, replace them with cross-platform alternatives.

### 7. Test on Target Platforms
If the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that static analysis may not surface.

### 8. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate RID (e.g., `win-x64`, `osx-x64`) as needed. Review the contents of the `publish` output directory to confirm all required assets are present before deploying.