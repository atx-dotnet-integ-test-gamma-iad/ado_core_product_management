# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:
```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies are restored cleanly:
```bash
dotnet restore
```
Review the output for any warnings about deprecated or unlisted packages.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that may have been missed:
```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:
```bash
dotnet test --configuration Release
```
Review test output for any failures or skipped tests that may indicate behavioral differences between the old and new target frameworks.

### 5. Review Removed or Replaced APIs
Check the code for any APIs that were available in .NET Framework but have changed behavior (not just signature) in cross-platform .NET. Common areas to review include:
- `System.Configuration` usage (replaced by `Microsoft.Extensions.Configuration`)
- `System.Web` usage (not available on cross-platform .NET)
- Windows-specific registry or file path assumptions
- `AppDomain` usage, which has partial support

### 6. Run the Application
Execute the application directly to observe runtime behavior:
```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```
Test all major code paths, particularly any database access, file I/O, or network calls, as these are common sources of cross-platform issues.

### 7. Verify Database Connectivity
Given the project name `AdoCore` suggests ADO.NET usage, confirm the following:
- Connection strings are correctly configured for the new environment.
- The appropriate database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of `System.Data.SqlClient` if applicable).
- Any provider-specific behavior differences have been accounted for.

### 8. Check for Platform-Specific Code
Search the codebase for any conditional compilation symbols or runtime platform checks that may have been relevant to the old .NET Framework target but are no longer necessary or accurate:
```csharp
#if NET48
// legacy code
#endif
```
Remove or update these blocks as appropriate.

### 9. Review Output Artifacts
Confirm that the build output directory contains the expected assemblies and that no required files (such as configuration files or native binaries) are missing from the output.