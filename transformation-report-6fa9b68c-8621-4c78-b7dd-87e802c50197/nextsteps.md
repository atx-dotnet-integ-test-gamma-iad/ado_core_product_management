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
Use the .NET Upgrade Assistant compatibility analyzer or review the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) to identify any APIs that were available in .NET Framework but have changed behavior or been removed in modern .NET. Pay particular attention to:

- `System.Web` usages (not available in .NET Core/.NET 5+)
- `AppDomain` usage
- Reflection APIs that have changed behavior
- Binary serialization (`BinaryFormatter` is obsolete and disabled by default)

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and review all `<PackageReference>` entries. Confirm each package has a version that supports the target framework. You can verify this on [nuget.org](https://www.nuget.org) or by running:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

### 6. Validate Platform-Specific Code
Search the codebase for any platform-specific assumptions such as:

- Windows registry access (`Microsoft.Win32.Registry`)
- Windows-only file path separators (use `Path.Combine` and `Path.DirectorySeparatorChar`)
- P/Invoke calls to Windows DLLs
- `Environment.SpecialFolder` paths that may differ across operating systems

### 7. Run on Target Platforms
If cross-platform support is a requirement, test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

### 8. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` folder to confirm all expected files are present before deploying to the target environment.