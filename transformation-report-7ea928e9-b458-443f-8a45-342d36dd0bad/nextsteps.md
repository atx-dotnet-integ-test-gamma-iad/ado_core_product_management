# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other outdated monikers unless intentionally targeting them.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them in the relevant `.csproj` files.

### 3. Build the Solution
Perform a full solution build to confirm there are no errors or warnings that were not captured previously:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output for any failures and trace them back to code changes introduced during the transformation.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-specific API calls that may compile successfully but fail at runtime on Linux or macOS:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Address any `CA1416` platform compatibility warnings surfaced by the analyzer.

### 6. Verify Runtime Behavior
Run the application directly and exercise its primary workflows:

```bash
dotnet run --project AdoCore --configuration Release
```

Compare the output and behavior against the known baseline from the legacy project.

### 7. Review Removed or Changed References
Check that any references that were previously resolved via the GAC (e.g., `System.Web`, `System.Drawing`) have been replaced with their NuGet equivalents where necessary, such as:

- `System.Drawing.Common` for GDI+ types
- `Microsoft.AspNetCore.*` for web-related functionality

### 8. Inspect Output Artifacts
Confirm the build output is placed in the expected directory and that all required assets, configuration files, and dependencies are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` folder to ensure completeness before any further distribution.