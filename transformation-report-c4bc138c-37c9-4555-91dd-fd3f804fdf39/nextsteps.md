# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other legacy/EOL frameworks unless intentionally kept for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a full build to confirm the clean state holds outside of the initial transformation:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly `CS0618` (obsolete API usage) or platform compatibility warnings (`CA1416`), as these may indicate areas that require attention for cross-platform correctness.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may point to behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Text.Encoding`, `HttpClient`, threading, or reflection behavior).

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the `Microsoft.DotNet.Analyzers.Compatibility` tooling to identify any remaining Windows-only API calls if cross-platform execution is a goal:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to usages of `System.Drawing`, `Microsoft.Win32`, `RegistryKey`, or any P/Invoke calls.

### 6. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that settings have been properly migrated to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`.

### 7. Verify Output Artifacts
After a successful Release build, inspect the output directory (`bin/Release/net8.0/`) to confirm:
- The expected assemblies are present.
- No unintended dependencies on platform-specific runtimes exist unless a self-contained publish is intended.

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific platform:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Or for a framework-dependent deployment:

```bash
dotnet publish --configuration Release --self-contained false --output ./publish
```

Review the contents of the `./publish` folder and confirm all required runtime files and configuration files are present before deploying to the target environment.