# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Run the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework, paying particular attention to packages that previously targeted `.NET Framework`.

## 4. Check for Removed or Changed APIs

Review any usages of APIs that are known to have been removed or altered in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available in cross-platform .NET)
- `AppDomain` usage
- Windows Registry access (`Microsoft.Win32.Registry`)
- `BinaryFormatter` (deprecated and disabled by default)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tooling if a deeper API surface check is needed.

## 5. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether failures are due to migration-related changes or pre-existing issues.

## 6. Validate Runtime Behavior

Run the application and exercise its primary workflows manually or via integration tests. Pay attention to:

- File path handling (ensure paths use `Path.Combine` and are not hardcoded with backslashes)
- Configuration loading (e.g., `app.config` vs `appsettings.json`)
- Any platform-specific behavior that may differ on Linux or macOS if cross-platform execution is intended

## 7. Check for Platform-Specific Code

Search the codebase for any `[DllImport]` calls or P/Invoke usage that targets Windows-only native libraries. If cross-platform execution is required, these will need platform guards or cross-platform alternatives.

```csharp
if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
{
    // Windows-specific logic
}
```

## 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

If a self-contained deployment is needed:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your target environment.

## 9. Verify Published Output

Navigate to the `./publish` directory and confirm the expected binaries and configuration files are present. Run the published executable directly to confirm it starts and operates correctly outside of the development environment.