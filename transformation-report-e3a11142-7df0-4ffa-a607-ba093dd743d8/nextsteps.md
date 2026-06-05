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
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 4. Check NuGet Package Compatibility
Review all NuGet dependencies in each `.csproj` file. Confirm that every package has a version compatible with the target .NET version. You can use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Replace any packages that target only .NET Framework with their .NET-compatible equivalents where applicable.

### 5. Review Removed or Changed APIs
Some .NET Framework APIs are not available or behave differently in cross-platform .NET. Run the .NET Upgrade Assistant compatibility analyzer or the Platform Compatibility Analyzer to surface any such usages:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

Pay particular attention to areas such as:
- `System.Web` usages (not available in .NET Core/.NET 5+)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- `AppDomain`, `BinaryFormatter`, or `Remoting` APIs

### 6. Verify Configuration Files
Check that any `app.config` or `web.config` files have been migrated appropriately to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`. Legacy config sections may be silently ignored at runtime.

### 7. Test on Target Platform
If cross-platform support (Linux/macOS) is a goal, run the application and its tests on those operating systems to catch any platform-specific runtime issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

### 8. Publish a Release Build
Once validation passes, produce a published output to confirm the deployment artifact is correct:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to ensure all required assets, configuration files, and dependencies are present.

### 9. Smoke Test the Published Output
Run the published output directly to verify it functions correctly outside of the development environment:

```bash
./publish/AdoCore
```

Or on Windows:

```powershell
.\publish\AdoCore.exe
```

Confirm that the application starts, connects to any required data sources, and performs its core operations without error.