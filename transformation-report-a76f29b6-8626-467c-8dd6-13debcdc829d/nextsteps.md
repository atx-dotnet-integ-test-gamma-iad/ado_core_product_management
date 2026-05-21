# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that were not surfaced previously:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that existing behavior has been preserved after the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests may indicate behavioral differences between .NET Framework and cross-platform .NET that need to be addressed.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows-only APIs such as those in `System.Drawing` (requires the `System.Drawing.Common` package and may have platform restrictions)
- `AppDomain` usage
- Remoting or binary serialization

### 6. Review Configuration Files
Confirm that any `App.config` or `Web.config` files have been migrated to the appropriate `appsettings.json` format or that the `System.Configuration.ConfigurationManager` NuGet package has been added if the legacy configuration approach is still required.

### 7. Run the Application
Execute the application directly to confirm it starts and operates as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test the primary workflows of the application to verify runtime behavior matches expectations.

### 8. Verify Output Artifacts
Check that the published output is correct by running:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to confirm all expected assemblies, configuration files, and assets are present.