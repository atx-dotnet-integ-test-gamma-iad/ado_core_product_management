# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:
```xml
<TargetFramework>net8.0</TargetFramework>
```
Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:
```bash
dotnet restore
dotnet build --configuration Release
```
Review the output for any warnings that may indicate deprecated APIs or compatibility concerns even if they are not hard errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET.

### 4. Check for Removed or Changed APIs
Even with a clean build, some APIs behave differently on modern .NET. Review the Microsoft documentation for [breaking changes in .NET](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) relevant to the version you are targeting. Pay particular attention to:
- `System.Configuration` usage (replaced by `Microsoft.Extensions.Configuration`)
- `System.Web` usage (not available on modern .NET)
- Remoting or `AppDomain` APIs
- Binary serialization (`BinaryFormatter` is disabled by default)

### 5. Audit NuGet Package Compatibility
Run the following to check for outdated or potentially incompatible packages:
```bash
dotnet list package --outdated
dotnet list package --deprecated
```
Update any packages that have newer versions compatible with your target framework.

### 6. Review `AdoCore.csproj` Specifically
Since `AdoCore` is listed as the most independent (and therefore most foundational) project in the solution, manually inspect its `.csproj` to confirm:
- All project references resolve correctly
- No legacy `<HintPath>` references point to GAC or Windows-only assemblies
- Any ADO.NET-related packages (e.g., database drivers) are updated to their cross-platform compatible versions

### 7. Test on Target Platform
If cross-platform support is a goal, run the build and tests on the intended non-Windows platform (Linux or macOS) to surface any platform-specific issues:
```bash
dotnet build --configuration Release
dotnet test --configuration Release
```
Look for issues related to file path separators, case-sensitive file systems, or Windows-only interop calls.

### 8. Validate Runtime Behavior
Beyond unit tests, perform integration or smoke testing against real data sources and dependencies to confirm end-to-end functionality is intact after the migration.