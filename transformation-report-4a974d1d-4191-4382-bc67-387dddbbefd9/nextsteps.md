# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other legacy/EOL targets unless intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages, missing packages, or version conflicts.

### 3. Build the Solution
Perform a clean build to confirm there are no issues that may have been masked:

```bash
dotnet build --configuration Release
```

Review all warnings in the output, as some warnings may indicate runtime issues even when the build succeeds.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the transformation:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding further.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the compatibility analyzer to identify any remaining Windows-specific or platform-specific API calls that may compile successfully but fail at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Alternatively, enable the platform compatibility analyzer by ensuring the following is present in your `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild and review any new `CA1416` warnings, which indicate platform-specific API usage.

### 6. Verify Runtime Behavior
Run the application directly to confirm it behaves as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any that involve file I/O, database access, networking, or interop, as these areas are most likely to surface cross-platform issues at runtime.

### 7. Review NuGet Package Compatibility
Check that all referenced NuGet packages support the target framework. Visit [nuget.org](https://www.nuget.org) for each dependency and confirm `.NET` or `.NET Standard` compatibility. Replace any packages that only support `.NET Framework` with their cross-platform equivalents.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier (`linux-x64`, `win-x64`, `osx-x64`, etc.) to match your deployment target. Review the publish output directory to confirm all required files are present.