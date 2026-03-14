# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Review Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

### 2. Restore and Build from the Command Line
Run the following commands from the solution root to confirm a clean restore and build outside of any IDE:

```bash
dotnet restore
dotnet build
```

Confirm that both commands complete with no errors or warnings that could indicate unresolved compatibility issues.

### 3. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test
```

Review any failing tests carefully, as they may indicate behavioral differences introduced by the migration rather than compilation issues.

### 4. Check for Removed or Changed APIs
Even without build errors, some APIs behave differently on cross-platform .NET compared to .NET Framework. Pay particular attention to:

- **`System.Drawing`** — requires the `System.Drawing.Common` NuGet package and has platform restrictions on non-Windows systems.
- **`System.Web`** — is not available on cross-platform .NET. Any indirect dependencies on it should be reviewed.
- **Windows Registry, WCF, or Remoting** — these either require additional packages or are not supported.
- **`AppDomain`** — some members are no longer functional and will throw `PlatformNotSupportedException` at runtime.

### 5. Audit NuGet Package Compatibility
Open the NuGet package manager or inspect each `.csproj` file and verify that all referenced packages have versions that support the target framework. Packages targeting only `net4x` may still resolve but can cause runtime failures.

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform .NET support.

### 6. Verify Platform-Specific Code Paths
Search the codebase for any use of `#if` preprocessor directives or runtime platform checks (e.g., `RuntimeInformation.IsOSPlatform`) to ensure platform-specific logic is correct and intentional.

### 7. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (e.g., Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

```bash
dotnet run
```

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish -c Release -r <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example:
- `win-x64`
- `linux-x64`
- `osx-x64`

Review the output in the `publish` folder to confirm all required assemblies and assets are present.