# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate latent issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate runtime behavioral differences between .NET Framework and modern .NET rather than compilation issues.

### 5. Check for Windows-Specific API Usage
Even without build errors, the code may reference APIs that are Windows-only (e.g., registry access, `System.Drawing`, WinForms, certain `System.Security` APIs). Run the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review analyzer warnings in your IDE after building. APIs flagged with `[SupportedOSPlatform("windows")]` will not function on Linux or macOS.

### 6. Verify Runtime Behavior on Target Platforms
If cross-platform execution is a goal, run the application on each intended operating system (Windows, Linux, macOS) and confirm expected behavior. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity of the file system
- Platform-specific environment variables
- Any P/Invoke or interop calls

### 7. Review `AdoCore.csproj` Specifically
Since `AdoCore` appears to be a core dependency in this solution, manually inspect its `.csproj` for the following:

- Removal of any `<HintPath>` references pointing to GAC or Windows-specific assemblies
- Replacement of any `packages.config` style references with `<PackageReference>` items
- Correct SDK-style project format header: `<Project Sdk="Microsoft.NET.Sdk">`

### 8. Check Configuration and App Settings
If the project uses `App.config` or `Web.config`, confirm these have been migrated to `appsettings.json` or equivalent .NET configuration providers, as `System.Configuration.ConfigurationManager` has limited support and behavior differences on non-Windows platforms.