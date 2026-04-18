# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting multiple frameworks.

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

Address any failing tests before proceeding further.

### 4. Check for Removed or Changed APIs
Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to identify any APIs that were available in the legacy framework but have been removed or changed in the target .NET version.

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and review all `<PackageReference>` entries. For each package:
- Confirm the version supports the target framework.
- Check [NuGet.org](https://www.nuget.org) for newer stable versions if the current version is outdated.
- Replace any packages that have known cross-platform incompatibilities with their recommended alternatives.

### 6. Validate Platform-Specific Code
Search the codebase for any usage of Windows-specific APIs (e.g., `System.Windows.Forms`, `Microsoft.Win32`, registry access, or COM interop) that may compile but fail at runtime on non-Windows platforms:

```bash
grep -rn "Microsoft.Win32\|Registry\|System.Windows.Forms\|[DllImport]" --include="*.cs"
```

Replace or conditionally compile these sections using runtime checks:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific logic
}
```

### 7. Test on Target Platforms
If cross-platform support is a goal, run and test the application on each intended operating system (Linux, macOS, Windows) to surface any platform-specific runtime issues that would not appear during compilation.

### 8. Publish a Release Build
Once testing is satisfactory, produce a published output to verify the final artifact:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all expected files are present and the application runs correctly from the published location.