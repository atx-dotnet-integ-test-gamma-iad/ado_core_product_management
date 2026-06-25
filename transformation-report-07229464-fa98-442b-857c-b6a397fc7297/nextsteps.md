# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless a multi-targeting scenario is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that may have been masked:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee that runtime behavior is identical to the original .NET Framework version.

### 5. Check for Windows-Specific API Usage
Even without build errors, certain APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usages of:
- `System.Windows.Forms` or `System.Drawing` (without the `-windows` TFM suffix)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific P/Invoke calls

If any are found and cross-platform support is required, replace them with cross-platform alternatives or conditionally compile them using runtime checks.

### 6. Validate Configuration Files
Check that any `App.config` or `Web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. Legacy config files are not processed the same way in modern .NET.

### 7. Review Removed or Changed APIs
Consult the [.NET Upgrade Assistant compatibility report](https://learn.microsoft.com/en-us/dotnet/core/porting/) or the `.upgrade-assistant` log files (if present) to review any APIs that were flagged during transformation. Even if they compiled, some may require manual remediation.

### 8. Smoke Test the Application
Run the application manually and exercise its primary workflows to confirm runtime behavior matches expectations:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Pay particular attention to:
- Database connectivity (especially if using ADO.NET, as connection string formats or provider registrations may differ)
- File I/O paths (use `Path.Combine` and avoid hardcoded backslashes)
- Any reflection-based code that may behave differently under .NET's trimming or AOT scenarios

### 9. Publish the Application
Once validation is complete, publish the application for the target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the output directory to confirm all required assets, configuration files, and dependencies are present before deploying.