# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility concerns even if they are not hard errors.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in `System.Drawing`, `AppDomain`, reflection behavior, or culture handling).

### 5. Review Removed or Replaced APIs
Check the code for any uses of APIs that were replaced with compatibility shims during transformation. Common areas to review include:

- `System.Web` usages replaced by `Microsoft.AspNetCore`
- `BinaryFormatter` (removed in .NET 9, deprecated in .NET 5+)
- `System.Drawing.Common` (platform-specific behavior on non-Windows)
- `Registry` and other Windows-specific APIs under `Microsoft.Win32`

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to surface any remaining concerns:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

### 6. Test on Target Platforms
If cross-platform support (Linux, macOS) is a goal, run the application and its tests on those operating systems to surface any platform-specific runtime issues that do not appear at compile time.

### 7. Review Configuration and App Settings
Confirm that any `App.config` or `Web.config` files have been properly migrated to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`. Legacy XML-based configuration is not natively supported in cross-platform .NET.

### 8. Validate Output Artifacts
Run the application directly to confirm expected runtime behavior:

```bash
dotnet run --project <YourStartupProject>.csproj --configuration Release
```

For library projects, confirm the generated `.dll` and any accompanying assets are correct by inspecting the `bin/Release` output directory.