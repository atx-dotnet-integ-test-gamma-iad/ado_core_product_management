# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless a multi-targeting scenario is intentional.

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
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs that were available in .NET Framework but behave differently or are absent in cross-platform .NET:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <YourSolution>.sln
```

Review the generated report and address any flagged compatibility issues.

### 5. Review NuGet Package Versions
Open each `.csproj` file and verify that all `<PackageReference>` entries reference versions that support the target framework. Check [nuget.org](https://www.nuget.org) for each package if there is any uncertainty.

### 6. Validate Platform-Specific Code
Search the codebase for any usage of Windows-specific APIs such as:
- `System.Windows.Forms`
- `Microsoft.Win32` registry access
- COM interop
- `System.Drawing` (GDI+)

If any are found, either replace them with cross-platform alternatives or add a Windows-specific runtime guard using `RuntimeInformation.IsOSPlatform(OSPlatform.Windows)`.

### 7. Smoke Test the Application
Run the application manually and exercise the primary workflows to confirm expected behavior at runtime:

```bash
dotnet run --project src/AdoCore/AdoCore.csproj --configuration Release
```

### 8. Publish a Release Build
Once the above steps are completed without issue, produce a published output to verify the final deployable artifact:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to confirm all expected assemblies and assets are present, then deploy the contents to the target environment.