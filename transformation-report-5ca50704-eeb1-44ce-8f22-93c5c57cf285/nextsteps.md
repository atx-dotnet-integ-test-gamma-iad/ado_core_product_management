# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:
```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies are resolved cleanly:
```bash
dotnet restore
```
Review the output for any warnings about deprecated or unlisted packages and consider updating them.

### 3. Build the Solution
Perform a full build to confirm there are no issues:
```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:
```bash
dotnet test --configuration Release
```
Review the test output and address any failing tests before proceeding.

### 5. Review Removed or Replaced APIs
Check the codebase for any APIs that were available in .NET Framework but have changed behavior (not just signature) in cross-platform .NET. Common areas to review include:
- `System.Configuration` usage (replaced by `Microsoft.Extensions.Configuration`)
- `System.Web` usage (not available on cross-platform .NET)
- Registry access (`Microsoft.Win32.Registry`) — only functional on Windows
- `AppDomain` usage — some members are no longer supported
- File path assumptions that rely on Windows-style separators (`\`)

### 6. Verify Platform-Specific Behavior
If the application was originally Windows-only, run it on the target platform(s) and confirm that features such as file I/O, networking, and any interop calls behave as expected.

### 7. Check for Remaining `packages.config` Files
Ensure no legacy `packages.config` files remain in the solution. All package references should now use the `<PackageReference>` format inside `.csproj` files.

### 8. Review Output Artifacts
Confirm that the build output is placed in the expected location and that all necessary assets (configuration files, static resources, etc.) are copied correctly:
```bash
dotnet publish --configuration Release --output ./publish
```
Inspect the `./publish` directory to verify the output is complete.

### 9. Smoke Test the Application
Run the published output directly and perform a basic functional walkthrough of the application to confirm it starts and operates correctly end-to-end.