# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other unintended frameworks.

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

Review any failing tests and address the root causes before proceeding.

### 4. Check for Removed or Changed APIs
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tooling to identify any APIs used in the code that have been removed or altered in the target .NET version:

```bash
dotnet tool install -g dotnet-apicompat
```

Pay particular attention to APIs in the `System.Web`, `System.Runtime.Remoting`, and `System.Security.Permissions` namespaces, which are commonly unavailable in cross-platform .NET.

### 5. Review NuGet Package Compatibility
Open the `.csproj` files and inspect each `<PackageReference>`. For any package that does not explicitly support the target framework, check NuGet.org for a compatible version and update accordingly:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Replace or remove any packages that are Windows-only if cross-platform support is required.

### 6. Validate Platform-Specific Code
Search the solution for any platform-specific code paths, such as Windows registry access, COM interop, or P/Invoke calls. These will compile but may fail at runtime on non-Windows platforms. Annotate or guard them appropriately using runtime checks:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific logic
}
```

### 7. Test on Target Platforms
If the goal is cross-platform support, run the application on each intended operating system (Linux, macOS, Windows) to surface any platform-specific runtime failures that would not appear during a Windows-only build.

### 8. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the output directory to confirm all expected assemblies and configuration files are present before deploying.