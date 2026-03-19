# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Ensure this aligns with the runtime version available in your target environment.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

## 4. Check for Runtime-Only Issues

Some issues do not surface at compile time. Run the application and exercise its primary code paths:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Pay particular attention to:
- Database connectivity and ADO.NET provider compatibility (given the `AdoCore` naming suggests ADO.NET usage)
- Any calls to APIs that existed in .NET Framework but behave differently in cross-platform .NET (e.g., `System.Data`, `System.Configuration`)
- File path handling, as path separators differ between Windows and Linux/macOS

## 5. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. For any packages that were carried over from the legacy project, verify they have .NET-compatible versions available:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Replace or update any packages that are outdated or deprecated.

## 6. Validate Configuration Handling

If the original project used `System.Configuration` (i.e., `app.config` or `web.config`), confirm that configuration has been migrated to the appropriate .NET mechanism, such as `appsettings.json` with `Microsoft.Extensions.Configuration`. The `System.Configuration.ConfigurationManager` NuGet package is available as a compatibility shim if a full migration is not immediately feasible.

## 7. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues, particularly around:
- File I/O
- Registry access (not available on Linux/macOS)
- Windows-specific interop or P/Invoke calls

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deploying to the target environment.