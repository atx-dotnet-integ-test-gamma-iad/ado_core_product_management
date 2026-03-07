# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

### 4. Check for Platform-Specific API Usage
Even when a project compiles successfully, it may contain APIs that are Windows-specific and will fail at runtime on other platforms. Use the .NET Compatibility Analyzer to surface these:

- Ensure the `Microsoft.DotNet.Analyzers.Compatibility` or the built-in platform compatibility analyzers are active.
- Look for warnings such as `CA1416: This call site is reachable on all platforms`.
- Replace or conditionally guard any Windows-only APIs (e.g., registry access, certain `System.Drawing` calls, WinForms/WPF components).

### 5. Review NuGet Package Compatibility
Check that all NuGet dependencies support the target framework:

```bash
dotnet list package --outdated
```

For any packages flagged as outdated or incompatible, update them to versions that explicitly support your target framework. Pay particular attention to packages that previously relied on `net45`/`net48` targets.

### 6. Validate Configuration and App Settings
If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent mechanisms appropriate for cross-platform .NET. The `System.Configuration.ConfigurationManager` package can be used as a compatibility shim if a full migration is not yet feasible.

### 7. Runtime Smoke Test
Run the application locally on your development machine and exercise the primary workflows to confirm basic runtime correctness:

```bash
dotnet run --project src/AdoCore/AdoCore.csproj --configuration Release
```

If the project is a library, write or run a small console harness that exercises its public API surface.

### 8. Test on a Non-Windows Platform (if applicable)
If cross-platform support is a goal, run the application or tests on Linux or macOS to confirm there are no hidden platform dependencies:

```bash
dotnet test --configuration Release
```

This can be done on a secondary machine or within a local Linux/macOS environment.

### 9. Publish a Self-Contained Build
Produce a self-contained publish artifact to verify the output is complete and runnable without a pre-installed .NET runtime:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 -o ./publish
```

Adjust the `--runtime` identifier (`win-x64`, `osx-x64`, `linux-x64`, etc.) to match your deployment target.