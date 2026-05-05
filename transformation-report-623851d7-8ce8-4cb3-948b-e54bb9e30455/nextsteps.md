# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages.

### 3. Build the Solution
Perform a full build to confirm there are no errors in the transformed state:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Platform-Specific API Usage
Even without build errors, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Upgrade Assistant compatibility analyzer or the following command to surface these warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- COM interop usage
- Windows-specific file path assumptions

### 6. Review `AdoCore.csproj` Specifically
Since `AdoCore` appears to be the most foundational project in this solution, manually inspect its `.csproj` for the following:
- Removal of any legacy `<Reference>` entries pointing to GAC assemblies
- Correct replacement of any `packages.config` dependencies with `<PackageReference>` entries
- No remaining `<HintPath>` entries pointing to local or legacy assembly paths

### 7. Smoke Test Core Functionality
Execute the application manually or through integration tests against a known dataset to confirm that the core ADO-related functionality (connections, commands, data reading) behaves as expected under the new runtime.

### 8. Deployment
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm the output runs correctly on the target platform before promoting it to a production environment.