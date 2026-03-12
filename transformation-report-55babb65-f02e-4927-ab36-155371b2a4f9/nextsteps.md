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
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the no-error state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check both `Debug` and `Release` configurations to rule out configuration-specific issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral differences introduced by the migration.

### 5. Check for Removed or Changed APIs
Even with a clean build, some .NET Framework APIs behave differently or have been removed in cross-platform .NET. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to surface any runtime-only concerns:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

Pay particular attention to:
- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific registry or file path assumptions
- `AppDomain` and remoting APIs
- `BinaryFormatter` usage, which is disabled by default

### 6. Validate Platform-Specific Behavior
If the application was previously Windows-only, run it on the target platform (Linux or macOS if applicable) and exercise the main code paths to confirm no platform-specific runtime exceptions occur.

### 7. Review NuGet Package Compatibility
Open the NuGet package manager or inspect each `.csproj` and confirm that all referenced packages have versions that support the new target framework. Packages that only support `net4x` may have been included without error at build time but will fail at runtime.

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --runtime <target-rid> --self-contained false
```

Replace `<target-rid>` with the appropriate Runtime Identifier, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the publish output directory to confirm all expected assemblies and assets are present before deploying.