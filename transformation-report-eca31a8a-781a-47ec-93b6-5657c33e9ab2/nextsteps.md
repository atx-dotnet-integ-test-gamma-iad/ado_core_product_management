# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only frameworks unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the absence of errors and review any warnings:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test output for any failures or skipped tests that may indicate platform-specific behavior that no longer applies.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls (e.g., registry access, `System.Windows.Forms`, COM interop) that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.Windows.Compatibility --version <latest>
```

If cross-platform support is required, replace or abstract any platform-specific APIs accordingly.

### 6. Run the Application
Execute the application directly to verify runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all primary workflows and confirm output matches expected behavior from the legacy version.

### 7. Verify NuGet Package Compatibility
Review the packages listed in each `.csproj` file and confirm that all referenced NuGet packages have versions that support the target framework. The NuGet package page for each dependency will list supported frameworks under the **Frameworks** tab.

### 8. Review Output Artifacts
Check the `bin/Release` output directory to confirm the expected assemblies, dependencies, and any required assets are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` folder to ensure all required files are included before distribution.