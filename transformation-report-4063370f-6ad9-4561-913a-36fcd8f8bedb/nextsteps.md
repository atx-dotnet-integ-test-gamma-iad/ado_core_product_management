# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:
```xml
<TargetFramework>net8.0</TargetFramework>
```
Ensure no projects are still referencing `net4x` or `netstandard` targets unless that is intentional.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:
```bash
dotnet restore
dotnet build --configuration Release
```
Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:
```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```
Review any failing tests carefully, as they may indicate behavioral differences between the old .NET Framework runtime and the new cross-platform .NET runtime.

### 4. Check for Removed or Changed APIs
Even with a clean build, some APIs behave differently on cross-platform .NET. Pay particular attention to:
- `System.Configuration` usage — `ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on .NET Core/.NET 5+.
- `System.Drawing` — requires the `System.Drawing.Common` NuGet package and has platform restrictions on non-Windows systems.
- Windows Registry access (`Microsoft.Win32.Registry`) — only functional on Windows.
- `AppDomain`, `Remoting`, and `Reflection.Emit` APIs — some members are no longer supported or throw `PlatformNotSupportedException`.

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and inspect all `<PackageReference>` entries. Verify that each package version supports your target framework by checking [NuGet.org](https://www.nuget.org). Replace any packages that only support `net4x` with their cross-platform equivalents.

### 6. Validate Platform-Specific Behavior
If the application is intended to run on Linux or macOS, test it explicitly on those platforms. File path separators, environment variable names, and case-sensitive file systems can introduce runtime issues that do not appear on Windows.

### 7. Review Output and Publish Profile
When ready to publish, run:
```bash
dotnet publish --configuration Release --output ./publish
```
Confirm the output directory contains all expected assemblies and that no required files (such as configuration files or native dependencies) are missing.

### 8. Smoke Test the Published Output
Navigate to the publish output directory and run the application directly:
```bash
cd ./publish
dotnet AdoCore.dll
```
Perform a basic functional walkthrough to confirm the application starts and core functionality behaves as expected.