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

Address any failing tests before proceeding.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tool to identify any APIs that were available in .NET Framework but have been removed or changed in the target .NET version:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to:
- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- Reflection behaviors that differ between runtimes

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and review each `<PackageReference>`. For any package that does not have a `net6.0`, `net7.0`, or `net8.0` target framework folder in its NuGet package, check NuGet.org for an updated version or a supported alternative.

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

### 6. Validate Runtime Behavior
Run the application locally and exercise the primary workflows. Check application logs for:
- `PlatformNotSupportedException`
- `NotImplementedException` from compatibility shims
- Unexpected `NullReferenceException` that may stem from changed default behaviors (e.g., `JsonSerializer` casing, `HttpClient` defaults)

### 7. Review Configuration Files
Confirm that `app.config` or `web.config` settings have been migrated to `appsettings.json` or environment variables where applicable. Legacy configuration sections are not supported in cross-platform .NET without additional packages.

### 8. Publish a Release Build
Once the above steps pass, produce a self-contained or framework-dependent publish to confirm the output is complete:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` folder and run the output executable to confirm it starts correctly.