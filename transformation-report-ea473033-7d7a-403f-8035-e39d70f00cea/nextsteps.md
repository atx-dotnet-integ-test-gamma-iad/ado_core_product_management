# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

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

Address any failing tests before proceeding further.

### 4. Audit NuGet Package Compatibility
Check that all NuGet packages referenced in each `.csproj` are compatible with the target .NET version. You can use the following command to identify outdated or vulnerable packages:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Replace or update any packages that are incompatible or flagged.

### 5. Review Removed Windows-Specific APIs
If `AdoCore` or any dependent project previously used Windows-specific APIs (e.g., `System.Web`, `Microsoft.Win32`, Registry access, WCF server-side components), verify that cross-platform alternatives have been applied. Running the .NET Upgrade Assistant compatibility analyzer can assist here:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

### 6. Check Runtime Behavior
Execute the application manually or through its entry point and exercise the primary workflows. Pay attention to:

- File path separators (`/` vs `\`)
- Environment variable access
- Configuration file loading (e.g., `appsettings.json` vs `app.config`)
- Any platform-specific behavior that may differ on Linux or macOS if cross-platform execution is intended

### 7. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or another supported configuration provider, and that `ConfigurationManager` calls have been updated accordingly.

### 8. Validate Assembly and Namespace References
Confirm that any reflection-based code, assembly loading, or namespace references that existed in the legacy project still resolve correctly under the new runtime.

## Deployment

Once all validation steps above pass without errors or unexpected behavior:

1. Publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

2. Verify the contents of the `./publish` directory contain all expected binaries and dependencies.
3. Deploy the contents of the publish output to the target environment and perform a smoke test against the live configuration.