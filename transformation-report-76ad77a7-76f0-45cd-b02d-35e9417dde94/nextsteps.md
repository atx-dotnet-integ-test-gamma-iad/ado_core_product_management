# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48`, `netcoreapp3.1`, or other unintended frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that may indicate subtle compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully, particularly for any tests that exercise platform-specific behavior such as file paths, registry access, or Windows-only APIs.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the built-in platform compatibility analyzer to identify any remaining calls to Windows-only APIs. These will appear as analyzer warnings (e.g., `CA1416`). If the application is intended to run only on Windows, you can suppress these with the appropriate `[SupportedOSPlatform("windows")]` attributes. If true cross-platform support is required, those APIs will need to be replaced.

### 6. Verify Runtime Behavior
Run the application directly and exercise its primary workflows:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Confirm that database connections, file I/O, and any other runtime dependencies function as expected on the target operating system.

### 7. Review NuGet Package Compatibility
Check that all third-party NuGet packages in use have versions compatible with your target .NET version. Visit [nuget.org](https://www.nuget.org) or use the following command to inspect outdated packages:

```bash
dotnet list package --outdated
```

Update packages where newer, compatible versions are available.

### 8. Publish the Application
Once validation is complete, produce a release build artifact:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that output location before distributing it.