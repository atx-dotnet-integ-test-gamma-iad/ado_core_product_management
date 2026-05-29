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
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to their current equivalents.

### 3. Build the Solution
Perform a full build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Review any warnings that surface, as some may indicate runtime issues that do not manifest as build errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that behavior has not changed during the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate breaking API changes between .NET Framework and cross-platform .NET (e.g., `System.Web`, `AppDomain`, reflection behavior, or threading differences).

### 5. Audit Removed or Replaced APIs
Check the code for any usage of APIs that are present in cross-platform .NET but behave differently from their .NET Framework counterparts. Common areas to review include:

- `System.Web` references (not available on cross-platform .NET)
- `BinaryFormatter` (disabled by default in .NET 5+)
- `Thread.Abort` (throws `PlatformNotSupportedException` on cross-platform .NET)
- Registry access (`Microsoft.Win32.Registry`) — only functional on Windows
- WCF server-side components

### 6. Run the Application
Execute the application directly to confirm runtime behavior:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any that involve database access, file I/O, or platform-specific operations, as these are common sources of runtime issues that do not appear at build time.

### 7. Check Platform-Specific Behavior
If the application uses any Windows-specific functionality (e.g., COM interop, MSMQ, Windows Event Log), verify that the target deployment environment is Windows or that appropriate guards are in place using `RuntimeInformation.IsOSPlatform(OSPlatform.Windows)`.

### 8. Review NuGet Package Compatibility
Run the following command to check for any packages that may not fully support the target framework:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide better .NET compatibility.