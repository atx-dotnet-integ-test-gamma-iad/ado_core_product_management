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
Run the following commands from the root of the solution to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to identify any APIs that were available in .NET Framework but have changed behavior or been removed in cross-platform .NET. Pay particular attention to:

- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- `AppDomain` and remoting APIs

### 5. Review NuGet Package Versions
Open the `.csproj` files and verify that all NuGet package references are pointing to versions compatible with your target framework. Run:

```bash
dotnet list package --outdated
```

Update packages where appropriate, and check for any packages that have cross-platform replacements.

### 6. Validate Platform-Specific Behavior
If the application uses any platform-specific features (file paths, line endings, encoding defaults, etc.), test the application on each intended target operating system (Windows, Linux, macOS) to confirm consistent behavior.

### 7. Run the Application
Execute the application directly to perform a basic smoke test:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Confirm that the application starts without runtime exceptions and behaves as expected.

### 8. Publish a Self-Contained or Framework-Dependent Build
Once the above steps pass, produce a publish output to verify the final deployable artifact:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish-linux
```

Inspect the output directory to confirm all expected files are present.

### 9. Review Output for Nullable and Other Warnings
If `<Nullable>enable</Nullable>` or `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>` are set in the project files, review and resolve any nullable reference warnings, as these can surface latent null-reference issues at runtime if left unaddressed.