# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no hidden build issues:

```bash
dotnet build --configuration Release
```

Review all warnings in the output. Warnings related to nullable reference types, obsolete APIs, or platform compatibility should be addressed even if they do not block the build.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether they are caused by behavioral differences between .NET Framework and modern .NET (e.g., changes in `HttpClient`, `Thread.Abort`, serialization defaults, or globalization behavior).

### 5. Check for Platform Compatibility Warnings
Install and run the .NET Compatibility Analyzer if not already active:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

This will surface any API calls that are not supported on non-Windows platforms if cross-platform support is a goal.

### 6. Review Runtime Behavior
Manually exercise the core workflows of the application, paying attention to the following areas that commonly differ between .NET Framework and modern .NET:

- **Globalization and encoding**: Modern .NET uses ICU by default instead of NLS on non-Windows systems.
- **JSON serialization**: If the project used `Newtonsoft.Json` and has been migrated to `System.Text.Json`, verify serialization and deserialization output is equivalent.
- **Configuration**: Confirm `app.config` or `web.config` based configuration has been replaced or is being read correctly via `Microsoft.Extensions.Configuration`.
- **WCF or Remoting**: If any WCF service references or .NET Remoting usage exists, confirm replacements are functioning correctly.

### 7. Publish the Application
Once validation is complete, publish the application to confirm the output is correct:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required assemblies and assets are present.

### 8. Smoke Test the Published Output
Run the published output directly rather than through `dotnet run` to catch any issues with self-contained deployment or missing runtime dependencies:

```bash
./publish/AdoCore
```

Or on Windows:

```bash
.\publish\AdoCore.exe
```