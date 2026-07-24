# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. The solution compiles without issues.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to deprecated packages or incompatible target frameworks.

### 2. Build the Solution

Perform a full build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences introduced by the migration even when the build succeeds.

### 4. Review Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the runtime environment where the application will be deployed.

### 5. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently in cross-platform .NET compared to .NET Framework. Pay particular attention to:

- **File system paths**: Ensure no hardcoded Windows-style paths (e.g., backslashes) exist in the code.
- **Registry access**: `Microsoft.Win32.Registry` is not available on Linux/macOS.
- **Windows-specific libraries**: Any P/Invoke calls or references to Windows-only DLLs will fail on non-Windows platforms.
- **Configuration**: `System.Configuration.ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package in cross-platform .NET.
- **Thread culture and globalization**: Behavior may differ; verify `CultureInfo` usage.

### 6. Run the Application

Execute the application directly and exercise its primary workflows to confirm runtime correctness:

```bash
dotnet run --project ado_core_product_management/AdoCore.csproj --configuration Release
```

### 7. Publish the Application

Once validation is complete, publish the application for the target platform:

**Framework-dependent (requires .NET runtime on target machine):**
```bash
dotnet publish ado_core_product_management/AdoCore.csproj --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish ado_core_product_management/AdoCore.csproj --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (e.g., `win-x64`, `osx-x64`, `osx-arm64`) based on your deployment target.

### 8. Verify Published Output

Navigate to the publish output directory and confirm the expected binaries and assets are present before deploying to the target environment.