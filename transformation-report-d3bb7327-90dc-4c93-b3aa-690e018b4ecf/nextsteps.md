# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this is consistent across all projects in the solution.

### 2. Restore Dependencies
Run a full NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any warnings about package compatibility or deprecated packages.

### 3. Build the Solution
Perform a clean build to confirm there are no issues that may have been masked:

```bash
dotnet clean
dotnet build
```

Review all warnings in the build output, as some may indicate runtime issues even if the build succeeds.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new .NET runtime.

### 5. Check for Removed or Unsupported APIs
Even with a clean build, some APIs that existed in .NET Framework may have been removed or changed in cross-platform .NET. Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to scan for potential runtime issues:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to:
- `System.Web` usage (not available in cross-platform .NET)
- Windows-specific APIs (e.g., registry access, WCF server-side, Windows Forms if targeting non-Windows)
- Reflection-based code that may behave differently

### 6. Test on Target Platforms
If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues.

### 7. Review `AdoCore.csproj` Specifically
Since `AdoCore.csproj` is listed as the most independent project in the solution, validate it first in isolation:

```bash
dotnet build AdoCore/AdoCore.csproj
dotnet test AdoCore/AdoCore.csproj  # if applicable
```

Confirm that any ADO.NET-related functionality (connections, commands, data adapters) works correctly against the intended database provider, as some legacy ADO providers may require updated NuGet packages for cross-platform .NET.

## Publishing

Once validation is complete, publish the application using:

```bash
dotnet publish -c Release -o ./publish
```

Review the contents of the `./publish` directory to confirm all required assemblies and configuration files are present before deploying to the target environment.